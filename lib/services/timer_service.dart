```dart
// lib/services/timer_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

class TimerService extends ChangeNotifier {
  int remainingSeconds = 0;
  bool isFrozen = false;
  Timer? _timer;

  bool get isLocked => remainingSeconds > 0;

  TimerService() {
    // For demo, we don't persist timer — in production persist start time & duration
    remainingSeconds = 0;
  }

  void start(int seconds) {
    remainingSeconds = seconds;
    _startTick();
    notifyListeners();
  }

  void _startTick() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (!isFrozen && remainingSeconds > 0) {
        remainingSeconds -= 1;
        if (remainingSeconds <= 0) _timer?.cancel();
        notifyListeners();
      }
    });
  }

  void increase(int seconds) {
    remainingSeconds += seconds;
    if (_timer == null || !_timer!.isActive) _startTick();
    notifyListeners();
  }

  void toggleFreeze() {
    isFrozen = !isFrozen;
    notifyListeners();
  }

  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
```
