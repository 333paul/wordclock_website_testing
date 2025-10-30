import 'package:flutter/material.dart';

/// Modern visualisation card:
/// - "Darstellung" title
/// - Brightness slider (with smoother update)
/// - Color palette with tap selection
class VisualisationCard extends StatefulWidget {
  const VisualisationCard({
    Key? key,
    required this.brightness,
    required this.onBrightnessChanged,
    required this.color,
    required this.onColorChanged,
    this.brightnessNotifier,
    this.colorNotifier,
  }) : super(key: key);

  final double brightness;
  final ValueChanged<double> onBrightnessChanged;
  final Color color;
  final ValueChanged<Color> onColorChanged;

  /// Optional notifiers for optimized local state updates
  final ValueNotifier<double>? brightnessNotifier;
  final ValueNotifier<Color>? colorNotifier;

  @override
  State<VisualisationCard> createState() => _VisualisationCardState();
}

class _VisualisationCardState extends State<VisualisationCard> {
  late double _localBrightness;
  // controller + repetition to simulate infinite horizontal scrolling
  late final ScrollController _swatchScrollController;
  static const int _repeatFactor = 800; // large enough to feel "infinite"
  late final int _totalSwatches;
  static const double _swatchSize = 56.0;
  static const double _swatchHorizontalPadding =
      8.0; // left+right from Padding(4)
  static const double _swatchExtent = _swatchSize + _swatchHorizontalPadding;

  @override
  void initState() {
    super.initState();
    _localBrightness = widget.brightness;
    widget.brightnessNotifier?.addListener(_brightnessNotifierListener);
    widget.colorNotifier?.addListener(_colorNotifierListener);
    // prepare repeated swatch list and place scroll in the middle so user can
    // swipe both directions and experience a wrap-around effect.
    _totalSwatches = _colors.length * _repeatFactor;
    final int initialIndex = _totalSwatches ~/ 2;
    _swatchScrollController = ScrollController(
      initialScrollOffset: initialIndex * _swatchExtent,
    );
  }

  @override
  void dispose() {
    widget.brightnessNotifier?.removeListener(_brightnessNotifierListener);
    widget.colorNotifier?.removeListener(_colorNotifierListener);
    _swatchScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant VisualisationCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // keep local brightness in sync when parent updates externally
    if (oldWidget.brightness != widget.brightness) {
      _localBrightness = widget.brightness;
    }

    // re-register notifiers if changed
    if (oldWidget.brightnessNotifier != widget.brightnessNotifier) {
      oldWidget.brightnessNotifier?.removeListener(_brightnessNotifierListener);
      widget.brightnessNotifier?.addListener(_brightnessNotifierListener);
      if (widget.brightnessNotifier != null) {
        _localBrightness = widget.brightnessNotifier!.value;
      }
    }

    if (oldWidget.colorNotifier != widget.colorNotifier) {
      oldWidget.colorNotifier?.removeListener(_colorNotifierListener);
      widget.colorNotifier?.addListener(_colorNotifierListener);
    }
  }

  void _brightnessNotifierListener() {
    setState(() {
      _localBrightness = widget.brightnessNotifier!.value;
    });
  }

  void _colorNotifierListener() {
    setState(() {}); // only repaint color swatch selection
  }

  // palette of 10 muted colors
  final List<Color> _colors = const [
    Color.fromARGB(255, 255, 243, 224),
    Color.fromARGB(255, 255, 255, 255),
    Color.fromARGB(255, 230, 190, 40),
    Color.fromARGB(255, 200, 110, 35),
    Color.fromARGB(255, 180, 40, 40),
    Color.fromARGB(255, 180, 70, 120),
    Color.fromARGB(255, 110, 70, 180),
    Color.fromARGB(255, 60, 110, 180),
    Color.fromARGB(255, 50, 150, 150),
    Color.fromARGB(255, 50, 150, 80),
  ];

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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Darstellung',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Brightness section
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 2.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Helligkeit',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 10,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 18,
                            ),
                            activeTrackColor: Colors.blueGrey,
                            inactiveTrackColor: Colors.grey.shade200,
                            thumbColor: Colors.blueGrey,
                            valueIndicatorColor: Colors.blueGrey,
                            valueIndicatorTextStyle: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          child: Slider(
                            min: 0,
                            max: 100,
                            divisions: 100,
                            value: _localBrightness,
                            label: '${_localBrightness.round()}%',
                            onChanged: (v) {
                              // reduce rebuild frequency to every ~0.5%
                              if ((v - _localBrightness).abs() >= 0.5) {
                                setState(() => _localBrightness = v);
                              }
                            },
                            onChangeEnd: (v) {
                              if (widget.brightnessNotifier != null) {
                                widget.brightnessNotifier!.value = v;
                              } else {
                                widget.onBrightnessChanged(v);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 34,
                        child: Text(
                          '${_localBrightness.round()}%',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Divider(
                    height: 18,
                    thickness: 1,
                    color: Colors.grey.shade100,
                  ),
                  const SizedBox(height: 8),

                  const Text(
                    'Farbstil',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    height: 58, // compact
                    child: ListView.builder(
                      controller: _swatchScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      itemCount: _totalSwatches,
                      itemBuilder: (context, i) {
                        final int idx = i % _colors.length;
                        final Color currentColor =
                            widget.colorNotifier?.value ?? widget.color;
                        final bool selected =
                            currentColor.value == _colors[idx].value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              overlayColor:
                                  MaterialStateProperty.resolveWith<Color?>(
                                    (states) =>
                                        states.contains(MaterialState.pressed)
                                            ? Colors.black.withOpacity(0.10)
                                            : null,
                                  ),
                              onTap: () {
                                final Color chosen = _colors[idx];
                                if (widget.colorNotifier != null) {
                                  widget.colorNotifier!.value = chosen;
                                } else {
                                  widget.onColorChanged(chosen);
                                }
                              },
                              child: Ink(
                                width: _swatchSize,
                                height: _swatchSize,
                                decoration: BoxDecoration(
                                  color: _colors[idx],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color:
                                        selected
                                            ? Colors.black26
                                            : Colors.grey.shade200,
                                    width: selected ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 3,
                                      offset: const Offset(0, 1.5),
                                    ),
                                  ],
                                ),
                                child:
                                    selected
                                        ? Center(
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                0.45,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        )
                                        : null,
                              ),
                            ),
                          ),
                        );
                      },
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
