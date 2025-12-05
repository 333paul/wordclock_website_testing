import 'package:flutter/material.dart';
import 'dart:async';

class AlarmCard extends StatefulWidget {
  final int alarmEnable;
  final ValueChanged<int> onAlarmEnableChanged;
  final ValueChanged<int> onAlarmTimeChanged;

  const AlarmCard({
    Key? key,
    required this.alarmEnable,
    required this.onAlarmEnableChanged,
    required this.onAlarmTimeChanged,
  }) : super(key: key);

  @override
  State<AlarmCard> createState() => _AlarmCardState();
}

class _AlarmCardState extends State<AlarmCard> {
  int _selectedHours = 7;
  int _selectedMinutes = 0;

  late bool _isRunning;
  bool _isFinished = false;
  Timer? _timer;

  late final FixedExtentScrollController _hoursController;
  late final FixedExtentScrollController _minutesController;

  @override
  void initState() {
    super.initState();
    _isRunning = widget.alarmEnable == 1;
    _hoursController = FixedExtentScrollController(initialItem: _selectedHours);
    _minutesController = FixedExtentScrollController(
      initialItem: _selectedMinutes,
    );

    if (_isRunning) _startClockWatcher();
  }

  @override
  void didUpdateWidget(covariant AlarmCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alarmEnable == 1 && widget.alarmEnable == 0 && _isRunning) {
      _stopClockWatcher();
      setState(() {
        _isRunning = false;
        _isFinished = false;
      });
    }
    if (oldWidget.alarmEnable == 0 && widget.alarmEnable == 1 && !_isRunning) {
      setState(() => _isRunning = true);
      _startClockWatcher();
    }
  }

  void _startClockWatcher() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      if (_isRunning &&
          now.hour == _selectedHours &&
          now.minute == _selectedMinutes) {
        _timer?.cancel();
        setState(() {
          _isRunning = false;
          _isFinished = true;
        });
        try {
          widget.onAlarmEnableChanged(0);
          widget.onAlarmTimeChanged(0);
        } catch (_) {}
      }
    });
  }

  void _stopClockWatcher() {
    _timer?.cancel();
    _timer = null;
  }

  void _toggleAlarm() {
    if (_isFinished) {
      setState(() {
        _isFinished = false;
        _isRunning = false;
      });
      try {
        widget.onAlarmEnableChanged(0);
        widget.onAlarmTimeChanged(0);
      } catch (_) {}
      return;
    }

    if (_isRunning) {
      _stopClockWatcher();
      setState(() => _isRunning = false);
      widget.onAlarmEnableChanged(0);
    } else {
      setState(() {
        _selectedHours = _hoursController.selectedItem;
        _selectedMinutes = _minutesController.selectedItem;
        _isRunning = true;
        _isFinished = false;
      });

      final totalMinutes = _selectedHours * 60 + _selectedMinutes;
      widget.onAlarmEnableChanged(1);
      widget.onAlarmTimeChanged(totalMinutes);
      _startClockWatcher();
    }
  }

  Widget _picker({
    required FixedExtentScrollController controller,
    required int itemCount,
    required ValueChanged<int>? onSelected,
    double width = 44,
    bool enabled = true,
  }) {
    return NotificationListener<ScrollEndNotification>(
      onNotification: (notification) {
        if (enabled && onSelected != null) {
          final idx = controller.selectedItem;
          onSelected(idx);
        }
        return false;
      },
      child: SizedBox(
        width: width,
        height: 56,
        child: ClipRect(
          child: ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 56,
            perspective: 0.00001,
            overAndUnderCenterOpacity: 0.0,
            physics:
                enabled
                    ? const FixedExtentScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: itemCount,
              builder:
                  (context, index) => Center(
                    child: Text(
                      index.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String buttonText;
    ButtonStyle buttonStyle;

    if (_isRunning) {
      buttonText = 'Deaktivieren';
      buttonStyle = ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        minimumSize: const Size(double.infinity, 40),
        side: BorderSide(color: Colors.black26, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );
    } else if (_isFinished) {
      buttonText = 'Zurücksetzen';
      buttonStyle = OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.green,
        minimumSize: const Size(double.infinity, 40),
        side: BorderSide(color: Colors.green, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );
    } else {
      buttonText = 'Aktivieren';
      buttonStyle = ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );
    }

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
              'Wecker',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                const double colonWidth = 8.0;
                const double pickerWidth = 44.0;
                const double uhrSpacing = 2.0;
                final double buttonWidth = 150.0;

                // Dynamischer Abstand: 30% des verbleibenden Platzes zwischen Uhrzeit und Button
                final double availableWidth =
                    constraints.maxWidth -
                    buttonWidth -
                    (pickerWidth * 2 + colonWidth + uhrSpacing + 44);
                final double spaceBetweenColumns = (availableWidth * 0.6).clamp(
                  16.0,
                  100.0,
                ); // min 16, max 100

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Spalte 1: Uhrzeit
                    Row(
                      children: [
                        _picker(
                          controller: _hoursController,
                          itemCount: 24,
                          width: pickerWidth,
                          onSelected:
                              _isRunning
                                  ? null
                                  : (i) => setState(() => _selectedHours = i),
                          enabled: !_isRunning,
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: colonWidth,
                          child: const Center(
                            child: Text(
                              ':',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        _picker(
                          controller: _minutesController,
                          itemCount: 60,
                          width: pickerWidth,
                          onSelected:
                              _isRunning
                                  ? null
                                  : (i) => setState(() => _selectedMinutes = i),
                          enabled: !_isRunning,
                        ),
                        const SizedBox(width: uhrSpacing),
                        const Text(
                          'Uhr',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ),
                    SizedBox(width: spaceBetweenColumns),
                    // Spalte 2: Button
                    SizedBox(
                      width: buttonWidth,
                      child: ElevatedButton(
                        onPressed: _toggleAlarm,
                        style: buttonStyle,
                        child: Text(buttonText),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }
}
