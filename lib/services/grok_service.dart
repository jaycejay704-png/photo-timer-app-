```dart
// lib/services/grok_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GrokService {
  static final _secure = FlutterSecureStorage();

  static Future<String?> _getKey() async {
    return await _secure.read(key: 'grok_api_key');
  }

  // Example: send a prompt to Grok and return text response
  static Future<String?> askGrok(String prompt) async {
    final key = await _getKey();
    if (key == null || key.isEmpty) return null;
    final url = Uri.parse('https://api.grok.example/v1/ask'); // placeholder
    final res = await http.post(url, headers: {
      'Authorization': 'Bearer $key',
      'Content-Type': 'application/json'
    }, body: jsonEncode({'prompt': prompt}));
    if (res.statusCode == 200) {
      final j = jsonDecode(res.body);
      return j['answer'] as String?;
    }
    return null;
  }
}
```
