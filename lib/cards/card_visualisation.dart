import 'package:flutter/material.dart';

// A modern, interactive visualization card:
// - Title "Darstellung" top-left
// - Brightness section with label + slider (swipe/drag)
// - Color style section with 10 square color swatches in a horizontal
//   scrollable row; tap to select. Selected swatch shows a checkmark.

/// VisualisationCard is the exported widget. It receives the current
/// brightness and selected color from the parent and reports changes via
/// callbacks so the parent (main.dart) can persist them.
class VisualisationCard extends StatefulWidget {
  const VisualisationCard({
    Key? key,
    required this.brightness,
    required this.onBrightnessChanged,
    required this.color,
    required this.onColorChanged,
  }) : super(key: key);

  final double brightness;
  final ValueChanged<double> onBrightnessChanged;
  final Color color;
  final ValueChanged<Color> onColorChanged;

  @override
  State<VisualisationCard> createState() => _VisualisationCardState();
}

class _VisualisationCardState extends State<VisualisationCard> {
  // a simple palette of 10 colors (feel free to change)
  final List<Color> _colors = const [
    Color.fromARGB(255, 255, 243, 224), // Warmweiß (RGB 255,243,224) - #FFF3E0
    Color.fromARGB(255, 255, 255, 255), // Weiß (RGB 255,255,255) - #FFFFFF
    Color.fromARGB(255, 230, 190, 40), // gedämpftes Gelb (RGB 230,190,40)
    Color.fromARGB(255, 200, 110, 35), // gedämpftes Orange (RGB 200,110,35)
    Color.fromARGB(255, 180, 40, 40), // gedämpftes Rot (RGB 180,40,40)
    Color.fromARGB(255, 180, 70, 120), // gedämpftes Magenta (RGB 180,70,120)
    Color.fromARGB(255, 110, 70, 180), // gedämpftes Violett (RGB 110,70,180)
    Color.fromARGB(255, 60, 110, 180), // gedämpftes Blau (RGB 60,110,180)
    Color.fromARGB(255, 50, 150, 150), // gedämpftes Cyan/Teal (RGB 50,150,150)
    Color.fromARGB(255, 50, 150, 80), // gedämpftes Grün (RGB 50,150,80)
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
            // Title
            const Text(
              'Darstellung',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Content indented a bit to create a modern visual rhythm (title flush,
            // content slightly inset)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 2.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brightness section
                  const Text(
                    'Helligkeit',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Slider wrapped in a Row to show percentage on the right
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
                            // make the value indicator (the popup label when dragging)
                            // have a black background with white text instead of the
                            // default theme color (was purple-ish)
                            valueIndicatorColor: Colors.blueGrey,
                            valueIndicatorTextStyle: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          child: Slider(
                            min: 0,
                            max: 100,
                            value: widget.brightness,
                            divisions: 100,
                            label: '${widget.brightness.round()}%',
                            onChanged: (v) => widget.onBrightnessChanged(v),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 34,
                        child: Text(
                          '${widget.brightness.round()}%',
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

                  // subtle divider for a modern card sectioning
                  Divider(
                    height: 18,
                    thickness: 1,
                    color: Colors.grey.shade100,
                  ),
                  const SizedBox(height: 8),

                  // Color style section
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
                    height: 72,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _colors.length,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemBuilder: (context, i) {
                        final bool selected =
                            widget.color.value == _colors[i].value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => widget.onColorChanged(_colors[i]),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: _colors[i],
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      // always show a thin light grey border so the
                                      // swatches are visible on light backgrounds;
                                      // when selected, make it a bit stronger.
                                      color:
                                          selected
                                              ? Colors.black26
                                              : Colors.grey.shade200,
                                      width: selected ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                // checkmark overlay when selected
                                AnimatedOpacity(
                                  opacity: selected ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 180),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.45),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
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
