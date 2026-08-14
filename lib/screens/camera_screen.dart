```dart
// lib/screens/camera_screen.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../services/storage_service.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;
  List<CameraDescription>? cameras;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      controller = CameraController(cameras![0], ResolutionPreset.medium);
      await controller!.initialize();
      setState(() {});
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> takePicture() async {
    if (controller == null || !controller!.value.isInitialized) return;
    final XFile file = await controller!.takePicture();
    final bytes = await File(file.path).readAsBytes();
    // Save encrypted
    await StorageService.saveEncryptedPhoto(bytes);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Photo saved and locked')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) return Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: Text('Take Photo')),
      body: CameraPreview(controller!),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        onPressed: takePicture,
      ),
    );
  }
}
```
