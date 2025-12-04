import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class NotificationCard extends StatefulWidget {
  final int notificationEnable;
  final ValueChanged<int> onNotificationChanged;

  const NotificationCard({
    Key? key,
    required this.notificationEnable,
    required this.onNotificationChanged,
  }) : super(key: key);

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard> {
  late bool _enabled;
  bool _hasPermission = false;
  static const MethodChannel _platform = MethodChannel(
    'notification_permission_channel',
  );

  @override
  void initState() {
    super.initState();
    _enabled = widget.notificationEnable == 1;

    // Permission-Check erst nach dem ersten Frame starten
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermission();
    });
  }

  Future<void> _checkPermission() async {
    try {
      final bool hasPermission = await _platform.invokeMethod(
        'checkPermission',
      );
      if (!mounted) return;
      setState(() {
        _hasPermission = hasPermission;
      });
    } catch (e) {
      debugPrint('Notification permission check failed: $e');
      if (!mounted) return;
      setState(() {
        _hasPermission = false;
      });
    }
  }

  void _toggleSwitch(bool value) async {
    if (value) {
      if (_hasPermission) {
        if (!mounted) return;
        setState(() {
          _enabled = true;
        });
        widget.onNotificationChanged(1);
        return;
      }
      // Wenn keine Berechtigung, einfach deaktiviert lassen und Info anzeigen
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Benachrichtigungsberechtigung erforderlich'),
              content: const Text(
                'Die App benötigt Zugriff auf Benachrichtigungen. Bitte erlaube diese Berechtigung in den Systemeinstellungen.'
                '\n\nDu kannst die Berechtigung später in den Android-Einstellungen erteilen.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } else {
      if (!mounted) return;
      setState(() {
        _enabled = false;
      });
      widget.onNotificationChanged(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nur auf Android anzeigen, sonst gar nichts rendern
    if (kIsWeb || !Platform.isAndroid) return const SizedBox.shrink();
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200, width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Benachrichtigungen',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 5, right: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _enabled,
                      onChanged: _toggleSwitch,
                      activeColor: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Expanded(
                    child: Text(
                      'Smartphone Benachrichtigungen anzeigen',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
