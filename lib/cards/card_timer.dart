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
  int _selectedMinutes = 1;
  int _selectedSeconds = 0;

  late bool _isRunning;
  bool _isFinished = false;
  Timer? _timer;
  int _remainingSeconds = 0;

  // 👇 Controller für jedes Wheel
  final FixedExtentScrollController _hoursController =
      FixedExtentScrollController();
  final FixedExtentScrollController _minutesController =
      FixedExtentScrollController();
  final FixedExtentScrollController _secondsController =
      FixedExtentScrollController();

  @override
  void initState() {
    super.initState();
    _isRunning = widget.timerEnable == 1;
    _remainingSeconds = _totalSeconds;
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
      return;
    }

    if (_isRunning) {
      // Stoppen
      _timer?.cancel();
      setState(() => _isRunning = false);
      widget.onTimerEnableChanged(0);
    } else {
      // Starten
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
        if (_remainingSeconds <= 1) {
          timer.cancel();
          setState(() {
            _isRunning = false;
            _isFinished = true;
          });
          widget.onTimerEnableChanged(0);
        } else {
          setState(() => _remainingSeconds--);
          _updateScrollControllers(); // 👈 Scrollen aktualisieren
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
                        fontSize: 20,
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
        backgroundColor: Colors.grey,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // 👈 Rundung
        ),
      );
    } else if (_isFinished) {
      buttonText = 'Zurücksetzen';
      buttonStyle = OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 40),
        side: BorderSide(color: Colors.black26, width: 1),
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
