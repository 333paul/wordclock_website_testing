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

  // no-op: we previously considered exposing whether external controllers
  // are used; removed unused getter to avoid lint warnings.

  @override
  void initState() {
    super.initState();
    // If external controllers are provided use them; otherwise create local ones
    _localSsidController = widget.ssidController ?? TextEditingController();
    _localPasswordController =
        widget.passwordController ?? TextEditingController();
    // seed controllers with canonical values so the fields show current state
    if ((widget.ssidController == null) && widget.ssid.isNotEmpty) {
      _localSsidController.text = widget.ssid;
    }
    if ((widget.passwordController == null) && widget.password.isNotEmpty) {
      _localPasswordController.text = widget.password;
    }
  }

  @override
  void dispose() {
    // Only dispose local controllers (not ones passed in)
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
    final pw = _localPasswordController.text;
    if (ssid.isNotEmpty) {
      widget.onConnect(ssid, pw);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ssidController = widget.ssidController ?? _localSsidController;
    final passwordController =
        widget.passwordController ?? _localPasswordController;

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
              'Verbindungen',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Wenn verbunden: nur Statuszeile + Trennen zeigen
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
                  // 'Trennen' Button rechtsbündig im Timer-Start-Stil
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
              const Text('Nicht verbunden'),

              const Divider(height: 20, thickness: 1),

              // Einfaches Formular: SSID + Passwort untereinander
              TextField(
                controller: ssidController,
                decoration: const InputDecoration(
                  labelText: 'SSID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Passwort',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _localConnect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Verbinden'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      ssidController.clear();
                      passwordController.clear();
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(88, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Löschen'),
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
