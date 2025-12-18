import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class EspApi {
  // Last working base URL (STA mode) to avoid rediscovery on every request
  static Uri? _cachedBase;

  // Discovery candidates (order matters after cache):
  // - AP mode fixed IP first (instant in setup)
  // - mDNS names for STA mode
  // - Common local network IP range for manual fallback
  static final List<Uri> _candidates = <Uri>[
    Uri.parse('http://192.168.10.2'),
    Uri.parse('http://wordclock.local'),
    Uri.parse('http://www.wordclock.local'),
  ];

  /// Find the ESP base URL.
  ///
  /// Tries the cached successful base first with a short timeout, then falls
  /// back to trying all candidates in parallel with increasing timeouts for
  /// better discovery of mDNS names in STA mode. Returns as soon as the first
  /// candidate responds successfully instead of waiting for all to finish.
  static Future<Uri?> findBase({
    Duration cacheTimeout = const Duration(milliseconds: 800),
    Duration discoveryTimeout = const Duration(seconds: 5),
  }) async {
    // 1) Try cached base quickly
    if (_cachedBase != null) {
      final cached = _cachedBase!;
      try {
        debugPrint('[ESP API] Trying cached: $cached');
        final res = await http
            .get(cached.replace(path: '/api/ping'))
            .timeout(cacheTimeout);
        debugPrint(
          '[ESP API] Response from cached ${cached.host}: ${res.statusCode}',
        );
        if (res.statusCode == 200) {
          debugPrint('[ESP API] ✓ Cached base still valid');
          return cached;
        }
      } catch (e) {
        debugPrint('[ESP API] ✗ Cached base failed: $e');
        _cachedBase = null; // Clear invalid cache
      }
    }

    // 2) Try candidates in multiple rounds with increasing timeouts and
    //    complete early on the first success.
    Uri? found;
    Future<Uri?> roundProbe(
      Duration perRequestTimeout,
      Duration roundBudget,
    ) async {
      debugPrint(
        '[ESP API] Parallel discovery (per-request: ${perRequestTimeout.inSeconds}s, round budget: ${roundBudget.inSeconds}s)',
      );
      final completer = Completer<Uri?>();

      for (final base in _candidates) {
        () async {
          try {
            debugPrint('[ESP API] Trying: $base');
            final uri = base.replace(path: '/api/ping');
            final res = await http.get(uri).timeout(perRequestTimeout);
            debugPrint('[ESP API] Response from $base: ${res.statusCode}');
            if (res.statusCode == 200) {
              if (!completer.isCompleted) {
                debugPrint('[ESP API] ✓ Connected to: $base');
                completer.complete(base);
              }
            }
          } catch (e) {
            debugPrint('[ESP API] ✗ Failed to reach $base: $e');
          }
        }();
      }

      // Wait for first success or the round budget timeout
      return Future.any(<Future<Uri?>>[
        completer.future,
        Future<Uri?>.delayed(roundBudget, () => null),
      ]).catchError((_) => null);
    }

    // Round 1: discoveryTimeout (default 5s); Round 2: x2; Round 3: x3
    final d1 = discoveryTimeout;
    final d2 = Duration(milliseconds: discoveryTimeout.inMilliseconds * 2);
    final d3 = Duration(milliseconds: discoveryTimeout.inMilliseconds * 3);
    final roundBudgets = <Duration>[
      d1 + const Duration(seconds: 1),
      d2 + const Duration(seconds: 1),
      d3 + const Duration(seconds: 1),
    ];
    final perRequest = <Duration>[d1, d2, d3];

    for (var i = 0; i < roundBudgets.length; i++) {
      found = await roundProbe(perRequest[i], roundBudgets[i]);
      if (found != null) {
        _cachedBase = found; // Cache for next time
        return found;
      }
    }

    debugPrint('[ESP API] ✗ No ESP found after all discovery rounds');
    return null;
  }

  static Future<Map<String, dynamic>> fetchParameters(
    Uri base, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = base.replace(path: '/api/parameters');
    final res = await http.get(uri).timeout(timeout);
    if (res.statusCode != 200) {
      throw Exception('GET /api/parameters failed: ${res.statusCode}');
    }
    final json = jsonDecode(utf8.decode(res.bodyBytes));
    if (json is! Map<String, dynamic>) {
      throw Exception('Invalid JSON response');
    }
    // On successful communication assume this base is valid and cache it.
    _cachedBase = base;
    return json;
  }

  static Future<bool> sendParameters(
    Uri base,
    Map<String, String> fields, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = base.replace(path: '/api/parameters');
    final res = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
          },
          body: fields,
        )
        .timeout(timeout);
    if (res.statusCode == 200 || res.statusCode == 204) {
      _cachedBase = base; // keep fresh on success
    }
    return res.statusCode == 200 || res.statusCode == 204;
  }

  /// Repeatedly tries to discover the ESP base URL until found or a total
  /// timeout elapses. Useful after switching the ESP from AP → STA mode when
  /// the device may briefly lose Wi‑Fi and mDNS takes time to come up.
  ///
  /// The loop uses a gentle backoff schedule between attempts. It returns as
  /// soon as a candidate is found, or `null` if the overall timeout is reached.
  static Future<Uri?> waitForBase({
    Duration overallTimeout = const Duration(seconds: 60),
    List<Duration>? backoffSchedule,
  }) async {
    final schedule =
        backoffSchedule ??
        const <Duration>[
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
          Duration(seconds: 5),
          Duration(seconds: 8),
          Duration(seconds: 13),
          Duration(seconds: 21),
        ];

    final sw = Stopwatch()..start();
    var i = 0;
    while (sw.elapsed < overallTimeout) {
      // Use a moderately short per-try discovery timeout to avoid nesting
      // very long waits (findBase itself does multi-round probing).
      final uri = await findBase(discoveryTimeout: const Duration(seconds: 4));
      if (uri != null) return uri;

      // Delay with backoff (but do not exceed the remaining overall time).
      final remaining = overallTimeout - sw.elapsed;
      if (remaining <= Duration.zero) break;
      final wait = schedule[i < schedule.length ? i : schedule.length - 1];
      await Future.delayed(wait <= remaining ? wait : remaining);
      if (i < schedule.length - 1) i++;
    }
    return null;
  }
}
