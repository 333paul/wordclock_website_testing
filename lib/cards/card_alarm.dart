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

  Widget _buildPicker({
    required int itemCount,
    required FixedExtentScrollController controller,
    required ValueChanged<int> onSelected,
  }) {
    return SizedBox(
      height: 50,
      width: 70,
      child: ClipRect(
        child: ListWheelScrollView.useDelegate(
          controller: controller,
          itemExtent: 50,
          perspective: 0.00001,
          overAndUnderCenterOpacity: 0.0,
          physics:
              _isRunning
                  ? const NeverScrollableScrollPhysics()
                  : const FixedExtentScrollPhysics(),
          onSelectedItemChanged: _isRunning ? null : onSelected,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: itemCount,
            builder: (context, index) {
              return Center(
                child: Text(
                  index.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              );
            },
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
                double totalWidth = constraints.maxWidth;

                // Kleinere Abstände
                const double gapHM = 1.0; // Stunden <-> Minuten
                const double gapMU = 2.0; // Minuten <-> Uhr
                const double colonWidth = 12.0;

                // Picker-Grundwerte
                const double pickerMax = 70.0;
                const double pickerMin = 44.0;
                const double labelWidth = 26.0;

                // Gesamter Platzbedarf für horizontal
                double requiredWidth =
                    pickerMax * 2 + gapHM * 2 + colonWidth + gapMU + labelWidth;

                // Wenn zu wenig Platz → vertikales Layout
                if (totalWidth < requiredWidth + 40) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: pickerMin,
                            child: _buildPicker(
                              itemCount: 24,
                              controller: _hoursController,
                              onSelected:
                                  (i) => setState(() => _selectedHours = i),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(':', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: pickerMin,
                            child: _buildPicker(
                              itemCount: 60,
                              controller: _minutesController,
                              onSelected:
                                  (i) => setState(() => _selectedMinutes = i),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Uhr'),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _toggleAlarm,
                          style: buttonStyle,
                          child: Text(buttonText),
                        ),
                      ),
                    ],
                  );
                }

                // passt → horizontales Layout
                return Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: pickerMax,
                            child: _buildPicker(
                              itemCount: 24,
                              controller: _hoursController,
                              onSelected:
                                  (i) => setState(() => _selectedHours = i),
                            ),
                          ),
                          SizedBox(width: gapHM),
                          SizedBox(
                            width: colonWidth,
                            child: const Center(
                              child: Text(':', style: TextStyle(fontSize: 18)),
                            ),
                          ),
                          SizedBox(width: gapHM),
                          SizedBox(
                            width: pickerMax,
                            child: _buildPicker(
                              itemCount: 60,
                              controller: _minutesController,
                              onSelected:
                                  (i) => setState(() => _selectedMinutes = i),
                            ),
                          ),
                          SizedBox(width: gapMU),
                          SizedBox(
                            width: labelWidth,
                            child: const Center(
                              child: Text(
                                'Uhr',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    SizedBox(
                      width: 150,
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

            const SizedBox(height: 8),
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
