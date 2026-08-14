name: photo-timer-app

# Flutter project scaffold for Photo Timer App with Grok integration

This repo contains a Flutter app that allows taking a photo and locking it behind a timer. It stores photos encrypted on the device and supports app-initiated Grok (xAI) API calls using an API key saved in secure storage.

## Features
- Take photo with camera
- Save photos encrypted on device
- Lock photo behind a countdown timer
- Increase or freeze the timer
- Settings screen to store Grok API key securely
- FLAG_SECURE on Android to prevent screenshots/recents preview

## Setup
1. Install Flutter: https://flutter.dev/docs/get-started/install
2. Clone this repo
3. Run `flutter pub get`
4. Connect a device or emulator and run `flutter run`

## Notes about Grok API key
- Do not put your API key in source control. Use the in-app Settings screen to paste it after launching the app.
