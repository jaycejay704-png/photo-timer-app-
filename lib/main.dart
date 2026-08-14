```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/camera_screen.dart';
import 'screens/locked_view.dart';
import 'screens/settings_screen.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Timer',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Photo Timer')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text('Take Photo'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CameraScreen())),
            ),
            ElevatedButton(
              child: Text('Locked View'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LockedView())),
            ),
            ElevatedButton(
              child: Text('Settings'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen())),
            ),
          ],
        ),
      ),
    );
  }
}
```
