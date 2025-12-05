import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'cards/card_visualisation.dart' as visual;
import 'cards/card_connections.dart' as conn;
import 'cards/card_notification.dart' as notif;
import 'cards/card_timer.dart' as timer;
import 'cards/card_alarm.dart' as alarm;
import 'cards/card_automation.dart' as automation;
import 'cards/card_offline_mode.dart' as offline;

void main() {
  runApp(const MainApp());
}

// Startup / cross-widget connection state used while the splash runs.
int initialIsConnected = -1; // -1 = unknown, 0 = not connected, 1 = connected
bool _startupConnectionError = false;

// Simulated fetch from ESP. Per spec this sets an internal `int i = 0` and
// inverts that into the connection state. If `i == 1` we mark a startup
// connection error so the app shows the power-off UI and a blocking dialog.
Future<void> getParametersFromESP() async {
  // Simulated network/ESP call delay
  await Future.delayed(const Duration(milliseconds: 200));
  int i = 0; // change this to 1 to simulate another device holding the lock

  if (i == 0) {
    // invert and store
    initialIsConnected = 1 - i; // will be 1
    _startupConnectionError = false;
    debugPrint(
      'getParametersFromESP: success initialIsConnected=$initialIsConnected',
    );
  } else {
    // simulate busy/locked device -> force powerOff UI after splash
    initialIsConnected = 0;
    _startupConnectionError = true;
    debugPrint('getParametersFromESP: startup connection error (i=$i)');
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WORDCLOCK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      // Show a small splash screen on startup before the main scaffold.
      // Show a small splash screen on startup before the main scaffold.
      // If an initialization Future is provided it will wait for it, otherwise
      // it will show the splash for the given duration. Default duration: 4s.
      home: SplashScreen(
        next: const HomeScaffold(),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

/// Simple startup splash screen: black background with centered image.
class SplashScreen extends StatefulWidget {
  final Widget next;
  final Duration duration;

  // Optional initialization future. If provided the splash waits for this
  // future to complete. If null the splash waits for [duration].
  final Future<void>? initFuture;

  const SplashScreen({
    super.key,
    required this.next,
    this.duration = const Duration(seconds: 4),
    this.initFuture,
  });
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Precache the splash icon so it's available immediately, and
      // precache the large preview image. We will not transition away
      // from the splash until both the init/duration and the preview
      // image are ready. Use a timeout for the preview to avoid hanging
      // indefinitely if the asset is missing.
      final iconProvider = const AssetImage('assets/images/AppIcon2.png');
      final previewProvider = const AssetImage(
        'assets/images/wordclock_preview.png',
      );

      try {
        await precacheImage(iconProvider, context);
      } catch (_) {}

      Future<void> precachePreview() async {
        try {
          await precacheImage(previewProvider, context);
        } catch (_) {}
      }

      final Future<void> waitForInit =
          widget.initFuture ?? Future.delayed(widget.duration);

      // Start a quick fetch of parameters from the ESP while the splash is
      // visible so the app can reflect connection state immediately after
      // the splash completes.
      try {
        await getParametersFromESP();
      } catch (_) {}

      // Wait for both the init/duration and the preview (with a timeout).
      await Future.wait<void>([
        waitForInit,
        precachePreview().timeout(
          const Duration(seconds: 10),
          onTimeout: () {},
        ),
      ]);

      if (!mounted) return;
      setState(() => _done = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.next;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 12, 12, 12),
      body: Center(
        child: Builder(
          builder: (ctx) {
            final dpr = MediaQuery.of(ctx).devicePixelRatio;
            final int cache = (256 * dpr).round();
            return Image.asset(
              'assets/images/AppIcon2.png',
              width: 256,
              height: 256,
              cacheWidth: cache,
              cacheHeight: cache,
              fit: BoxFit.contain,
            );
          },
        ),
      ),
    );
  }
}

class HomeScaffold extends StatefulWidget {
  const HomeScaffold({super.key});

  @override
  State<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<HomeScaffold>
    with WidgetsBindingObserver {
  // MethodChannel für NotificationListenerService
  static const MethodChannel _notifChannel = MethodChannel(
    'notification_permission_channel',
  );
  // Track whether the preview image has been painted at least once. While
  // false we keep the scaffold background dark to avoid a brief white flash
  // when transitioning from the splash screen.
  bool _previewPainted = false;
  // When the user is automatically logged out due to inactivity we want the
  // UI to look like the clock is powered off without actually mutating the
  // canonical `powerOn` parameter. This overlay flag controls that visual
  // state and is cleared as soon as the user interacts again or reconnects.
  bool _inactivityUiOverlay = false;
  // Globale Parameter
  int powerOn = 1; //Parameter zum Ein/Ausschalten der UhrUhr ein/aus
  bool newChanges =
      false; //Änderungen vorhanden (interner Paramter -> nicht im ESP-Code)
  int isConnected =
      0; //0 = nicht verbunden, 1 = verbunden (bereits in ESP-Code implementiert)

  // Verbindungs-Parameter
  int loginsaved =
      0; //0 = erstes Mal verbinden/einstellen, 1 = verbunden (bereits in ESP-Code implementiert)
  String ssid =
      ""; //SSID des aktuell verbundenen WLANs (bereits in ESP-Code implementiert)
  String password =
      ""; //Passwort des aktuell verbundenen WLANs (bereits in ESP-Code implementiert)

  // Controllers for the connections card so main can read entered values
  late final TextEditingController _ssidController;
  late final TextEditingController _passwordController;

  // Visualisierungs-Parameter
  double brightness =
      70; //Helligkeit (-> wird direkt in RGB-Werte umgesetzt -> im ESP-Code um Farbe zurückrechnen zu können)
  int selectedColorRed =
      36; //Rotanteil der ausgewählten Farbe (bereits in ESP-Code implementiert)
  int selectedColorGreen =
      36; //Grünanteil der ausgewählten Farbe (bereits in ESP-Code implementiert)
  int selectedColorBlue =
      36; //Blauanteil der ausgewählten Farbe (bereits in ESP-Code implementiert)
  ValueNotifier<Color>? colorNotifier; //Notifier für Farbänderungen
  ValueNotifier<double>?
  brightnessNotifier; //Notifier für Helligkeitsänderungen

  // Automatisierungs-Parameter
  int enableNightMode =
      0; //Automatisches Ein/Ausschalten aktivieren/deaktivieren (bereits in ESP-Code implementiert)
  int displayOffStunden =
      0; //Stundenzahl der Zeit zum Ausschalten der Uhr (=TimeDisplayOff, bereits in ESP-Code implementiert)
  int displayOffMinuten = 0; //Minutenzahl der Zeit zum Ausschalten der Uhr
  int displayOnStunden =
      0; //Stundenzahl der Zeit zum Einschalten der Uhr (=TimeDisplayOn, bereits in ESP-Code implementiert)
  int displayOnMinuten = 0; //Minutenzahl der Zeit zum Einschalten der Uhr

  // Wecker-Parameter
  int alarmEnable = 0; //Wecker aktiveren/deaktivieren (in ESP-Code: if-Abfrage)
  int alarmTimeStunden =
      0; //Stundenzahl der Uhrzeit zum Auslösen des Weckers (in ESP-Code: if-Abfrage mit mezaktstunde und mezaktminute)
  int alarmTimeMinuten = 0; //Minutenzahl der Uhrzeit zum Auslösen des Weckers

  // Timer-Parameter
  int timerEnable = 0; //Timer aktivieren/deaktivieren
  int timerDurationStunden = 0;
  int timerDurationMinuten = 0;
  int timerDurationSekunden = 0;
  int timerAusloesungStunden = 0;
  int timerAusloesungMinuten = 0;
  int timerAusloesungSekunden = 0;
  // Internal flag: expect the initial duration update right after a Start
  bool _expectingInitialTimerDuration = false;

  // Offline-Modus Parameter
  int offlineMode =
      0; //Offline Modus aktivieren/deaktiveren (in ESP-Code: if-Abfrage)
  int utcaktsekunde =
      0; //aktuelle Sekunde UTC (in ESP-Code wahrscheinlich einfach überschreiben)
  int utcaktminute =
      0; //aktuelle Minute UTC (in ESP-Code wahrscheinlich einfach überschreiben)
  int utcaktstunde =
      0; //aktuelle Stunde UTC (in ESP-Code wahrscheinlich einfach überschreiben)

  // Benachrichtigungs-Parameter
  int notificationEnable =
      0; //Benachrichtigungsanzeige aktivieren/deaktiveren (in ESP-Code: if(NotificationEnable&&NewNotification) dann LED an)
  int newNotification = 0; //Neue Benachrichtigung

  // --- Baseline (confirmed) values ---
  // When the user presses "Übernehmen" we snapshot the current settings
  // here and use these values as the comparison baseline for `newChanges`.
  late String _baseSsid;
  late String _basePassword;
  late double _baseBrightness;
  late int _baseSelectedColorRed;
  late int _baseSelectedColorGreen;
  late int _baseSelectedColorBlue;
  late int _baseEnableNightMode;
  late int _baseDisplayOffStunden;
  late int _baseDisplayOffMinuten;
  late int _baseDisplayOnStunden;
  late int _baseDisplayOnMinuten;
  late int _baseAlarmEnable;
  late int _baseAlarmTimeStunden;
  late int _baseAlarmTimeMinuten;
  late int _baseOfflineMode;
  late int _baseUtcaktsekunde;
  late int _baseUtcaktminute;
  late int _baseUtcaktstunde;
  late int _baseNotificationEnable;

  // Handler für NotificationListenerService-Status
  Future<void> _handleNotificationStatusChanged(MethodCall call) async {
    if (call.method == 'onNotificationStatusChanged') {
      final bool hasNotification = call.arguments == true;
      if (notificationEnable == 1) {
        if (hasNotification && newNotification != 1) {
          setState(() {
            newNotification = 1;
          });
          sendParametersToESP();
        } else if (!hasNotification && newNotification != 0) {
          setState(() {
            newNotification = 0;
          });
          sendParametersToESP();
        }
      } else {
        // Wenn Notification-Feature deaktiviert, immer auf 0
        if (newNotification != 0) {
          setState(() {
            newNotification = 0;
          });
          sendParametersToESP();
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Android NotificationListenerService-Status abonnieren
    _notifChannel.setMethodCallHandler(_handleNotificationStatusChanged);

    // Observe app lifecycle so we can cancel the timer if the app/web page
    // is backgrounded or closed.
    WidgetsBinding.instance.addObserver(this);
    _printVisualVars('init');
    // Initialize notifiers from the canonical state so the visual card can
    // update them directly without causing a full scaffold rebuild on every
    // user interaction (slider drag / swatch tap). The listeners update the
    // canonical ints stored here but intentionally do not call setState.

    // When building the initial Color for the visual card we need to
    // compensate the stored channel values by the requested factor
    // 5*(100/brightness) as requested. Guard against brightness==0
    // to avoid division by zero and clamp results to valid bytes.
    final double safeBrightness = (brightness == 0) ? 1.0 : brightness;
    final double factor = 5 * (100 / safeBrightness);
    final int initR = (selectedColorRed * factor).clamp(0, 255).round();
    final int initG = (selectedColorGreen * factor).clamp(0, 255).round();
    final int initB = (selectedColorBlue * factor).clamp(0, 255).round();
    colorNotifier = ValueNotifier<Color>(
      Color.fromARGB(255, initR, initG, initB),
    );
    colorNotifier!.addListener(_colorNotifierListener);
    // initialize brightness notifier and register listener so the visual
    // card can update the canonical brightness value without full rebuilds
    brightnessNotifier = ValueNotifier<double>(brightness);
    brightnessNotifier!.addListener(_brightnessNotifierListener);
    // Precache preview image to avoid decoding jank during first display on mobile.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(
        const AssetImage('assets/images/wordclock_preview.png'),
        context,
      );
    });

    // Initialize text controllers for the connections card (seed with current values)
    _ssidController = TextEditingController(text: ssid);
    _passwordController = TextEditingController(text: password);

    // Initialize baseline snapshot from the current values so the first
    // comparison uses these initial settings as the "confirmed" ones.
    _baseSsid = ssid;
    _basePassword = password;
    _baseBrightness = brightness;
    _baseSelectedColorRed = selectedColorRed;
    _baseSelectedColorGreen = selectedColorGreen;
    _baseSelectedColorBlue = selectedColorBlue;
    _baseEnableNightMode = enableNightMode;
    _baseDisplayOffStunden = displayOffStunden;
    _baseDisplayOffMinuten = displayOffMinuten;
    _baseDisplayOnStunden = displayOnStunden;
    _baseDisplayOnMinuten = displayOnMinuten;
    _baseAlarmEnable = alarmEnable;
    _baseAlarmTimeStunden = alarmTimeStunden;
    _baseAlarmTimeMinuten = alarmTimeMinuten;
    _baseOfflineMode = offlineMode;
    _baseUtcaktsekunde = utcaktsekunde;
    _baseUtcaktminute = utcaktminute;
    _baseUtcaktstunde = utcaktstunde;
    _baseNotificationEnable = notificationEnable;

    // Apply any startup connection state collected during the splash.
    if (initialIsConnected >= 0) {
      isConnected = initialIsConnected;
      debugPrint('Applying initialIsConnected=$isConnected');
      if (_startupConnectionError) {
        // Per spec: if startup indicates i==1 (busy device) the app should
        // show the UI as if `powerOn == 0` and display a blocking dialog.
        powerOn = 0;
        // Show blocking dialog after first frame of the scaffold build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showBlockingDialog(
            title: 'Verbindungsfehler',
            message:
                'Ein anderes Gerät besitzt aktuell den Zugriff auf die Wordclock.',
            buttonText: 'Nochmals Versuchen',
            buttonTextColor: Colors.white, // <-- korrekt
            buttonBackgroundColor: Colors.blueGrey,
            onButton: () async {
              try {
                await getParametersFromESP();
              } catch (_) {}
              // re-apply
              setState(() {
                isConnected =
                    initialIsConnected >= 0 ? initialIsConnected : isConnected;
                if (!_startupConnectionError) powerOn = 1;
              });
              if (!_startupConnectionError)
                Navigator.of(context, rootNavigator: true).pop();
            },
          );
        });
      }
    }

    // Start inactivity timer management
    _resetInactivityTimer();
  }

  Timer? _inactivityTimer;

  void _resetInactivityTimer([PointerEvent? _]) {
    // any user interaction should clear the inactivity overlay immediately
    if (_inactivityUiOverlay) {
      setState(() {
        _inactivityUiOverlay = false;
      });
    }
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 3), () {
      // On inactivity -> mark disconnected, send parameters and show dialog
      setState(() {
        isConnected = 0;
        _inactivityUiOverlay = true;
      });
      try {
        sendParametersToESP();
      } catch (_) {}
      _showBlockingDialog(
        title: 'Inaktivität',
        message:
            'Sie waren länger als 3 Minuten inaktiv, daher wurde Ihre Verbindung zur WordClock getrennt.',
        buttonText: 'Erneut Verbinden',
        buttonBackgroundColor: Colors.blueGrey,
        buttonTextColor: Colors.white,
        onButton: () async {
          try {
            await getParametersFromESP();
          } catch (_) {}
          setState(() {
            isConnected =
                initialIsConnected >= 0 ? initialIsConnected : isConnected;
            if (!_startupConnectionError) {
              powerOn = 1;
              _inactivityUiOverlay = false;
            }
          });
          if (!_startupConnectionError)
            Navigator.of(context, rootNavigator: true).pop();
        },
      );
    });
  }

  void _showBlockingDialog({
    required String title,
    required String message,
    required String buttonText,
    Color? buttonTextColor,
    Color? buttonBackgroundColor,
    required VoidCallback onButton,
  }) {
    // Use rootNavigator to ensure dialog is on top
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              ElevatedButton(
                onPressed: onButton,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonBackgroundColor,
                  foregroundColor: buttonTextColor,
                ),
                child: Text(buttonText),
              ),
            ],
          ),
    );
  }

  void _colorNotifierListener() {
    final c =
        colorNotifier?.value ??
        Color.fromARGB(
          255,
          selectedColorRed,
          selectedColorGreen,
          selectedColorBlue,
        );

    // Use the brightness value coming from the visual card's notifier if
    // available — that ensures the slider's value is used when computing
    // the scaled RGB components.
    final currentBrightness = brightnessNotifier?.value ?? brightness;
    _applyBrightnessToCanonical(c, currentBrightness);
    _printVisualVars('color-notifier');
    // Keep `newChanges` up-to-date when the visual parameters change.
    // We avoid forcing a rebuild unless the `newChanges` flag actually
    // toggles to reduce unnecessary work.
    _updateNewChanges();
  }

  void _brightnessNotifierListener() {
    // keep canonical brightness in sync with the visual card's notifier.
    // Intentionally do not call setState here to avoid rebuilding the
    // whole scaffold on every slider movement; children reading the
    // notifier will update locally. We only update the stored value so
    // other logic (e.g. color scaling) can read the current brightness.
    brightness = brightnessNotifier?.value ?? brightness;
    // Recalculate the canonical RGBs using the new brightness and the
    // currently selected color so the device-facing values update
    // immediately when the slider changes.
    final c =
        colorNotifier?.value ??
        Color.fromARGB(
          255,
          selectedColorRed,
          selectedColorGreen,
          selectedColorBlue,
        );
    _applyBrightnessToCanonical(c, brightness);
    _printVisualVars('brightness-notifier');
    // Brightness changed -> update the newChanges flag as well.
    _updateNewChanges();
  }

  // Return true when any of the tracked fields differ from their default
  // values. This is used to decide whether the UI should show the
  // "unsaved changes" state (`newChanges`).
  bool _computeNewChanges() {
    // Compare current values against the last confirmed (baseline) values.
    if (ssid != _baseSsid) return true;
    if (password != _basePassword) return true;
    if ((brightness - _baseBrightness).abs() > 0.01) return true;
    if (selectedColorRed != _baseSelectedColorRed) return true;
    if (selectedColorGreen != _baseSelectedColorGreen) return true;
    if (selectedColorBlue != _baseSelectedColorBlue) return true;
    if (enableNightMode != _baseEnableNightMode) return true;
    // Only treat the automation on/off times as a change when the
    // night mode/automation is enabled. If automation is disabled we
    // ignore the time fields so they don't trigger the 'Übernehmen'
    // indicator by themselves.
    if (enableNightMode == 1) {
      if (displayOffStunden != _baseDisplayOffStunden) return true;
      if (displayOffMinuten != _baseDisplayOffMinuten) return true;
      if (displayOnStunden != _baseDisplayOnStunden) return true;
      if (displayOnMinuten != _baseDisplayOnMinuten) return true;
    }
    if (alarmEnable != _baseAlarmEnable) return true;
    if (offlineMode != _baseOfflineMode) return true;
    if (notificationEnable != _baseNotificationEnable) return true;
    return false;
  }

  // Update `newChanges` and call setState only when the boolean actually
  // changes to avoid redundant rebuilds.
  void _updateNewChanges() {
    final bool changed = _computeNewChanges();
    if (newChanges != changed) {
      setState(() {
        newChanges = changed;
      });
    }
  }

  void _applyBrightnessToCanonical(Color c, double b) {
    // Keep the existing scaling behaviour but read brightness from the
    // provided value. Clamp to valid byte range before rounding.
    selectedColorRed = (c.red * (b / 500)).clamp(0, 255).round();
    selectedColorGreen = (c.green * (b / 500)).clamp(0, 255).round();
    selectedColorBlue = (c.blue * (b / 500)).clamp(0, 255).round();
  }

  // Centralized debug helper that prints all canonical parameters to the
  // console and shows them in a temporary overlay popup for 10 seconds.
  void sendParametersToESP() {
    final List<String> params = [
      'powerOn=$powerOn',
      'newChanges=$newChanges',
      'isConnected=$isConnected',
      'loginsaved=$loginsaved',
      'ssid=$ssid',
      'password=$password',
      'brightness=$brightness',
      'selectedColorRed=$selectedColorRed',
      'selectedColorGreen=$selectedColorGreen',
      'selectedColorBlue=$selectedColorBlue',
      'enableNightMode=$enableNightMode',
      'displayOnStunden=$displayOnStunden',
      'displayOnMinuten=$displayOnMinuten',
      'displayOffStunden=$displayOffStunden',
      'displayOffMinuten=$displayOffMinuten',
      'alarmEnable=$alarmEnable',
      'alarmTimeStunden=$alarmTimeStunden',
      'alarmTimeMinuten=$alarmTimeMinuten',
      'timerEnable=$timerEnable',
      'timerDurationStunden=$timerDurationStunden',
      'timerDurationMinuten=$timerDurationMinuten',
      'timerDurationSekunden=$timerDurationSekunden',
      'timerAusloesungStunden=$timerAusloesungStunden',
      'timerAusloesungMinuten=$timerAusloesungMinuten',
      'timerAusloesungSekunden=$timerAusloesungSekunden',
      'offlineMode=$offlineMode',
      'utcaktstunde=$utcaktstunde',
      'utcaktminute=$utcaktminute',
      'utcaktsekunde=$utcaktsekunde',
      'notificationEnable=$notificationEnable',
      'newNotification=$newNotification',
    ];
    debugPrint('--- sendParametersToESP ---');
    for (int i = 0; i < params.length; i += 2) {
      final left = params[i];
      final right = (i + 1 < params.length) ? params[i + 1] : '';
      debugPrint(left + (right.isNotEmpty ? '    ' + right : ''));
      print(left + (right.isNotEmpty ? '    ' + right : ''));
    }
    debugPrint('--- end sendParametersToESP ---');

    // Show SnackBar for 10 seconds
    if (mounted) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.clearSnackBars();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '--- sendParametersToESP ---',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
                ...List.generate((params.length + 1) ~/ 2, (i) {
                  final left = params[i * 2];
                  final right =
                      (i * 2 + 1 < params.length) ? params[i * 2 + 1] : '';
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          left,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (right.isNotEmpty)
                        Expanded(
                          child: Text(
                            right,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  );
                }),
                const Text(
                  '--- end sendParametersToESP ---',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ],
            ),
          ),
          duration: const Duration(seconds: 10),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    // stop observing lifecycle changes
    WidgetsBinding.instance.removeObserver(this);
    // remove our listeners and dispose the notifiers we created
    colorNotifier?.removeListener(_colorNotifierListener);
    colorNotifier?.dispose();
    brightnessNotifier?.removeListener(_brightnessNotifierListener);
    brightnessNotifier?.dispose();
    // dispose text controllers
    _ssidController.dispose();
    _passwordController.dispose();
    _inactivityTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app is backgrounded/closed we should cancel the timer and
    // clear the canonical timer fields so the device doesn't keep waiting
    // for a timer that the user can no longer control from the UI.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      debugPrint('App lifecycle: $state — clearing timer state');
      setState(() {
        timerEnable = 0;
        timerDurationStunden = 0;
        timerDurationMinuten = 0;
        timerDurationSekunden = 0;
        _expectingInitialTimerDuration = false;
      });
    }
  }

  void _printVisualVars([String when = '']) {
    debugPrint(
      'Visual params${when.isNotEmpty ? ' ($when)' : ''}: '
      'color=($selectedColorRed, $selectedColorGreen, $selectedColorBlue), '
      'brightness=${brightness.toStringAsFixed(1)}%',
    );
  }

  @override
  void setState(VoidCallback fn) {
    // weiterhin normales setState ausführen, danach die aktuellen Werte ausgeben
    super.setState(() {
      fn();
    });
    // Avoid spamming the debug console during layout/resize; only print in
    // debug mode and keep it lightweight.
    if (kDebugMode) {
      _printVisualVars('after setState');
    }
  }

  // Helper to safely build an individual card. If the card's build throws
  // an exception, return a visible error placeholder instead of letting the
  // exception take down the whole settings page.
  Widget _safeCard(Widget Function() builder, {String? label}) {
    try {
      return builder();
    } catch (e, st) {
      final tag = label ?? 'Card';
      debugPrint('Error building $tag: $e\n$st');
      return Card(
        color: Colors.red.shade50,
        child: ListTile(
          leading: const Icon(Icons.error, color: Colors.red),
          title: Text('Fehler in $tag'),
          subtitle: Text(e.toString()),
        ),
      );
    }
  }

  Widget build(BuildContext context) {
    // decide wide layout early for AppBar buttons
    final bool wideAtAppBar = MediaQuery.of(context).size.width >= 800;

    const double appBarButtonHeight = 36.0;
    Widget labeledButton(
      IconData icon,
      String label,
      VoidCallback onPressed, {
      bool active = false,
    }) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color:
              icon == Icons.check
                  ? Colors.black
                  : (active ? Colors.red : Colors.green),
          size: 20,
        ),
        label: Text(label, style: const TextStyle(color: Colors.black87)),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, appBarButtonHeight),
          side: BorderSide(color: Colors.grey.shade300, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          _previewPainted
              ? Colors.white
              : const Color.fromARGB(255, 12, 12, 12),
      appBar: AppBar(
        leadingWidth: wideAtAppBar ? 150 : 50,
        leading:
            wideAtAppBar
                ? (newChanges
                    ? Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Center(
                        child: SizedBox(
                          height: appBarButtonHeight,
                          child: labeledButton(Icons.check, 'Übernehmen', () {
                            // Read entered SSID/password from the connections card
                            final enteredSsid = _ssidController.text.trim();
                            final enteredPassword = _passwordController.text;
                            // Update canonical fields so they are reflected below
                            ssid = enteredSsid;
                            password = enteredPassword;
                            // Print all current settings to the debug console
                            debugPrint('Apply pressed -> current settings:');
                            debugPrint('ssid=$ssid');
                            debugPrint('password=$password');
                            debugPrint(
                              'brightness=${brightness.toStringAsFixed(2)}',
                            );
                            debugPrint('selectedColorRed=$selectedColorRed');
                            debugPrint(
                              'selectedColorGreen=$selectedColorGreen',
                            );
                            debugPrint('selectedColorBlue=$selectedColorBlue');
                            debugPrint('enableNightMode=$enableNightMode');
                            debugPrint('displayOffStunden=$displayOffStunden');
                            debugPrint('displayOffMinuten=$displayOffMinuten');
                            debugPrint('displayOnStunden=$displayOnStunden');
                            debugPrint('displayOnMinuten=$displayOnMinuten');
                            debugPrint('alarmEnable=$alarmEnable');
                            debugPrint('alarmTimeStunden=$alarmTimeStunden');
                            debugPrint('alarmTimeMinuten=$alarmTimeMinuten');
                            debugPrint('offlineMode=$offlineMode');
                            debugPrint('utcaktsekunde=$utcaktsekunde');
                            debugPrint('utcaktminute=$utcaktminute');
                            debugPrint('utcaktstunde=$utcaktstunde');
                            debugPrint(
                              'notificationEnable=$notificationEnable',
                            );
                            // Update baseline snapshot so these values become the
                            // confirmed defaults; hide the Apply button until they
                            // change again.
                            setState(() {
                              // Mark the entered SSID/password as confirmed
                              _baseSsid = ssid;
                              _basePassword = password;
                              loginsaved =
                                  1; // consider connection confirmed now
                              _baseBrightness = brightness;
                              _baseSelectedColorRed = selectedColorRed;
                              _baseSelectedColorGreen = selectedColorGreen;
                              _baseSelectedColorBlue = selectedColorBlue;
                              _baseEnableNightMode = enableNightMode;
                              _baseDisplayOffStunden = displayOffStunden;
                              _baseDisplayOffMinuten = displayOffMinuten;
                              _baseDisplayOnStunden = displayOnStunden;
                              _baseDisplayOnMinuten = displayOnMinuten;
                              _baseAlarmEnable = alarmEnable;
                              _baseAlarmTimeStunden = alarmTimeStunden;
                              _baseAlarmTimeMinuten = alarmTimeMinuten;
                              _baseOfflineMode = offlineMode;
                              _baseNotificationEnable = notificationEnable;
                              newChanges = false;
                            });
                            sendParametersToESP();
                            // keep prior behaviour (close if possible)
                            Navigator.maybePop(context);
                          }),
                        ),
                      ),
                    )
                    : const SizedBox.shrink())
                : (newChanges
                    ? IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.check,
                        size: 25.0,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        // Read entered SSID/password from the connections card
                        final enteredSsid = _ssidController.text.trim();
                        final enteredPassword = _passwordController.text;
                        ssid = enteredSsid;
                        password = enteredPassword;
                        debugPrint('Apply pressed -> current settings:');
                        debugPrint('ssid=$ssid');
                        debugPrint('password=$password');
                        debugPrint(
                          'brightness=${brightness.toStringAsFixed(2)}',
                        );
                        debugPrint('selectedColorRed=$selectedColorRed');
                        debugPrint('selectedColorGreen=$selectedColorGreen');
                        debugPrint('selectedColorBlue=$selectedColorBlue');
                        debugPrint('enableNightMode=$enableNightMode');
                        debugPrint('displayOffStunden=$displayOffStunden');
                        debugPrint('displayOffMinuten=$displayOffMinuten');
                        debugPrint('displayOnStunden=$displayOnStunden');
                        debugPrint('displayOnMinuten=$displayOnMinuten');
                        debugPrint('alarmEnable=$alarmEnable');
                        debugPrint('alarmTimeStunden=$alarmTimeStunden');
                        debugPrint('alarmTimeMinuten=$alarmTimeMinuten');
                        debugPrint('offlineMode=$offlineMode');
                        debugPrint('utcaktsekunde=$utcaktsekunde');
                        debugPrint('utcaktminute=$utcaktminute');
                        debugPrint('utcaktstunde=$utcaktstunde');
                        debugPrint('notificationEnable=$notificationEnable');
                        setState(() {
                          // Mark the entered SSID/password as confirmed
                          _baseSsid = ssid;
                          _basePassword = password;
                          loginsaved = 1; // consider connection confirmed now
                          _baseBrightness = brightness;
                          _baseSelectedColorRed = selectedColorRed;
                          _baseSelectedColorGreen = selectedColorGreen;
                          _baseSelectedColorBlue = selectedColorBlue;
                          _baseEnableNightMode = enableNightMode;
                          _baseDisplayOffStunden = displayOffStunden;
                          _baseDisplayOffMinuten = displayOffMinuten;
                          _baseDisplayOnStunden = displayOnStunden;
                          _baseDisplayOnMinuten = displayOnMinuten;
                          _baseAlarmEnable = alarmEnable;
                          _baseAlarmTimeStunden = alarmTimeStunden;
                          _baseAlarmTimeMinuten = alarmTimeMinuten;
                          _baseOfflineMode = offlineMode;
                          _baseNotificationEnable = notificationEnable;
                          newChanges = false;
                        });
                        sendParametersToESP();
                        Navigator.maybePop(context);
                      },
                    )
                    : null),
        title: const Text(
          'WORDCLOCK',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 20.0,
          ),
        ),
        centerTitle: true,
        backgroundColor:
            _previewPainted
                ? Colors.white
                : const Color.fromARGB(255, 12, 12, 12),
        elevation: 0,
        actions:
            wideAtAppBar
                ? [
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Center(
                      child: SizedBox(
                        height: appBarButtonHeight,
                        child: labeledButton(
                          Icons.power_settings_new,
                          (powerOn == 1) ? 'Ausschalten' : 'Einschalten',
                          () =>
                              setState(() => powerOn = (powerOn == 1) ? 0 : 1),
                          active: powerOn == 1,
                        ),
                      ),
                    ),
                  ),
                ]
                : [
                  SizedBox(
                    width: 50,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed:
                          () =>
                              setState(() => powerOn = (powerOn == 1) ? 0 : 1),
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder:
                            (child, anim) =>
                                FadeTransition(opacity: anim, child: child),
                        child: Icon(
                          Icons.power_settings_new,
                          key: ValueKey<int>(powerOn),
                          color: (powerOn == 1) ? Colors.red : Colors.green,
                          size: 25.0,
                        ),
                      ),
                    ),
                  ),
                ],
      ),
      body: SafeArea(
        child: Listener(
          onPointerDown: _resetInactivityTimer,
          behavior: HitTestBehavior.translucent,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // breakpoint für single / two column
              final bool wide = constraints.maxWidth >= 800;

              // --- dynamische min/max Größen abhängig von Device/Treiber --
              // Beispielwerte: für mobile eher kleiner, für PC größer
              final double imageMinSide = wide ? 200.0 : 120.0;
              final double imageMaxSide = wide ? 420.0 : 360.0;

              // horizontal gutter inside each column (left/right)
              const double columnHorizontalPadding = 12.0;
              // total width reserved for the divider area between columns. Make this
              // smaller so the visible line isn't far away from the content.
              const double verticalDividerWidth = 12.0;

              // Bild-Widget (verwendet die berechnete side)
              // Bild-Widget (verwendet die berechnete side)
              // Shows a colored rectangle behind the preview image. The
              // rectangle has exactly the same size (`side`) so it remains
              // aligned when `side` changes. The color uses the color selected
              // in the VisualisationCard when available (via `colorNotifier`),
              // otherwise falls back to the canonical RGB ints.
              Widget imageBox(double side) {
                // Helper that builds the Stack (bg rect + image) using the
                // provided background color. Defined inside so `side` is in
                // scope.
                Widget buildStack(Color bgColor) {
                  return RepaintBoundary(
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: side,
                          height: side,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // background rectangle exactly the same size
                              Container(
                                width: side,
                                height: side,
                                color: bgColor,
                              ),
                              // preview image on top — request decoded size to match
                              // the box to reduce decode overhead.
                              Builder(
                                builder: (ctx) {
                                  final dpr =
                                      MediaQuery.of(ctx).devicePixelRatio;
                                  final int cache = (side * dpr).round();
                                  return Image.asset(
                                    'assets/images/wordclock_preview.png',
                                    fit: BoxFit.contain,
                                    cacheWidth: cache,
                                    cacheHeight: cache,
                                    gaplessPlayback: true,
                                    frameBuilder: (
                                      context,
                                      child,
                                      frame,
                                      wasSynchronouslyLoaded,
                                    ) {
                                      // When the first non-null frame arrives mark the
                                      // preview as painted so the scaffold can switch
                                      // to its normal background color immediately.
                                      if (frame != null && !_previewPainted) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              if (!mounted) return;
                                              setState(() {
                                                _previewPainted = true;
                                              });
                                            });
                                      }
                                      return child;
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // When the clock is powered off (or we're showing the
                // inactivity overlay) we want the box behind the preview
                // image to be pure black regardless of the selected color.
                // Otherwise keep the existing behavior (use the
                // colorNotifier if present or the canonical RGB fallback).
                final bool uiOff = (powerOn == 0) || _inactivityUiOverlay;
                if (uiOff) {
                  // Bild normal (nicht transparent), nur Hintergrund schwarz
                  return RepaintBoundary(
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: side,
                          height: side,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: side,
                                height: side,
                                color: Colors.black,
                              ),
                              Builder(
                                builder: (ctx) {
                                  final dpr =
                                      MediaQuery.of(ctx).devicePixelRatio;
                                  final int cache = (side * dpr).round();
                                  return Image.asset(
                                    'assets/images/wordclock_preview.png',
                                    fit: BoxFit.contain,
                                    cacheWidth: cache,
                                    cacheHeight: cache,
                                    gaplessPlayback: true,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // If we have a color notifier use it so the background updates
                // immediately when the user selects a new swatch in the
                // VisualisationCard. Otherwise fall back to canonical RGB ints.
                if (colorNotifier != null) {
                  return ValueListenableBuilder<Color>(
                    valueListenable: colorNotifier!,
                    builder: (context, value, child) {
                      return buildStack(
                        Color.fromARGB(
                          255,
                          value.red.clamp(0, 255),
                          value.green.clamp(0, 255),
                          value.blue.clamp(0, 255),
                        ),
                      );
                    },
                  );
                }

                final fallback = Color.fromARGB(
                  255,
                  selectedColorRed.clamp(0, 255),
                  selectedColorGreen.clamp(0, 255),
                  selectedColorBlue.clamp(0, 255),
                );
                return buildStack(fallback);
              }

              // linke Spalte: optional cardWidth übergeben (bei wide layout)
              Widget leftColumn({double? cardWidth}) {
                final bool uiOff = (powerOn == 0) || _inactivityUiOverlay;
                final bool _cardsDisabled = uiOff;
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 10, bottom: 24),
                  child: Padding(
                    // only add horizontal padding for the narrow layout
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          cardWidth == null ? columnHorizontalPadding : 0,
                    ),
                    child: AbsorbPointer(
                      absorbing: _cardsDisabled,
                      child: Opacity(
                        opacity: _cardsDisabled ? 0.45 : 1.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!wide)
                              LayoutBuilder(
                                builder: (ctx, c) {
                                  final double side = c.maxWidth.clamp(
                                    imageMinSide,
                                    imageMaxSide,
                                  );
                                  return imageBox(side);
                                },
                              ),
                            if (!wide) const SizedBox(height: 12),
                            const SizedBox(height: 8),
                            // Beim Vorhandensein von cardWidth: Cards zentrieren und auf diese Breite beschränken
                            if (cardWidth != null)
                              Center(
                                child: SizedBox(
                                  width: cardWidth,
                                  child: card_connections(),
                                ),
                              ),
                            if (cardWidth == null) card_connections(),
                            const SizedBox(height: 12),
                            if (cardWidth != null)
                              Center(
                                child: SizedBox(
                                  width: cardWidth,
                                  child: visual.VisualisationCard(
                                    brightness: brightness,
                                    brightnessNotifier: brightnessNotifier,
                                    onBrightnessChanged:
                                        (b) => setState(() {
                                          brightness = b;
                                        }),
                                    colorNotifier: colorNotifier,
                                    color: Color.fromARGB(
                                      255,
                                      selectedColorRed,
                                      selectedColorGreen,
                                      selectedColorBlue,
                                    ),
                                    onColorChanged:
                                        (c) => setState(() {
                                          selectedColorRed = c.red;
                                          selectedColorGreen = c.green;
                                          selectedColorBlue = c.blue;
                                        }),
                                  ),
                                ),
                              ),
                            if (cardWidth == null)
                              visual.VisualisationCard(
                                brightness: brightness,
                                brightnessNotifier: brightnessNotifier,
                                onBrightnessChanged:
                                    (b) => setState(() {
                                      brightness = b;
                                    }),
                                colorNotifier: colorNotifier,
                                color: Color.fromARGB(
                                  255,
                                  selectedColorRed,
                                  selectedColorGreen,
                                  selectedColorBlue,
                                ),
                                onColorChanged:
                                    (c) => setState(() {
                                      selectedColorRed = c.red;
                                      selectedColorGreen = c.green;
                                      selectedColorBlue = c.blue;
                                    }),
                              ),
                            const SizedBox(height: 12),
                            if (cardWidth != null)
                              Center(
                                child: SizedBox(
                                  width: cardWidth,
                                  child: _safeCard(
                                    () => automation.AutomationCard(
                                      enableNightMode: enableNightMode,
                                      onHour: displayOnStunden,
                                      onMinute: displayOnMinuten,
                                      offHour: displayOffStunden,
                                      offMinute: displayOffMinuten,
                                      onEnableChanged: (v) {
                                        setState(() {
                                          enableNightMode = v;
                                        });
                                        _updateNewChanges();
                                        // user toggled automation -> send parameters
                                        sendParametersToESP();
                                      },
                                      onOnTimeChanged: (totalMinutes) {
                                        setState(() {
                                          displayOnStunden = totalMinutes ~/ 60;
                                          displayOnMinuten = totalMinutes % 60;
                                        });
                                        _updateNewChanges();
                                        sendParametersToESP();
                                      },
                                      onOffTimeChanged: (totalMinutes) {
                                        setState(() {
                                          displayOffStunden =
                                              totalMinutes ~/ 60;
                                          displayOffMinuten = totalMinutes % 60;
                                        });
                                        _updateNewChanges();
                                        sendParametersToESP();
                                      },
                                    ),
                                    label: 'Automation',
                                  ),
                                ),
                              ),
                            if (cardWidth == null)
                              _safeCard(
                                () => automation.AutomationCard(
                                  enableNightMode: enableNightMode,
                                  onHour: displayOnStunden,
                                  onMinute: displayOnMinuten,
                                  offHour: displayOffStunden,
                                  offMinute: displayOffMinuten,
                                  onEnableChanged: (v) {
                                    setState(() {
                                      enableNightMode = v;
                                    });
                                    _updateNewChanges();
                                  },
                                  onOnTimeChanged: (totalMinutes) {
                                    setState(() {
                                      displayOnStunden = totalMinutes ~/ 60;
                                      displayOnMinuten = totalMinutes % 60;
                                    });
                                    _updateNewChanges();
                                  },
                                  onOffTimeChanged: (totalMinutes) {
                                    setState(() {
                                      displayOffStunden = totalMinutes ~/ 60;
                                      displayOffMinuten = totalMinutes % 60;
                                    });
                                    _updateNewChanges();
                                  },
                                ),
                                label: 'Automation',
                              ),
                            const SizedBox(height: 12),
                            if (cardWidth != null)
                              Center(
                                child: SizedBox(
                                  width: cardWidth,
                                  child: card_alarm(),
                                ),
                              ),
                            if (cardWidth == null) card_alarm(),
                            const SizedBox(height: 12),
                            if (cardWidth != null)
                              Center(
                                child: SizedBox(
                                  width: cardWidth,
                                  child: card_timer(),
                                ),
                              ),
                            if (cardWidth == null) card_timer(),
                            const SizedBox(height: 12),
                            if (cardWidth != null)
                              Center(
                                child: SizedBox(
                                  width: cardWidth,
                                  child: offline.OfflineModeCard(
                                    offlineMode: offlineMode,
                                    utcSecond: utcaktsekunde,
                                    utcMinute: utcaktminute,
                                    utcHour: utcaktstunde,
                                    onOfflineModeChanged:
                                        (v) => setState(() {
                                          offlineMode = v;
                                          debugPrint(
                                            'offlineMode=$offlineMode',
                                          );
                                          _updateNewChanges();
                                          // offline mode changed by user -> publish params
                                          sendParametersToESP();
                                        }),
                                    onSetUtcTime:
                                        (h, m, s) => setState(() {
                                          utcaktstunde = h;
                                          utcaktminute = m;
                                          utcaktsekunde = s;
                                          debugPrint(
                                            'offline time set: $h:$m:$s',
                                          );
                                          sendParametersToESP();
                                        }),
                                  ),
                                ),
                              ),
                            if (cardWidth == null)
                              offline.OfflineModeCard(
                                offlineMode: offlineMode,
                                utcSecond: utcaktsekunde,
                                utcMinute: utcaktminute,
                                utcHour: utcaktstunde,
                                onOfflineModeChanged:
                                    (v) => setState(() {
                                      offlineMode = v;
                                      debugPrint('offlineMode=$offlineMode');
                                      _updateNewChanges();
                                    }),
                                onSetUtcTime:
                                    (h, m, s) => setState(() {
                                      utcaktstunde = h;
                                      utcaktminute = m;
                                      utcaktsekunde = s;
                                      debugPrint('offline time set: $h:$m:$s');
                                      sendParametersToESP();
                                    }),
                              ),
                            const SizedBox(height: 12),
                            if (cardWidth != null)
                              Center(
                                child: SizedBox(
                                  width: cardWidth,
                                  child: notif.NotificationCard(
                                    notificationEnable: notificationEnable,
                                    onNotificationChanged:
                                        (v) => setState(() {
                                          notificationEnable = v;
                                          debugPrint(
                                            'Notification changed -> notificationEnable=$notificationEnable',
                                          );
                                          newChanges = _computeNewChanges();
                                          // user toggled notification -> publish params
                                          sendParametersToESP();
                                        }),
                                  ),
                                ),
                              ),
                            if (cardWidth == null)
                              notif.NotificationCard(
                                notificationEnable: notificationEnable,
                                onNotificationChanged:
                                    (v) => setState(() {
                                      notificationEnable = v;
                                      debugPrint(
                                        'Notification changed -> notificationEnable=$notificationEnable',
                                      );
                                      newChanges = _computeNewChanges();
                                      sendParametersToESP();
                                    }),
                              ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              if (!wide) {
                // mobile / narrow layout: single column
                return leftColumn();
              } else {
                // wide layout: compute per-column available width. Each column will
                // contain: [gutter | content | gutter] so that the distance from the
                // content edges to both the window edges and the divider equals
                // `columnHorizontalPadding`.
                final double columnAvailable =
                    (constraints.maxWidth - verticalDividerWidth) / 2;

                // content width inside a column after reserving left/right gutter
                final double contentWidth = (columnAvailable -
                        (2 * columnHorizontalPadding))
                    .clamp(0.0, double.infinity);

                // Side wird mit dynamischen min/max geclamped (unterscheidet mobile/pc)
                final double side = contentWidth.clamp(
                  imageMinSide,
                  imageMaxSide,
                );

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // linker Bereich: feste Breite = columnAvailable
                    SizedBox(
                      width: columnAvailable,
                      child: SizedBox(
                        height: constraints.maxHeight,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: columnHorizontalPadding,
                            ),
                            child: imageBox(side),
                          ),
                        ),
                      ),
                    ),

                    // vertikaler Trenner mit symmetrischem Abstand
                    const VerticalDivider(
                      width: verticalDividerWidth,
                      thickness: 1,
                      indent: 12,
                      endIndent: 12,
                      color: Color(0xFFE9EEF3),
                    ),

                    // rechter Bereich: feste Breite = columnAvailable -> Cards mit contentWidth
                    SizedBox(
                      width: columnAvailable,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: columnHorizontalPadding,
                        ),
                        child: leftColumn(cardWidth: side),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  // Build the connections card using this state's canonical fields so the
  // callbacks can directly update `Ssid`, `Password` and `LoginSaved`.
  Widget card_connections() {
    return conn.EspWifiCard(
      loginSaved: loginsaved,
      ssid: ssid,
      password: password,
      ssidController: _ssidController,
      passwordController: _passwordController,
      onConnect:
          (newSsid, newPassword) => setState(() {
            // Immediately accept the connection: update canonical fields,
            // update controllers so the inputs reflect the connected values,
            // and show the connected state in the UI.
            ssid = newSsid;
            password = newPassword;
            _ssidController.text = newSsid;
            _passwordController.text = newPassword;
            loginsaved = 1;
            // Treat an explicit Connect as a confirmed change for SSID/password
            // so the UI shouldn't show the "Übernehmen" (unsaved changes)
            // state. Update the baseline snapshot for these fields.
            _baseSsid = ssid;
            _basePassword = password;
            // Recompute newChanges (should be false after snapshot)
            newChanges = _computeNewChanges();
            // Print debug info immediately on connect
            debugPrint('Connect pressed -> ssid=$ssid');
            debugPrint('Connect pressed -> password=$password');
            // Send full parameter debug to ESP/log
            sendParametersToESP();
          }),
      onDisconnect:
          () => setState(() {
            // Clear canonical fields and controllers on disconnect
            loginsaved = 0;
            ssid = '';
            password = '';
            _ssidController.clear();
            _passwordController.clear();
            // Treat disconnect as a confirmed change (no Apply needed):
            // update baseline snapshot to match the cleared state so the
            // "Übernehmen" button does not appear.
            _baseSsid = '';
            _basePassword = '';
            newChanges = _computeNewChanges();
            debugPrint('Disconnected -> cleared ssid/password');
            sendParametersToESP();
          }),
    );
  }

  // Build the timer card using this state's canonical timer fields so the
  // TimerCard can update the state via callbacks.
  Widget card_timer() {
    // Timer-Initialisierung: Berechne verbleibende Zeit nur, wenn mindestens eine Auslösezeit ≠ 0 ist
    int initialHours = timerDurationStunden;
    int initialMinutes = timerDurationMinuten;
    int initialSeconds = timerDurationSekunden;
    if (timerEnable == 1 &&
        (timerAusloesungStunden != 0 ||
            timerAusloesungMinuten != 0 ||
            timerAusloesungSekunden != 0)) {
      final now = DateTime.now();
      int startSeconds =
          timerAusloesungStunden * 3600 +
          timerAusloesungMinuten * 60 +
          timerAusloesungSekunden;
      int durationSeconds =
          timerDurationStunden * 3600 +
          timerDurationMinuten * 60 +
          timerDurationSekunden;
      int ausloeseSeconds = (startSeconds + durationSeconds) % (24 * 3600);
      int nowSeconds = now.hour * 3600 + now.minute * 60 + now.second;
      // Prüfe, ob Timer abgelaufen ist (jetzt >= Auslösezeit + Dauer, inkl. Mitternacht-Überlauf)
      bool expired = false;
      if (startSeconds <= ausloeseSeconds) {
        // Normaler Fall, kein Mitternacht-Überlauf
        expired =
            (nowSeconds >= ausloeseSeconds) || (nowSeconds < startSeconds);
      } else {
        // Mitternacht-Überlauf: Auslösung ist am nächsten Tag
        expired =
            (nowSeconds >= ausloeseSeconds) && (nowSeconds < startSeconds);
      }
      if (expired) {
        initialHours = 0;
        initialMinutes = 0;
        initialSeconds = 0;
      } else {
        int remaining = (ausloeseSeconds - nowSeconds);
        if (remaining < 0) remaining += 24 * 3600;
        initialHours = remaining ~/ 3600;
        initialMinutes = (remaining % 3600) ~/ 60;
        initialSeconds = remaining % 60;
      }
    }
    return timer.TimerCard(
      initialHours: initialHours,
      initialMinutes: initialMinutes,
      initialSeconds: initialSeconds,
      timerEnable: timerEnable,
      onTimerEnableChanged:
          (val) => setState(() {
            _expectingInitialTimerDuration = val == 1;
            timerEnable = val;
            if (val == 0) {
              timerDurationStunden = 0;
              timerDurationMinuten = 0;
              timerDurationSekunden = 0;
              timerAusloesungStunden = 0;
              timerAusloesungMinuten = 0;
              timerAusloesungSekunden = 0;
              _expectingInitialTimerDuration = false;
              sendParametersToESP();
            } else {
              sendParametersToESP();
            }
          }),
      onTimerDurationChanged:
          (seconds) => setState(() {
            if (!_expectingInitialTimerDuration) return;
            _expectingInitialTimerDuration = false;
            final s = seconds.clamp(0, 24 * 3600);
            timerDurationStunden = s ~/ 3600;
            timerDurationMinuten = (s % 3600) ~/ 60;
            timerDurationSekunden = s % 60;
            // Speichere Systemzeit als Auslösezeit
            final now = DateTime.now();
            timerAusloesungStunden = now.hour;
            timerAusloesungMinuten = now.minute;
            timerAusloesungSekunden = now.second;
            sendParametersToESP();
          }),
    );
  }

  // Build the alarm card using this state's canonical alarm fields so the
  // AlarmCard can update the state via callbacks.
  Widget card_alarm() {
    return alarm.AlarmCard(
      alarmEnable: alarmEnable,
      onAlarmEnableChanged:
          (val) => setState(() {
            alarmEnable = val;
            if (val == 0) {
              // When alarm is deactivated externally, clear stored time fields
              alarmTimeStunden = 0;
              alarmTimeMinuten = 0;
            }
            debugPrint('Alarm enable changed -> alarmEnable=$alarmEnable');
            sendParametersToESP();
          }),
      onAlarmTimeChanged:
          (totalMinutes) => setState(() {
            final safe = totalMinutes.clamp(0, 24 * 60 - 1);
            alarmTimeStunden = safe ~/ 60;
            alarmTimeMinuten = safe % 60;
            debugPrint(
              'Alarm time set -> ${alarmTimeStunden}:${alarmTimeMinuten}',
            );
            sendParametersToESP();
          }),
    );
  }
}

// --- Cards: keine horizontalen Margins mehr, Spalten-Padding sorgt für Abstand ---

Widget cardBase(String title) {
  return Card(
    color: Colors.white,
    elevation: 1,
    shape: RoundedRectangleBorder(
      side: BorderSide(color: Colors.grey.shade200, width: 1),
      borderRadius: BorderRadius.circular(14),
    ),
    child: SizedBox(
      height: 140,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    ),
  );
}

Widget card_automation() => cardBase('Automation');
Widget card_offline_mode() => cardBase('Offline Mode');
