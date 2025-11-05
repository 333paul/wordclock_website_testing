import 'package:flutter/material.dart';
import 'dart:async';

class TimerCard extends StatefulWidget {
  final int timerEnable; // 0 = aus, 1 = läuft
  final ValueChanged<int> onTimerEnableChanged;
  final ValueChanged<int> onTimerDurationChanged; // in Sekunden

  const TimerCard({
    Key? key,
    required this.timerEnable,
    required this.onTimerEnableChanged,
    required this.onTimerDurationChanged,
  }) : super(key: key);

  @override
  State<TimerCard> createState() => _TimerCardState();
}

class _TimerCardState extends State<TimerCard> {
  int _selectedHours = 0;
  int _selectedMinutes = 0;
  int _selectedSeconds = 0;

  late bool _isRunning;
  bool _isFinished = false;
  Timer? _timer;
  int _remainingSeconds = 0;

  // 👇 Controller für jedes Wheel
  // Lazily initialize controllers in initState with the current selected values
  late final FixedExtentScrollController _hoursController;
  late final FixedExtentScrollController _minutesController;
  late final FixedExtentScrollController _secondsController;

  @override
  void initState() {
    super.initState();
    // initialize controllers at the currently selected items so the wheel
    // shows the correct initial values and selectedItem reflects user input
    _hoursController = FixedExtentScrollController(initialItem: _selectedHours);
    _minutesController = FixedExtentScrollController(
      initialItem: _selectedMinutes,
    );
    _secondsController = FixedExtentScrollController(
      initialItem: _selectedSeconds,
    );
    _isRunning = widget.timerEnable == 1;
    _remainingSeconds = _totalSeconds;
  }

  @override
  void didUpdateWidget(covariant TimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If parent turned the timer off externally (e.g. app lifecycle) cancel
    // our internal timer and update local state to match.
    if (oldWidget.timerEnable == 1 && widget.timerEnable == 0 && _isRunning) {
      _timer?.cancel();
      setState(() {
        _isRunning = false;
        _isFinished = false;
        _remainingSeconds = 0;
      });
      // Inform parent that we are stopped (defensive — parent likely already set this),
      // and that there is no remaining duration.
      try {
        widget.onTimerEnableChanged(0);
        widget.onTimerDurationChanged(0);
      } catch (_) {}
    }
  }

  int get _totalSeconds =>
      _selectedHours * 3600 + _selectedMinutes * 60 + _selectedSeconds;

  void _toggleTimer() {
    if (_isFinished) {
      // Zurücksetzen
      setState(() {
        _isFinished = false;
        _remainingSeconds = _totalSeconds;
      });
      _updateScrollControllers(); // 👈 Scrollposition zurücksetzen
      // Notify parent that the timer was reset so main can clear any
      // canonical timer state if desired.
      widget.onTimerEnableChanged(0);
      widget.onTimerDurationChanged(0);
      return;
    }

    if (_isRunning) {
      // Stoppen
      _timer?.cancel();
      setState(() => _isRunning = false);
      widget.onTimerEnableChanged(0);
    } else {
      // Starten
      // read current wheel positions (in case user pressed Start while
      // scrolling and onSelectedItemChanged hasn't fired yet)
      setState(() {
        _selectedHours = _hoursController.selectedItem;
        _selectedMinutes = _minutesController.selectedItem;
        _selectedSeconds = _secondsController.selectedItem;
      });

      final total = _totalSeconds;
      if (total == 0) return;

      setState(() {
        _isRunning = true;
        _isFinished = false;
        _remainingSeconds = total;
      });

      widget.onTimerEnableChanged(1);
      widget.onTimerDurationChanged(total);

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
            _updateScrollControllers();
          });
          // notify parent of remaining time each tick so main.dart can
          // keep separate hours/minutes/seconds fields in sync
          widget.onTimerDurationChanged(_remainingSeconds);
        }

        if (_remainingSeconds == 0) {
          timer.cancel();
          setState(() {
            _isRunning = false;
            _isFinished = true;
          });
          widget.onTimerEnableChanged(0);
          widget.onTimerDurationChanged(0);
        }
      });
    }
  }

  // 👇 Aktualisiert die Scrollposition der drei Wheels
  void _updateScrollControllers() {
    final hours = _remainingSeconds ~/ 3600;
    final minutes = (_remainingSeconds % 3600) ~/ 60;
    final seconds = _remainingSeconds % 60;

    // Animiert auf den neuen Wert
    _hoursController.jumpToItem(hours);
    _minutesController.jumpToItem(minutes);
    _secondsController.jumpToItem(seconds);
  }

  Widget _buildPicker({
    required String label,
    required int itemCount,
    required int selectedValue,
    required FixedExtentScrollController controller,
    required ValueChanged<int> onSelected,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 50,
          width: 70,
          child: ClipRect(
            child: ListWheelScrollView.useDelegate(
              controller: controller,
              itemExtent: 50,
              perspective: 0.00001,
              overAndUnderCenterOpacity: 0.0,
              // 👇 Nur scrollen, wenn Timer NICHT läuft
              physics:
                  _isRunning
                      ? const NeverScrollableScrollPhysics()
                      : const FixedExtentScrollPhysics(),
              // 👇 Nur reagieren, wenn Timer NICHT läuft
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
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String buttonText;
    ButtonStyle buttonStyle;

    if (_isRunning) {
      buttonText = 'Abbrechen';
      buttonStyle = ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        minimumSize: const Size(double.infinity, 40),
        side: BorderSide(color: Colors.black26, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // 👈 Rundung
        ),
      );
    } else if (_isFinished) {
      buttonText = 'Zurücksetzen';
      buttonStyle = OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.green,
        minimumSize: const Size(double.infinity, 40),
        side: BorderSide(color: Colors.green, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // 👈 Rundung
        ),
      );
    } else {
      buttonText = 'Starten';
      buttonStyle = ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // 👈 Rundung
        ),
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
              'Timer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPicker(
                  label: 'Stunden',
                  itemCount: 24,
                  selectedValue: _selectedHours,
                  controller: _hoursController,
                  onSelected: (index) => setState(() => _selectedHours = index),
                ),
                _buildPicker(
                  label: 'Minuten',
                  itemCount: 60,
                  selectedValue: _selectedMinutes,
                  controller: _minutesController,
                  onSelected:
                      (index) => setState(() => _selectedMinutes = index),
                ),
                _buildPicker(
                  label: 'Sekunden',
                  itemCount: 60,
                  selectedValue: _selectedSeconds,
                  controller: _secondsController,
                  onSelected:
                      (index) => setState(() => _selectedSeconds = index),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _isFinished
                ? OutlinedButton(
                  onPressed: _toggleTimer,
                  style: buttonStyle,
                  child: Text(buttonText),
                )
                : ElevatedButton(
                  onPressed: _toggleTimer,
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
    _secondsController.dispose();
    super.dispose();
  }
}
