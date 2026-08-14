```dart
// lib/services/timer_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'storage_service.dart';

class TimerService extends ChangeNotifier {
  int remainingSeconds = 0;
  bool isFrozen = false;
  Timer? _uiTimer;
  final FlutterLocalNotificationsPlugin _notifs = FlutterLocalNotificationsPlugin();

  TimerService() {
    _initNotifications();
    _recomputeRemaining();
    _startUiTimer();
  }

  void _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();
    await _notifs.initialize(const InitializationSettings(android: android, iOS: iOS));
  }

  void _startUiTimer() {
    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isFrozen) {
        _recomputeRemaining();
        notifyListeners();
      }
    });
  }

  void _recomputeRemaining() {
    final lockedAt = StorageService.lockedAt?.toUtc();
    if (lockedAt == null) {
      remainingSeconds = 0;
      return;
    }
    final duration = Duration(seconds: StorageService.lockDurationSeconds);
    // compute paused total from storage
    final paused = StorageService._box.get('paused_intervals') as List<dynamic>;
    Duration pausedTotal = Duration.zero;
    for (final p in paused) {
      final map = Map<String, dynamic>.from(p);
      final s = DateTime.parse(map['start']).toUtc();
      final eStr = map['end'];
      final e = eStr == null ? DateTime.now().toUtc() : DateTime.parse(eStr).toUtc();
      pausedTotal += e.difference(s);
    }
    final expiry = lockedAt.add(duration).add(pausedTotal);
    final now = DateTime.now().toUtc();
    remainingSeconds = now.isBefore(expiry) ? expiry.difference(now).inSeconds : 0;
  }

  bool get isLocked => remainingSeconds > 0;

  void startLock(int seconds) {
    // called when saving photo
    StorageService._box.put('locked_at', DateTime.now().toUtc().toIso8601String());
    StorageService._box.put('lock_duration', seconds);
    StorageService._box.put('paused_intervals', <Map>[]);
    _scheduleExpiryNotification(seconds);
    _recomputeRemaining();
    _startUiTimer();
    notifyListeners();
  }

  void increase(int seconds) {
    StorageService.increaseLockDuration(seconds);
    _recomputeRemaining();
    _scheduleExpiryNotification(remainingSeconds + seconds);
    notifyListeners();
  }

  void toggleFreeze() {
    isFrozen = !isFrozen;
    if (isFrozen) {
      StorageService.addPauseIntervalStart();
    } else {
      StorageService.endPauseInterval();
    }
    _recomputeRemaining();
    notifyListeners();
  }

  Future<void> _scheduleExpiryNotification(int secondsFromNow) async {
    final when = DateTime.now().add(Duration(seconds: secondsFromNow));
    const androidDetails = AndroidNotificationDetails('expiry', 'Expiry', 'Photo unlock notification', importance: Importance.max, priority: Priority.high);
    const iosDetails = DarwinNotificationDetails();
    await _notifs.zonedSchedule(
      0,
      'Photo unlocked',
      'Your locked photo is now available',
      tz.TZDateTime.from(when, tz.local),
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }
}
```
