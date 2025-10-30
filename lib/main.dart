import 'package:flutter/material.dart';
import 'cards/card_visualisation.dart' as visual;
import 'cards/card_connections.dart' as conn;
import 'cards/card_notification.dart' as notif;

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
  // Globale Parameter
  bool powerOn = true; // Uhr ein/aus
  bool newChanges = true; // Änderungen vorhanden
  int currentTime = 0;

  // Verbindungs-Parameter
  bool LoginSaved = false;
  String Ssid = "";
  String Password = "";
  int ConfigSaved = 0;

  // Visualisierungs-Parameter
  double brightness = 70;
  int selectedColor_RED = 255;
  int selectedColor_GREEN = 255;
  int selectedColor_BLUE = 255;
  // Notifiers to avoid frequent full-widget rebuilds during interactions
  ValueNotifier<double>? brightnessNotifier;
  ValueNotifier<Color>? colorNotifier;

  // Automatisierungs-Parameter
  int EnableNightMode = 0; //Automatisches Ein/Ausschalten
  int TimeDisplayOff = 0; //Zeit für Uhr aus
  int TimeDisplayOn = 0; //Zeit für Uhr ein

  // Wecker-Parameter
  int AlarmEnable = 0; //Wecker ein/aus
  int AlarmTime = 0; //Zeit zum Auslösen des Weckers

  // Timer-Parameter
  int TimerEnable = 0; //Timer ein/aus
  int TimerDuration = 0; //Timer Dauer in Minuten

  // Offline-Modus Parameter
  int OfflineMode = 0; //Offline Modus ein/aus
  int SelectedTime = 0; //Ausgewählte Zeit im Offline Modus

  // Benachrichtigungs-Parameter
  int NotificationEnable = 0; //Benachrichtigungen ein/aus
  int NewNotification = 0; //Neue Benachrichtigung

  @override
  void initState() {
    super.initState();
    _printVisualVars('init');
    // Initialize notifiers from the canonical state so the visual card can
    // update them directly without causing a full scaffold rebuild on every
    // user interaction (slider drag / swatch tap). The listeners update the
    // canonical ints stored here but intentionally do not call setState.
    brightnessNotifier = ValueNotifier<double>(brightness);
    brightnessNotifier!.addListener(_brightnessNotifierListener);

    colorNotifier = ValueNotifier<Color>(
      Color.fromARGB(
        255,
        selectedColor_RED,
        selectedColor_GREEN,
        selectedColor_BLUE,
      ),
    );
    colorNotifier!.addListener(_colorNotifierListener);
    // Precache preview image to avoid decoding jank during first display on mobile.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(
        const AssetImage('assets/images/wordclock_preview.png'),
        context,
      );
    });
  }

  void _brightnessNotifierListener() {
    final v = brightnessNotifier?.value ?? brightness;
    // update canonical value without triggering a full rebuild; the card
    // listens to the notifier and will update visually.
    brightness = v;
    _printVisualVars('brightness-notifier');
  }

  void _colorNotifierListener() {
    final c =
        colorNotifier?.value ??
        Color.fromARGB(
          255,
          selectedColor_RED,
          selectedColor_GREEN,
          selectedColor_BLUE,
        );
    selectedColor_RED = c.red;
    selectedColor_GREEN = c.green;
    selectedColor_BLUE = c.blue;
    _printVisualVars('color-notifier');
  }

  @override
  void dispose() {
    // remove our listeners and dispose the notifiers we created
    brightnessNotifier?.removeListener(_brightnessNotifierListener);
    colorNotifier?.removeListener(_colorNotifierListener);
    brightnessNotifier?.dispose();
    colorNotifier?.dispose();
    super.dispose();
  }

  void _printVisualVars([String when = '']) {
    debugPrint(
      'Visual params${when.isNotEmpty ? ' ($when)' : ''}: '
      'brightness=$brightness, color=($selectedColor_RED, $selectedColor_GREEN, $selectedColor_BLUE)',
    );
  }

  @override
  void setState(VoidCallback fn) {
    // weiterhin normales setState ausführen, danach die aktuellen Werte ausgeben
    super.setState(() {
      fn();
    });
    _printVisualVars('after setState');
  }

  Widget build(BuildContext context) {
    // decide wide layout early for AppBar buttons
    final bool wideAtAppBar = MediaQuery.of(context).size.width >= 800;

    const double appBarButtonHeight = 36.0;
    Widget labeledButton(
      IconData icon,
      String label,
      VoidCallback onPressed, {
      bool active = false,
    }) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color:
              icon == Icons.check
                  ? Colors.black
                  : (active ? Colors.red : Colors.green),
          size: 20,
        ),
        label: Text(label, style: const TextStyle(color: Colors.black87)),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, appBarButtonHeight),
          side: BorderSide(color: Colors.grey.shade300, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leadingWidth: wideAtAppBar ? 150 : 50,
        leading:
            wideAtAppBar
                ? Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Center(
                    child: SizedBox(
                      height: appBarButtonHeight,
                      child: labeledButton(Icons.check, 'Übernehmen', () {
                        // apply / send settings (placeholder)
                        Navigator.maybePop(context);
                      }),
                    ),
                  ),
                )
                : (newChanges
                    ? IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.check,
                        size: 25.0,
                        color: Colors.black,
                      ),
                      onPressed: () => Navigator.maybePop(context),
                    )
                    : null),
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
        actions:
            wideAtAppBar
                ? [
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Center(
                      child: SizedBox(
                        height: appBarButtonHeight,
                        child: labeledButton(
                          powerOn
                              ? Icons.power_settings_new
                              : Icons.power_settings_new,
                          powerOn ? 'Ausschalten' : 'Einschalten',
                          () => setState(() => powerOn = !powerOn),
                          active: powerOn,
                        ),
                      ),
                    ),
                  ),
                ]
                : [
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
                          color: powerOn ? Colors.red : Colors.green,
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

            // horizontal gutter inside each column (left/right)
            const double columnHorizontalPadding = 12.0;
            // total width reserved for the divider area between columns. Make this
            // smaller so the visible line isn't far away from the content.
            const double verticalDividerWidth = 12.0;

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
                  // only add horizontal padding for the narrow layout
                  padding: EdgeInsets.symmetric(
                    horizontal: cardWidth == null ? columnHorizontalPadding : 0,
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
                            child: visual.VisualisationCard(
                              brightness: brightness,
                              brightnessNotifier: brightnessNotifier,
                              colorNotifier: colorNotifier,
                              onBrightnessChanged:
                                  (v) => setState(() => brightness = v),
                              color: Color.fromARGB(
                                255,
                                selectedColor_RED,
                                selectedColor_GREEN,
                                selectedColor_BLUE,
                              ),
                              onColorChanged:
                                  (c) => setState(() {
                                    selectedColor_RED = c.red;
                                    selectedColor_GREEN = c.green;
                                    selectedColor_BLUE = c.blue;
                                  }),
                            ),
                          ),
                        ),
                      if (cardWidth == null)
                        visual.VisualisationCard(
                          brightness: brightness,
                          brightnessNotifier: brightnessNotifier,
                          colorNotifier: colorNotifier,
                          onBrightnessChanged:
                              (v) => setState(() => brightness = v),
                          color: Color.fromARGB(
                            255,
                            selectedColor_RED,
                            selectedColor_GREEN,
                            selectedColor_BLUE,
                          ),
                          onColorChanged:
                              (c) => setState(() {
                                selectedColor_RED = c.red;
                                selectedColor_GREEN = c.green;
                                selectedColor_BLUE = c.blue;
                              }),
                        ),
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
                            child: notif.NotificationCard(
                              notificationEnable: NotificationEnable,
                              onNotificationChanged:
                                  (v) => setState(() => NotificationEnable = v),
                            ),
                          ),
                        ),
                      if (cardWidth == null)
                        notif.NotificationCard(
                          notificationEnable: NotificationEnable,
                          onNotificationChanged:
                              (v) => setState(() => NotificationEnable = v),
                        ),
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
              // wide layout: compute per-column available width. Each column will
              // contain: [gutter | content | gutter] so that the distance from the
              // content edges to both the window edges and the divider equals
              // `columnHorizontalPadding`.
              final double columnAvailable =
                  (constraints.maxWidth - verticalDividerWidth) / 2;

              // content width inside a column after reserving left/right gutter
              final double contentWidth = (columnAvailable -
                      (2 * columnHorizontalPadding))
                  .clamp(0.0, double.infinity);

              // Side wird mit dynamischen min/max geclamped (unterscheidet mobile/pc)
              final double side = contentWidth.clamp(
                imageMinSide,
                imageMaxSide,
              );

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // linker Bereich: feste Breite = columnAvailable
                  SizedBox(
                    width: columnAvailable,
                    child: SizedBox(
                      height: constraints.maxHeight,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: columnHorizontalPadding,
                          ),
                          child: imageBox(side),
                        ),
                      ),
                    ),
                  ),

                  // vertikaler Trenner mit symmetrischem Abstand
                  const VerticalDivider(
                    width: verticalDividerWidth,
                    thickness: 1,
                    indent: 12,
                    endIndent: 12,
                    color: Color(0xFFE9EEF3),
                  ),

                  // rechter Bereich: feste Breite = columnAvailable -> Cards mit contentWidth
                  SizedBox(
                    width: columnAvailable,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: columnHorizontalPadding,
                      ),
                      child: leftColumn(cardWidth: side),
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

  // Build the connections card using this state's canonical fields so the
  // callbacks can directly update `Ssid`, `Password` and `LoginSaved`.
  Widget card_connections() {
    return conn.EspWifiCard(
      loginSaved: LoginSaved,
      ssid: Ssid,
      password: Password,
      onConnect:
          (ssid, password) => setState(() {
            Ssid = ssid;
            Password = password;
            LoginSaved = true;
          }),
      onDisconnect:
          () => setState(() {
            LoginSaved = false;
            Ssid = '';
            Password = '';
          }),
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

Widget card_automation() => cardBase('Automation');
Widget card_alarm() => cardBase('Alarm');
Widget card_timer() => cardBase('Timer');
Widget card_offline_mode() => cardBase('Offline Mode');
