import 'package:flutter/material.dart';

class AutomationCard extends StatefulWidget {
  final int enableNightMode; // 0 = aus, 1 = an
  final int onHour;
  final int onMinute;
  final int offHour;
  final int offMinute;
  final ValueChanged<int> onEnableChanged;
  final ValueChanged<int> onOnTimeChanged; // total minutes
  final ValueChanged<int> onOffTimeChanged; // total minutes

  const AutomationCard({
    Key? key,
    required this.enableNightMode,
    required this.onHour,
    required this.onMinute,
    required this.offHour,
    required this.offMinute,
    required this.onEnableChanged,
    required this.onOnTimeChanged,
    required this.onOffTimeChanged,
  }) : super(key: key);

  @override
  State<AutomationCard> createState() => _AutomationCardState();
}

class _AutomationCardState extends State<AutomationCard> {
  late bool _enabled;
  late int _hourOn;
  late int _minuteOn;
  late int _hourOff;
  late int _minuteOff;

  late final FixedExtentScrollController _onHoursController;
  late final FixedExtentScrollController _onMinutesController;
  late final FixedExtentScrollController _offHoursController;
  late final FixedExtentScrollController _offMinutesController;

  @override
  void initState() {
    super.initState();
    _enabled = widget.enableNightMode == 1;
    _hourOn = widget.onHour.clamp(0, 23);
    _minuteOn = widget.onMinute.clamp(0, 59);
    _hourOff = widget.offHour.clamp(0, 23);
    _minuteOff = widget.offMinute.clamp(0, 59);

    _onHoursController = FixedExtentScrollController(initialItem: _hourOn);
    _onMinutesController = FixedExtentScrollController(initialItem: _minuteOn);
    _offHoursController = FixedExtentScrollController(initialItem: _hourOff);
    _offMinutesController = FixedExtentScrollController(
      initialItem: _minuteOff,
    );
  }

  @override
  void didUpdateWidget(covariant AutomationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enableNightMode != widget.enableNightMode) {
      setState(() => _enabled = widget.enableNightMode == 1);
    }
    if (oldWidget.onHour != widget.onHour) {
      _hourOn = widget.onHour.clamp(0, 23);
      try {
        _onHoursController.jumpToItem(_hourOn);
      } catch (_) {}
    }
    if (oldWidget.onMinute != widget.onMinute) {
      _minuteOn = widget.onMinute.clamp(0, 59);
      try {
        _onMinutesController.jumpToItem(_minuteOn);
      } catch (_) {}
    }
    if (oldWidget.offHour != widget.offHour) {
      _hourOff = widget.offHour.clamp(0, 23);
      try {
        _offHoursController.jumpToItem(_hourOff);
      } catch (_) {}
    }
    if (oldWidget.offMinute != widget.offMinute) {
      _minuteOff = widget.offMinute.clamp(0, 59);
      try {
        _offMinutesController.jumpToItem(_minuteOff);
      } catch (_) {}
    }
  }

  Widget _picker({
    required FixedExtentScrollController controller,
    required int itemCount,
    required ValueChanged<int>? onSelected,
    double width = 44,
    bool enabled = true,
  }) {
    // Use a larger itemExtent for smoother scrolling, and avoid setState during scroll
    return NotificationListener<ScrollEndNotification>(
      onNotification: (notification) {
        // Only fire callback when scroll ends
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
    const double colonWidth = 8.0;

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
              'Nachtmodus',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Switch + Text
            Padding(
              padding: const EdgeInsets.only(left: 5, right: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _enabled,
                      onChanged: (v) {
                        setState(() => _enabled = v);
                        try {
                          widget.onEnableChanged(v ? 1 : 0);
                        } catch (_) {}
                      },
                      activeColor: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Expanded(
                    child: Text(
                      'Automatisches Ein/Ausschalten',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Zeit-Picker Zeile mit Opacity
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Opacity(
                opacity: _enabled ? 1.0 : 0.4, // ausgegraut, wenn NightMode aus
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Ein
                    Row(
                      children: [
                        const Text(
                          'Ein:',
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                        const SizedBox(width: 4),
                        Row(
                          children: [
                            _picker(
                              controller: _onHoursController,
                              itemCount: 24,
                              width: 44,
                              onSelected:
                                  _enabled
                                      ? (i) {
                                        _hourOn = i;
                                        try {
                                          widget.onOnTimeChanged(
                                            _hourOn * 60 + _minuteOn,
                                          );
                                        } catch (_) {}
                                      }
                                      : null,
                              enabled: _enabled,
                            ),
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
                            _picker(
                              controller: _onMinutesController,
                              itemCount: 60,
                              width: 44,
                              onSelected:
                                  _enabled
                                      ? (i) {
                                        _minuteOn = i;
                                        try {
                                          widget.onOnTimeChanged(
                                            _hourOn * 60 + _minuteOn,
                                          );
                                        } catch (_) {}
                                      }
                                      : null,
                              enabled: _enabled,
                            ),
                            const SizedBox(width: 2),
                            const Text(
                              'Uhr',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                        ),
                      ],
                    ),
                    // Aus
                    Row(
                      children: [
                        const Text(
                          'Aus:',
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                        const SizedBox(width: 4),
                        Row(
                          children: [
                            _picker(
                              controller: _offHoursController,
                              itemCount: 24,
                              width: 44,
                              onSelected:
                                  _enabled
                                      ? (i) {
                                        _hourOff = i;
                                        try {
                                          widget.onOffTimeChanged(
                                            _hourOff * 60 + _minuteOff,
                                          );
                                        } catch (_) {}
                                      }
                                      : null,
                              enabled: _enabled,
                            ),
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
                            _picker(
                              controller: _offMinutesController,
                              itemCount: 60,
                              width: 44,
                              onSelected:
                                  _enabled
                                      ? (i) {
                                        _minuteOff = i;
                                        try {
                                          widget.onOffTimeChanged(
                                            _hourOff * 60 + _minuteOff,
                                          );
                                        } catch (_) {}
                                      }
                                      : null,
                              enabled: _enabled,
                            ),
                            const SizedBox(width: 2),
                            const Text(
                              'Uhr',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _onHoursController.dispose();
    _onMinutesController.dispose();
    _offHoursController.dispose();
    _offMinutesController.dispose();
    super.dispose();
  }
}
