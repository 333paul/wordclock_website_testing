import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _enabled = widget.notificationEnable == 1;
  }

  void _toggleSwitch(bool value) {
    setState(() {
      _enabled = value;
      widget.onNotificationChanged(_enabled ? 1 : 0);
    });
  }

  @override
  Widget build(BuildContext context) {
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
