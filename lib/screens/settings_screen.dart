```dart
// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final storage = FlutterSecureStorage();
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadKey();
  }

  Future<void> loadKey() async {
    final k = await storage.read(key: 'grok_api_key');
    controller.text = k ?? '';
  }

  Future<void> saveKey() async {
    await storage.write(key: 'grok_api_key', value: controller.text);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('API key saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(labelText: 'Grok API Key'),
            ),
            SizedBox(height: 12),
            ElevatedButton(onPressed: saveKey, child: Text('Save'))
          ],
        ),
      ),
    );
  }
}
```
