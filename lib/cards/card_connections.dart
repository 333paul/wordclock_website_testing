import 'package:flutter/material.dart';

class EspWifiCard extends StatefulWidget {
  final int loginSaved;
  final String ssid;
  final String password;
  final Function(String ssid, String password) onConnect;
  final Function() onDisconnect;
  final TextEditingController? ssidController;
  final TextEditingController? passwordController;

  const EspWifiCard({
    Key? key,
    required this.loginSaved,
    required this.ssid,
    required this.password,
    required this.onConnect,
    required this.onDisconnect,
    this.ssidController,
    this.passwordController,
  }) : super(key: key);

  @override
  State<EspWifiCard> createState() => _EspWifiCardState();
}

class _EspWifiCardState extends State<EspWifiCard> {
  late final TextEditingController _localSsidController;
  late final TextEditingController _localPasswordController;

  @override
  void initState() {
    super.initState();
    _localSsidController = widget.ssidController ?? TextEditingController();
    _localPasswordController =
        widget.passwordController ?? TextEditingController();

    if ((widget.ssidController == null) && widget.ssid.isNotEmpty) {
      _localSsidController.text = widget.ssid;
    }
    if ((widget.passwordController == null) && widget.password.isNotEmpty) {
      _localPasswordController.text = widget.password;
    }

    // Listener um UI neu zu zeichnen, wenn sich Textfelder ändern
    _localSsidController.addListener(() => setState(() {}));
    _localPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    if (widget.ssidController == null) {
      _localSsidController.dispose();
    }
    if (widget.passwordController == null) {
      _localPasswordController.dispose();
    }
    super.dispose();
  }

  void _localConnect() {
    final ssid = _localSsidController.text.trim();
    final password = _localPasswordController.text;
    if (ssid.isEmpty) return;
    if (ssid.toLowerCase() != 'esp' && password.isEmpty) return;
    widget.onConnect(ssid, password);
  }

  @override
  Widget build(BuildContext context) {
    final ssidController = widget.ssidController ?? _localSsidController;
    final passwordController =
        widget.passwordController ?? _localPasswordController;

    final ssidText = ssidController.text.trim();
    final passwordText = passwordController.text;

    // Button-Aktivität prüfen
    final canConnect =
        ssidText.isNotEmpty &&
        (ssidText.toLowerCase() == 'esp' || passwordText.isNotEmpty);
    final canDelete = ssidText.isNotEmpty || passwordText.isNotEmpty;

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
              'Verbindung',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            if ((widget.loginSaved == 1) && widget.ssid.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Verbunden mit: ${widget.ssid}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: widget.onDisconnect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(88, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Trennen'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ] else ...[
              const Text(
                'SSID "ESP" für Betrieb im Access-Point-Modus.',
                style: TextStyle(color: Colors.black54),
              ),
              const Divider(height: 20, thickness: 1),
              TextField(
                controller: ssidController,
                decoration: InputDecoration(
                  labelText: 'SSID',
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueGrey),
                  ),
                  floatingLabelStyle: const TextStyle(color: Colors.blueGrey),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Passwort',
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueGrey),
                  ),
                  floatingLabelStyle: const TextStyle(color: Colors.blueGrey),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: canConnect ? _localConnect : null,
                        style: ButtonStyle(
                          animationDuration: Duration.zero,
                          backgroundColor:
                              MaterialStateProperty.resolveWith<Color?>((
                                states,
                              ) {
                                if (states.contains(MaterialState.disabled)) {
                                  return Colors.grey[300];
                                }
                                return Colors.blueGrey;
                              }),
                          foregroundColor:
                              MaterialStateProperty.resolveWith<Color?>((
                                states,
                              ) {
                                if (states.contains(MaterialState.disabled)) {
                                  return Colors.grey[600];
                                }
                                return Colors.white;
                              }),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        child: const Text('Verbinden'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        onPressed:
                            canDelete
                                ? () {
                                  ssidController.clear();
                                  passwordController.clear();
                                }
                                : null,
                        style: ButtonStyle(
                          animationDuration: Duration.zero,
                          backgroundColor:
                              MaterialStateProperty.resolveWith<Color?>((s) {
                                if (s.contains(MaterialState.disabled)) {
                                  return Colors.grey[100];
                                }
                                return null;
                              }),
                          foregroundColor:
                              MaterialStateProperty.resolveWith<Color?>((s) {
                                if (s.contains(MaterialState.disabled)) {
                                  return Colors.grey[500];
                                }
                                return Colors.black87;
                              }),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        child: const Text('Löschen'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
