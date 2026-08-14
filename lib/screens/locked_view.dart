```dart
// lib/screens/locked_view.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import '../services/storage_service.dart';
import '../services/timer_service.dart';
import '../services/biometric_service.dart';

class LockedView extends StatefulWidget {
  @override
  _LockedViewState createState() => _LockedViewState();
}

class _LockedViewState extends State<LockedView> with WidgetsBindingObserver {
  final TimerService timerService = TimerService();
  bool _cover = false;
  String? status = 'No photo locked';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    secureScreen();
    loadStatus();
    timerService.addListener(onTimerUpdate);
  }

  Future<void> secureScreen() async {
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }

  void onTimerUpdate() async {
    setState(() {});
  }

  Future<void> loadStatus() async {
    final has = await StorageService.hasLockedPhoto();
    if (has) {
      setState(() {
        status = 'Photo locked';
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // show cover when app is backgrounded to obscure preview
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      setState(() => _cover = true);
    } else if (state == AppLifecycleState.resumed) {
      setState(() => _cover = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timerService.removeListener(onTimerUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: Text('Locked Photo')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(status ?? ''),
                SizedBox(height: 20),
                if (timerService.isLocked)
                  Text('Time left: ${timerService.remainingSeconds}s'),
                SizedBox(height: 20),
                ElevatedButton(
                  child: Text('Increase Timer (+30s)'),
                  onPressed: () => timerService.increase(30),
                ),
                ElevatedButton(
                  child: Text(timerService.isFrozen ? 'Unfreeze' : 'Freeze'),
                  onPressed: () => timerService.toggleFreeze(),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  child: Text('Show Photo (if unlocked)'),
                  onPressed: () async {
                    if (timerService.isLocked) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Photo still locked')));
                      return;
                    }
                    // Biometric auth before decrypt
                    final ok = await BiometricService.authenticate('Authenticate to view photo');
                    if (!ok) return;
                    final bytes = await StorageService.tryGetDecryptedPhotoIfUnlocked(requireUnlocked: false);
                    if (bytes != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: Text('Photo')), body: Center(child: Image.memory(bytes)))));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No photo available')));
                    }
                  },
                )
              ],
            ),
          ),
        ),
        if (_cover)
          Positioned.fill(
            child: Container(
              color: Colors.white,
              child: Center(child: Text('App is backgrounded', style: TextStyle(fontSize: 18))),
            ),
          ),
      ],
    );
  }
}
```
