import 'package:flutter/material.dart';

class OfflineModeCard extends StatefulWidget {
  final int offlineMode; // 0 = off, 1 = on
  final int utcSecond;
  final int utcMinute;
  final int utcHour;
  final ValueChanged<int> onOfflineModeChanged;
  final void Function(int hour, int minute, int second) onSetUtcTime;

  const OfflineModeCard({
    Key? key,
    required this.offlineMode,
    required this.utcSecond,
    required this.utcMinute,
    required this.utcHour,
    required this.onOfflineModeChanged,
    required this.onSetUtcTime,
  }) : super(key: key);

  @override
  State<OfflineModeCard> createState() => _OfflineModeCardState();
}

class _OfflineModeCardState extends State<OfflineModeCard> {
  bool _showManual = false;

  late final FixedExtentScrollController _hoursController;
  late final FixedExtentScrollController _minutesController;
  late final FixedExtentScrollController _secondsController;

  @override
  void initState() {
    super.initState();
    _hoursController = FixedExtentScrollController(initialItem: widget.utcHour);
    _minutesController = FixedExtentScrollController(
      initialItem: widget.utcMinute,
    );
    _secondsController = FixedExtentScrollController(
      initialItem: widget.utcSecond,
    );
  }

  @override
  void didUpdateWidget(covariant OfflineModeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.utcHour != widget.utcHour) {
      try {
        _hoursController.jumpToItem(widget.utcHour.clamp(0, 23));
      } catch (_) {}
    }
    if (oldWidget.utcMinute != widget.utcMinute) {
      try {
        _minutesController.jumpToItem(widget.utcMinute.clamp(0, 59));
      } catch (_) {}
    }
    if (oldWidget.utcSecond != widget.utcSecond) {
      try {
        _secondsController.jumpToItem(widget.utcSecond.clamp(0, 59));
      } catch (_) {}
    }
    if (oldWidget.offlineMode == 1 && widget.offlineMode == 0) {
      setState(() => _showManual = false);
    }
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    double width = 70,
  }) {
    return SizedBox(
      width: width,
      height: 50,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ListWheelScrollView.useDelegate(
          controller: controller,
          itemExtent: 50,
          perspective: 0.00001,
          overAndUnderCenterOpacity: 0.0,
          physics: const FixedExtentScrollPhysics(),
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
    );
  }

  void _applyManual() {
    final int hour = _hoursController.selectedItem % 24;
    final int minute = _minutesController.selectedItem % 60;
    final int second = _secondsController.selectedItem % 60;
    try {
      widget.onSetUtcTime(hour, minute, second);
    } catch (_) {}
  }

  void _useSystemTime() {
    final now = DateTime.now();
    try {
      widget.onSetUtcTime(now.hour, now.minute, now.second);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.offlineMode == 1;

    return Card(
      color: Colors.white,
      elevation: 0, // keine Schatten
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Offline-Modus',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 14),

            // Switch row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: enabled,
                    onChanged: (v) {
                      widget.onOfflineModeChanged(v ? 1 : 0);
                      setState(() {
                        if (!v) _showManual = false;
                      });
                    },
                    activeColor: Colors.blueGrey,
                  ),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Wordclock offline betreiben',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed:
                          enabled
                              ? () => setState(() => _showManual = true)
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Manuelle Eingabe'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: enabled ? _useSystemTime : null,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Systemzeit verwenden'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Manual picker in separate box
            if (_showManual && enabled) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100], // leicht dunkleres Weiß
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            const Text(
                              'Std',
                              style: TextStyle(color: Colors.black54),
                            ),
                            _wheel(controller: _hoursController, itemCount: 24),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Column(
                          children: [
                            const Text(
                              'Min',
                              style: TextStyle(color: Colors.black54),
                            ),
                            _wheel(
                              controller: _minutesController,
                              itemCount: 60,
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Column(
                          children: [
                            const Text(
                              'Sek',
                              style: TextStyle(color: Colors.black54),
                            ),
                            _wheel(
                              controller: _secondsController,
                              itemCount: 60,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _applyManual,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Übernehmen'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
