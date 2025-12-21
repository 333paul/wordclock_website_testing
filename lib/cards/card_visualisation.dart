import 'package:flutter/material.dart';
import 'dart:io' show Platform;

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
  // Reduced repeat factor: large factors create very long scroll extents
  // which are expensive to layout when the window size changes. 80 gives
  // a good feel while keeping layout cheap.
  // Reduced repeat factor: keep it small for cheap layout while still
  // allowing simple left/right swiping feel.
  static const int _repeatFactor = 32; // lower = less layout cost
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
    // Avoid setting a huge initialScrollOffset in the controller constructor
    // (which forces the scrollable to compute very large extents during build).
    // Instead create the controller with default offset and jump after first
    // frame when layout is ready.
    _swatchScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final double offset = initialIndex * _swatchExtent;
      // Guard: ensure offset is finite
      if (offset.isFinite) _swatchScrollController.jumpTo(offset);
    });
  }

  @override
  void didUpdateWidget(covariant VisualisationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If notifier instances changed, make sure we remove listeners from the
    // old ones and add them to the new ones to avoid leaks or no-op updates.
    if (oldWidget.brightnessNotifier != widget.brightnessNotifier) {
      oldWidget.brightnessNotifier?.removeListener(_brightnessNotifierListener);
      widget.brightnessNotifier?.addListener(_brightnessNotifierListener);
    }

    if (oldWidget.colorNotifier != widget.colorNotifier) {
      oldWidget.colorNotifier?.removeListener(_colorNotifierListener);
      widget.colorNotifier?.addListener(_colorNotifierListener);
    }
  }

  void _colorNotifierListener() {
    setState(() {}); // only repaint color swatch selection
  }

  void _brightnessNotifierListener() {
    // Sync the local slider value with external notifier changes.
    final v = widget.brightnessNotifier?.value ?? widget.brightness;
    if ((v - _localBrightness).abs() > 0.01) {
      setState(() => _localBrightness = v);
    }
  }

  @override
  void dispose() {
    // Remove any listeners we added to external notifiers to avoid
    // calling back into disposed state objects.
    widget.brightnessNotifier?.removeListener(_brightnessNotifierListener);
    widget.colorNotifier?.removeListener(_colorNotifierListener);
    _swatchScrollController.dispose();
    super.dispose();
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

                  Row(
                    children: [
                      if (Platform.isWindows)
                        IconButton(
                          icon: const Icon(Icons.arrow_left),
                          tooltip: 'Zurück',
                          onPressed: () {
                            final double offset =
                                _swatchScrollController.offset - _swatchExtent;
                            _swatchScrollController.animateTo(
                              offset < 0 ? 0 : offset,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                            );
                          },
                        ),
                      Expanded(
                        child: SizedBox(
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
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
                                                  ? Colors.black
                                                  : Colors.black26,
                                          width: selected ? 2 : 1,
                                        ),
                                      ),
                                      child:
                                          selected
                                              ? Icon(
                                                Icons.check,
                                                color:
                                                    _colors[idx].computeLuminance() >
                                                            0.6
                                                        ? Colors.black
                                                        : Colors.white,
                                              )
                                              : null,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      if (Platform.isWindows)
                        IconButton(
                          icon: const Icon(Icons.arrow_right),
                          tooltip: 'Weiter',
                          onPressed: () {
                            final double maxScroll =
                                _swatchScrollController
                                    .position
                                    .maxScrollExtent;
                            final double offset =
                                _swatchScrollController.offset + _swatchExtent;
                            _swatchScrollController.animateTo(
                              offset > maxScroll ? maxScroll : offset,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                            );
                          },
                        ),
                    ],
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
