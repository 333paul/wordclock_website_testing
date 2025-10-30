import 'package:flutter/material.dart';

class EspWifiCard extends StatefulWidget {
  final bool loginSaved;
  final String ssid;
  final String password;
  final Function(String ssid, String password) onConnect;
  final Function() onDisconnect;

  const EspWifiCard({
    Key? key,
    required this.loginSaved,
    required this.ssid,
    required this.password,
    required this.onConnect,
    required this.onDisconnect,
  }) : super(key: key);

  @override
  State<EspWifiCard> createState() => _EspWifiCardState();
}

class _EspWifiCardState extends State<EspWifiCard> {
  List<String> availableNetworks = [];
  String selectedSsid = '';
  String enteredPassword = '';

  @override
  void initState() {
    super.initState();
    selectedSsid = widget.ssid;
    enteredPassword = widget.password;
    _loadAvailableNetworks();
  }

  void _loadAvailableNetworks() {
    // TODO: Ersetze das durch echten ESP-WLAN Scan
    setState(() {
      availableNetworks = ['ESP_WLAN_1', 'ESP_WLAN_2', 'ESP_WLAN_3'];
    });
  }

  void _connect() {
    if (selectedSsid.isNotEmpty && enteredPassword.isNotEmpty) {
      widget.onConnect(selectedSsid, enteredPassword);
    }
  }

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
          children: [
            const Text(
              'ESP WLAN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Aktuelles WLAN
            if (widget.loginSaved && widget.ssid.isNotEmpty) ...[
              Text('Verbunden mit: ${widget.ssid}'),
              const SizedBox(height: 6),
              TextButton(
                onPressed: widget.onDisconnect,
                child: const Text('Trennen'),
              ),
            ] else
              const Text('Nicht verbunden'),

            const Divider(height: 20, thickness: 1),

            // Verfügbare Netzwerke
            const Text(
              'Verfügbare Netzwerke',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...availableNetworks.map(
              (network) => ListTile(
                title: Text(network),
                trailing:
                    selectedSsid == network
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                onTap: () {
                  setState(() {
                    selectedSsid = network;
                  });
                },
              ),
            ),

            const SizedBox(height: 8),

            // Passwort Eingabe
            if (selectedSsid.isNotEmpty) ...[
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Passwort',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => enteredPassword = v,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _connect,
                child: const Text('Verbinden'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
