import 'package:flutter/material.dart';
import 'dart:async';

class AlarmCard extends StatefulWidget {
  final int alarmEnable; // 0 = aus, 1 = aktiv
  final ValueChanged<int>
  onAlarmEnableChanged; // inform parent when enable toggles
  final ValueChanged<int> onAlarmTimeChanged; // total minutes since midnight

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

    // If the alarm is active on creation, start checking the clock.
    if (_isRunning) _startClockWatcher();
  }

  @override
  void didUpdateWidget(covariant AlarmCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If external owner disabled the alarm, make sure we stop.
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
    // Check every second whether the real clock matches the selected time
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      if (_isRunning &&
          now.hour == _selectedHours &&
          now.minute == _selectedMinutes) {
        // Alarm time reached
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
      // Reset
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
      // Deactivate
      _stopClockWatcher();
      setState(() => _isRunning = false);
      widget.onAlarmEnableChanged(0);
    } else {
      // Activate: read current wheel positions and start watcher
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
            // Responsive spacing: compute gap from available width so the
            // space between Hours, Minutes and 'Uhr' scales with the card.
            LayoutBuilder(
              builder: (context, constraints) {
                // widths of the two pickers base size
                const double basePickerWidth = 70.0;
                // approximate width for the 'Uhr' label
                const double labelWidth = 40.0;
                // width reserved for the colon between pickers
                const double colonWidth = 18.0;
                const double minGap = 8.0;
                const double minPickerWidth = 48.0;
                final double avail = constraints.maxWidth;

                // We want four equal gaps: outer-left, between1, between2, outer-right
                const int gapCount = 4;

                // If there's not enough space for the base sizes + min gaps,
                // scale down the pickers proportionally (but not below minPickerWidth).
                final double requiredForFixed =
                    basePickerWidth * 2 +
                    labelWidth +
                    colonWidth +
                    minGap * gapCount;
                double pickerWidth = basePickerWidth;
                if (avail < requiredForFixed) {
                  final double remainingForPickers = (avail -
                          labelWidth -
                          minGap * gapCount)
                      .clamp(0.0, double.infinity);
                  final double scale =
                      remainingForPickers / (basePickerWidth * 2);
                  pickerWidth = (basePickerWidth * scale).clamp(
                    minPickerWidth,
                    basePickerWidth,
                  );
                }

                final double totalFixed =
                    pickerWidth * 2 + labelWidth + colonWidth;
                final double remaining = (avail - totalFixed).clamp(
                  0.0,
                  double.infinity,
                );

                // Prefer outer gaps to be larger than inner gaps. We model
                // outer:inner as 2:1. That means total units = 2+1+1+2 = 6 units.
                const double minOuterGap = 6.0;

                // Make the gap between hours and minutes smaller than the gap
                // between minutes and the 'Uhr' label. We'll compute three
                // gaps: gapHM (hours-minutes), gapMU (minutes-Uhr), and
                // outerGap (left/right). outerGap should absorb most extra
                // space. Enforce sensible minimums.
                const double minInnerHM = 1.0; // very small
                const double minInnerMU = 4.0; // somewhat larger
                const double maxInnerMU = 12.0;

                double gapHM;
                double gapMU;
                double outerGap;

                // Minimal total width required for horizontal layout (include colon)
                final double minTotal =
                    2.0 * minPickerWidth +
                    labelWidth +
                    colonWidth +
                    minInnerHM +
                    minInnerMU +
                    2.0 * minOuterGap;

                if (avail < minTotal) {
                  // Not enough room: we'll stack the pickers vertically instead
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: minPickerWidth,
                        child: Center(
                          child: _buildPicker(
                            itemCount: 24,
                            controller: _hoursController,
                            onSelected:
                                (i) => setState(() => _selectedHours = i),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: minPickerWidth,
                        child: Center(
                          child: _buildPicker(
                            itemCount: 60,
                            controller: _minutesController,
                            onSelected:
                                (i) => setState(() => _selectedMinutes = i),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Uhr',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  );
                } else if (remaining <= 0) {
                  // No extra space — fallback to minima
                  gapHM = minInnerHM;
                  gapMU = minInnerMU;
                  outerGap = minOuterGap;
                } else {
                  // Try to reserve minima for inner gaps and give remainder to outerGap
                  final double minRequired =
                      minInnerHM + minInnerMU + 2.0 * minOuterGap;
                  if (remaining <= minRequired) {
                    // Tight: give minima and whatever is left to outerGap
                    gapHM = minInnerHM;
                    gapMU = minInnerMU;
                    outerGap = ((remaining - gapHM - gapMU) / 2.0).clamp(
                      0.0,
                      double.infinity,
                    );
                    if (outerGap < minOuterGap) outerGap = minOuterGap;
                  } else {
                    // Plenty of room: keep gapHM small, let gapMU grow a bit,
                    // and assign leftover to outerGap.
                    gapHM = minInnerHM;
                    // Give up to 30% of extra space (beyond minima) to gapMU,
                    // but cap it to avoid huge inner gaps.
                    final double extra =
                        remaining -
                        (minInnerHM + minInnerMU + 2.0 * minOuterGap);
                    gapMU = (minInnerMU + extra * 0.3).clamp(
                      minInnerMU,
                      maxInnerMU,
                    );
                    outerGap = ((remaining - gapHM - gapMU) / 2.0).clamp(
                      minOuterGap,
                      double.infinity,
                    );
                    if (!outerGap.isFinite) outerGap = minOuterGap;
                  }
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: outerGap), // outer left gap to card edge
                    SizedBox(
                      width: pickerWidth,
                      child: Center(
                        child: _buildPicker(
                          itemCount: 24,
                          controller: _hoursController,
                          onSelected: (i) => setState(() => _selectedHours = i),
                        ),
                      ),
                    ),
                    SizedBox(width: gapHM / 2.0),
                    SizedBox(
                      width: 18.0,
                      child: Center(
                        child: Text(
                          ':',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: gapHM / 2.0),
                    SizedBox(
                      width: pickerWidth,
                      child: Center(
                        child: _buildPicker(
                          itemCount: 60,
                          controller: _minutesController,
                          onSelected:
                              (i) => setState(() => _selectedMinutes = i),
                        ),
                      ),
                    ),
                    SizedBox(width: gapMU),
                    SizedBox(
                      width: labelWidth,
                      child: Center(
                        child: Text(
                          'Uhr',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: outerGap), // outer right gap to card edge
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _isFinished
                ? OutlinedButton(
                  onPressed: _toggleAlarm,
                  style: buttonStyle,
                  child: Text(buttonText),
                )
                : ElevatedButton(
                  onPressed: _toggleAlarm,
                  style: buttonStyle,
                  child: Text(buttonText),
                ),
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
