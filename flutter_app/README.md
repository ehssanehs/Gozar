# Gozar Flutter App

A Flutter-based Android application for Gozar VPN.

## Getting Started

This is the Flutter implementation of the Gozar VPN Android app.

### Prerequisites

- Flutter SDK (stable channel)
- Android SDK
- Java 17

### Building

```bash
# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release
```

The APK will be available at `build/app/outputs/flutter-apk/app-release.apk`.

### Signed Builds

To build a signed APK, configure signing in `android/key.properties` or via environment variables. See the main README for details.
