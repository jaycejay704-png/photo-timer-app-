```dart
// lib/services/storage_service.dart
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class StorageService {
  static const _boxName = 'photos';
  static final _secure = FlutterSecureStorage();
  static late Box _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    // Ensure encryption key exists
    String? k = await _secure.read(key: 'enc_key');
    if (k == null) {
      final gen = base64UrlEncode(utf8.encode(DateTime.now().toIso8601String()));
      await _secure.write(key: 'enc_key', value: gen);
    }
  }

  static Future<void> saveEncryptedPhoto(Uint8List bytes) async {
    final key = await _secure.read(key: 'enc_key');
    final hashed = sha256.convert(utf8.encode(key ?? '')).bytes;
    // Simple XOR encrypt for demo (replace with real AES in production)
    final enc = List<int>.generate(bytes.length, (i) => bytes[i] ^ hashed[i % hashed.length]);
    await _box.put('photo', enc);
    await _box.put('locked_at', DateTime.now().toIso8601String());
    await _box.put('lock_duration', 60); // default 60s
  }

  static Future<bool> hasLockedPhoto() async {
    return _box.containsKey('photo');
  }

  static Future<Uint8List?> tryGetDecryptedPhotoIfUnlocked(dynamic timerService) async {
    if (!_box.containsKey('photo')) return null;
    final lockedAt = DateTime.parse(_box.get('locked_at'));
    final duration = Duration(seconds: _box.get('lock_duration'));
    if (DateTime.now().isBefore(lockedAt.add(duration))) return null;
    final enc = List<int>.from(_box.get('photo'));
    final key = await _secure.read(key: 'enc_key');
    final hashed = sha256.convert(utf8.encode(key ?? '')).bytes;
    final dec = List<int>.generate(enc.length, (i) => enc[i] ^ hashed[i % hashed.length]);
    return Uint8List.fromList(dec);
  }
}
```
