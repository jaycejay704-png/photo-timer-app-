name: photo-timer-app

# Flutter project scaffold for Photo Timer App with Grok integration

This repo contains a Flutter app that allows taking a photo and locking it behind a timer. It stores photos encrypted on the device and supports app-initiated Grok (xAI) API calls using an API key saved in secure storage.

## Features added in this commit (iOS-specific improvements)
- Proper AES-GCM encryption for stored photos using a randomly generated key stored in Keychain (flutter_secure_storage)
- Persistent lock state: locked_at, lock_duration and paused intervals persisted so timer survives app restarts
- Local notification scheduling at expiry (flutter_local_notifications)
- Background blur/cover when the app is backgrounded (obscures task switcher preview)
- Biometric gating (Face ID / Touch ID) before decrypting/viewing photo using local_auth
- Info.plist entries for camera & photo usage

## Setup
1. Install Flutter: https://flutter.dev/docs/get-started/install
2. Clone this repo and checkout branch GrokKH:
   git clone https://github.com/jaycejay704-png/photo-timer-app-.git
   cd photo-timer-app-
   git checkout GrokKH
3. Run:
   flutter pub get
4. iOS: open ios/Runner.xcworkspace in Xcode, set signing team, and run on a physical device (camera & biometrics require device).

## Notes
- Do NOT commit your Grok API key. Use the in-app Settings screen to store it in Keychain.
- AES-GCM encryption key is generated once per device and stored in flutter_secure_storage.
