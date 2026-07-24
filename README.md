# ESP32-S3 LED Controller App

Flutter app to remotely control a WS2812 RGB LED on an ESP32-S3, via Firebase Realtime Database. Companion to the [ESP32-S3-RGB-LED-Controller](https://github.com/DadoDz/ESP32-S3-RGB-LED-Controller) firmware.

```
Flutter app  <--->  Firebase Realtime Database  <--->  ESP32-S3
(phone/desktop)            (/led node)              (WS2812 LED)
```

The app writes power/color/brightness to `/led` in Firebase over plain HTTPS REST calls (not the `firebase_database` plugin, which has no desktop implementation) and listens to a Server-Sent-Events stream for realtime updates from the board or other clients.

## Features

- 🎨 Full RGB color picker + brightness slider
- 🔌 Power on/off toggle
- 🎲 Random color button
- ⚡ Realtime sync — reflects changes from the board or other clients within seconds
- 📱 Runs on Android, iOS, and desktop (Windows/Linux/macOS)

## Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) (stable channel)
- A Firebase project with the Realtime Database enabled — see the [firmware repo's README](https://github.com/DadoDz/ESP32-S3-RGB-LED-Controller) for setup, since the app and board share the same `/led` node

## Setup

1. Clone the repo and get packages:
   ```bash
   flutter pub get
   ```
2. Point the app at your own Firebase Realtime Database. `LedService` takes the database URL as a constructor parameter, pass your own instead of relying on a hardcoded default:
   ```dart
   final service = LedService(
     databaseUrl: 'https://your-project-default-rtdb.firebaseio.com',
   );
   ```
3. Run it:
   ```bash
   flutter run
   ```

> **Note on Firebase rules:** this app doesn't use authentication, so make sure your database rules aren't left wide open once you have real hardware attached, lock reads/writes down to whatever level makes sense for your setup.

### Android

If you're building a release/profile APK, double check `android/app/src/main/AndroidManifest.xml` includes:
```xml
<uses-permission android:name="android.permission.INTERNET" />
```
(Flutter only auto-adds this to the debug manifest, not the main one.)

## Project structure

```
lib/
├── main.dart
├── models/led_state.dart       immutable LED state + Firebase (de)serialization
├── services/led_service.dart   Firebase REST client (fetch/write/debounce/stream)
├── screens/dashboard_screen.dart
└── widgets/                    power toggle, RGB sliders, brightness slider, color preview
```

## How it works

- `updateImmediate` fires for power toggle, random color, and the final slider value on release.
- `updateDebounced` batches rapid slider-drag writes into a single request every 250ms instead of flooding the database.
- `watch()` opens an SSE connection to `/led.json` so the UI reflects changes made from the ESP32 or another instance of the app in real time.
