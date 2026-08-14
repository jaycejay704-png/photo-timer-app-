```dart
// lib/services/biometric_service.dart
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final _auth = LocalAuthentication();

  static Future<bool> authenticate(String reason) async {
    try {
      final can = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (!can) return false;
      return await _auth.authenticate(localizedReason: reason, options: const AuthenticationOptions(biometricOnly: true));
    } catch (e) {
      return false;
    }
  }
}
```
