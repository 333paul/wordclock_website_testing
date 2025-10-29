import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WORDCLOCK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const HomeScaffold(),
    );
  }
}

class HomeScaffold extends StatefulWidget {
  const HomeScaffold({super.key});

  @override
  State<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<HomeScaffold> {
  bool powerOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leadingWidth: 50,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.check, size: 25.0, color: Colors.black),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'WORDCLOCK',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 20.0,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          SizedBox(
            width: 50,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => setState(() => powerOn = !powerOn),
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder:
                    (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                child: Icon(
                  Icons.power_settings_new,
                  key: ValueKey<bool>(powerOn),
                  color: powerOn ? Colors.green : Colors.red,
                  size: 25.0,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // breakpoint für single / two column
            final bool wide = constraints.maxWidth >= 800;

            // --- dynamische min/max Größen abhängig von Device/Treiber --
            // Beispielwerte: für mobile eher kleiner, für PC größer
            final double imageMinSide = wide ? 200.0 : 120.0;
            final double imageMaxSide = wide ? 420.0 : 360.0;

            const double columnHorizontalPadding = 16.0;
            const double verticalDividerWidth = 32.0;

            // Bild-Widget (verwendet die berechnete side)
            Widget imageBox(double side) {
              return Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: side,
                    height: side,
                    child: Image.asset(
                      'assets/images/wordclock_preview.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            }

            // linke Spalte: optional cardWidth übergeben (bei wide layout)
            Widget leftColumn({double? cardWidth}) {
              return SingleChildScrollView(
                padding: const EdgeInsets.only(top: 10, bottom: 24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: columnHorizontalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!wide)
                        LayoutBuilder(
                          builder: (ctx, c) {
                            final double side = c.maxWidth.clamp(
                              imageMinSide,
                              imageMaxSide,
                            );
                            return imageBox(side);
                          },
                        ),
                      if (!wide) const SizedBox(height: 12),
                      const SizedBox(height: 8),
                      // Beim Vorhandensein von cardWidth: Cards zentrieren und auf diese Breite beschränken
                      if (cardWidth != null)
                        Center(
                          child: SizedBox(
                            width: cardWidth,
                            child: card_connections(),
                          ),
                        ),
                      if (cardWidth == null) card_connections(),
                      const SizedBox(height: 12),
                      if (cardWidth != null)
                        Center(
                          child: SizedBox(
                            width: cardWidth,
                            child: card_visualisation(),
                          ),
                        ),
                      if (cardWidth == null) card_visualisation(),
                      const SizedBox(height: 12),
                      if (cardWidth != null)
                        Center(
                          child: SizedBox(
                            width: cardWidth,
                            child: card_automation(),
                          ),
                        ),
                      if (cardWidth == null) card_automation(),
                      const SizedBox(height: 12),
                      if (cardWidth != null)
                        Center(
                          child: SizedBox(
                            width: cardWidth,
                            child: card_alarm(),
                          ),
                        ),
                      if (cardWidth == null) card_alarm(),
                      const SizedBox(height: 12),
                      if (cardWidth != null)
                        Center(
                          child: SizedBox(
                            width: cardWidth,
                            child: card_timer(),
                          ),
                        ),
                      if (cardWidth == null) card_timer(),
                      const SizedBox(height: 12),
                      if (cardWidth != null)
                        Center(
                          child: SizedBox(
                            width: cardWidth,
                            child: card_offline_mode(),
                          ),
                        ),
                      if (cardWidth == null) card_offline_mode(),
                      const SizedBox(height: 12),
                      if (cardWidth != null)
                        Center(
                          child: SizedBox(
                            width: cardWidth,
                            child: card_notification(),
                          ),
                        ),
                      if (cardWidth == null) card_notification(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              );
            }

            if (!wide) {
              // mobile / narrow layout: single column
              return leftColumn();
            } else {
              // wide layout: compute per-column available width and clamp to image min/max
              final double columnAvailable =
                  (constraints.maxWidth - verticalDividerWidth) / 2;
              // inner available inside padding (left/right padding)
              final double innerAvailable = (columnAvailable -
                      (2 * columnHorizontalPadding))
                  .clamp(0.0, double.infinity);

              // Side wird mit dynamischen min/max geclamped (unterscheidet mobile/pc)
              final double side = innerAvailable.clamp(
                imageMinSide,
                imageMaxSide,
              );

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // linker Bereich: Cards (gleich breit wie rechter Bereich) -> übergebe cardWidth = side
                  Expanded(child: leftColumn(cardWidth: side)),

                  // vertikaler Trenner mit symmetrischem Abstand
                  const VerticalDivider(
                    width: verticalDividerWidth,
                    thickness: 1,
                    indent: 12,
                    endIndent: 12,
                    color: Color(0xFFE9EEF3),
                  ),

                  // rechter Bereich: Bild mit derselben side
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 10, bottom: 24),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: columnHorizontalPadding,
                        ),
                        child: Column(
                          children: [const SizedBox(height: 8), imageBox(side)],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}

// --- Cards: keine horizontalen Margins mehr, Spalten-Padding sorgt für Abstand ---

Widget cardBase(String title) {
  return Card(
    color: Colors.white,
    elevation: 1,
    shape: RoundedRectangleBorder(
      side: BorderSide(color: Colors.grey.shade200, width: 1),
      borderRadius: BorderRadius.circular(14),
    ),
    child: SizedBox(
      height: 140,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    ),
  );
}

Widget card_connections() => cardBase('Connections');
Widget card_visualisation() => cardBase('Visualisation');
Widget card_automation() => cardBase('Automation');
Widget card_alarm() => cardBase('Alarm');
Widget card_timer() => cardBase('Timer');
Widget card_offline_mode() => cardBase('Offline Mode');
Widget card_notification() => cardBase('Notification');
