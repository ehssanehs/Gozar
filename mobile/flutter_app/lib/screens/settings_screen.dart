import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _routingController = TextEditingController(text: '''
// Example routing rules (JSON or DSL as you prefer)
// TODO: Store and apply to Xray config
''');

  bool _idleDisconnect = true;
  bool _lowPowerMode = true;

  @override
  void dispose() {
    _routingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Routing Rules', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _routingController,
            maxLines: 10,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter routing rules (JSON)',
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Idle disconnect'),
            subtitle: const Text('Disconnect when idle to save battery'),
            value: _idleDisconnect,
            onChanged: (v) => setState(() => _idleDisconnect = v),
          ),
          SwitchListTile(
            title: const Text('Low power mode'),
            subtitle: const Text('Reduce keepalives and logging'),
            value: _lowPowerMode,
            onChanged: (v) => setState(() => _lowPowerMode = v),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
