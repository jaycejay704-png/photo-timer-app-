```dart
// lib/services/storage_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cryptography/cryptography.dart';

class StorageService {
  static const _boxName = 'photos';
  static final _secure = FlutterSecureStorage();
  static late Box _box;
  static final _aes = AesGcm.with256bits();

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    // Ensure encryption key exists
    String? k = await _secure.read(key: 'enc_key');
    if (k == null) {
      final keyBytes = _secureRandomBytes(32);
      await _secure.write(key: 'enc_key', value: base64Encode(keyBytes));
    }
  }

  static Uint8List _secureRandomBytes(int len) {
    final rnd = Random.secure();
    return Uint8List.fromList(List<int>.generate(len, (_) => rnd.nextInt(256)));
  }

  static Future<SecretKey> _getSecretKey() async {
    final k = await _secure.read(key: 'enc_key');
    if (k == null) throw Exception('Encryption key missing');
    final bytes = base64Decode(k);
    return SecretKey(bytes);
  }

  // Save encrypted photo using AES-GCM and persist locking metadata
  static Future<void> saveEncryptedPhoto(Uint8List bytes, {int lockDurationSeconds = 60}) async {
    final secretKey = await _getSecretKey();
    final nonce = _secureRandomBytes(12); // recommended nonce length for AES-GCM
    final secretBox = await _aes.encrypt(bytes, secretKey: secretKey, nonce: nonce);

    // Store base64 parts
    final entry = {
      'nonce': base64Encode(secretBox.nonce),
      'cipherText': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };
    await _box.put('photo', entry);
    await _box.put('locked_at', DateTime.now().toIso8601String());
    await _box.put('lock_duration', lockDurationSeconds);
    await _box.put('paused_intervals', <Map>[]); // list of {start, end} ISO strings
  }

  static Future<bool> hasLockedPhoto() async {
    return _box.containsKey('photo');
  }

  // Decrypt only when unlocked (caller should ensure authentication if needed)
  static Future<Uint8List?> tryGetDecryptedPhotoIfUnlocked({bool requireUnlocked = true}) async {
    if (!_box.containsKey('photo')) return null;
    final lockedAtStr = _box.get('locked_at') as String;
    final lockedAt = DateTime.parse(lockedAtStr).toUtc();
    final lockDuration = Duration(seconds: (_box.get('lock_duration') as int));

    // compute paused total
    final paused = _box.get('paused_intervals') as List<dynamic>;
    Duration pausedTotal = Duration.zero;
    for (final p in paused) {
      final map = Map<String, dynamic>.from(p);
      final s = DateTime.parse(map['start']).toUtc();
      final eStr = map['end'];
      final e = eStr == null ? DateTime.now().toUtc() : DateTime.parse(eStr).toUtc();
      pausedTotal += e.difference(s);
    }

    final expiry = lockedAt.add(lockDuration).add(pausedTotal);
    final now = DateTime.now().toUtc();
    if (requireUnlocked && now.isBefore(expiry)) return null;

    final entry = Map<String, dynamic>.from(_box.get('photo'));
    final nonce = base64Decode(entry['nonce'] as String);
    final cipherText = base64Decode(entry['cipherText'] as String);
    final mac = base64Decode(entry['mac'] as String);
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(mac));

    final secretKey = await _getSecretKey();
    final clear = await _aes.decrypt(secretBox, secretKey: secretKey);
    return Uint8List.fromList(clear);
  }

  // Timer related helpers
  static DateTime? get lockedAt => _box.get('locked_at') != null ? DateTime.parse(_box.get('locked_at')) : null;
  static int get lockDurationSeconds => _box.get('lock_duration') ?? 0;

  static void addPauseIntervalStart() {
    final list = List<Map<String, dynamic>>.from(_box.get('paused_intervals') as List<dynamic>);
    list.add({'start': DateTime.now().toUtc().toIso8601String(), 'end': null});
    _box.put('paused_intervals', list);
  }

  static void endPauseInterval() {
    final list = List<Map<String, dynamic>>.from(_box.get('paused_intervals') as List<dynamic>);
    if (list.isNotEmpty) {
      final last = list.last;
      if (last['end'] == null) {
        last['end'] = DateTime.now().toUtc().toIso8601String();
        _box.put('paused_intervals', list);
      }
    }
  }

  static void increaseLockDuration(int seconds) {
    final cur = _box.get('lock_duration') as int? ?? 0;
    _box.put('lock_duration', cur + seconds);
  }
}
```
