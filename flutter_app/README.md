# Flutter Android App

This directory contains a Flutter-based Android application for the Gozar project.

## Project Information

- **Package Name**: com.ehssanehs.gozar
- **Min SDK**: 21 (Android 5.0)
- **Target SDK**: 34 (Android 14)
- **Build System**: Flutter with Gradle

## Prerequisites

- Flutter SDK (stable channel)
- Java 17 or later
- Android SDK with API level 34

## Local Development

### Setup

1. Install Flutter:
   ```bash
   # Follow instructions at https://flutter.dev/docs/get-started/install
   ```

2. Verify Flutter installation:
   ```bash
   flutter doctor -v
   ```

3. Get dependencies:
   ```bash
   cd flutter_app
   flutter pub get
   ```

### Building

#### Debug Build

```bash
cd flutter_app
flutter build apk --debug
```

Output: `build/app/outputs/apk/debug/app-debug.apk`

#### Release Build (Unsigned)

```bash
cd flutter_app
flutter build apk --release
```

Output: `build/app/outputs/apk/release/app-release.apk`

#### Release Build (Signed)

1. Create a keystore:
   ```bash
   keytool -genkey -v -keystore ~/app-release.keystore -keyalg RSA \
     -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `android/key.properties` (see `android/key.properties.example`):
   ```properties
   storePassword=<your-store-password>
   keyPassword=<your-key-password>
   keyAlias=upload
   storeFile=/path/to/your/app-release.keystore
   ```

3. Build signed APK:
   ```bash
   flutter build apk --release
   ```

**Note**: Never commit `key.properties` or keystore files to version control!

### Running

```bash
cd flutter_app
flutter run
```

## CI/CD

The repository includes a GitHub Actions workflow at `.github/workflows/flutter-android-release.yml` that automatically builds APK artifacts.

### Workflow Triggers

- Manual dispatch via GitHub Actions UI
- Push to tags matching: `v*`, `release-*`, `android-*`

### Configuring Signing for CI

To enable signed builds in CI, configure the following repository secrets in GitHub:

1. Go to: Repository Settings → Secrets and variables → Actions
2. Add these secrets:
   - `ANDROID_KEYSTORE_BASE64`: Base64-encoded keystore file
   - `ANDROID_KEYSTORE_PASSWORD`: Keystore password
   - `ANDROID_KEY_ALIAS`: Key alias (e.g., "upload")
   - `ANDROID_KEY_PASSWORD`: Key password

#### Creating Base64-encoded Keystore

```bash
# Encode keystore to base64
base64 -i app-release.keystore | pbcopy  # macOS
base64 -i app-release.keystore | xclip   # Linux
```

### Workflow Behavior

- **With secrets configured**: Produces signed APK
- **Without secrets**: Produces unsigned APK (still usable for testing)

### Downloading Built APKs

1. Go to the Actions tab in GitHub
2. Select the workflow run
3. Download the `apk-release` artifact

For tagged releases, the APK is also attached to the GitHub Release.

## Project Structure

```
flutter_app/
├── android/                 # Android-specific code
│   ├── app/
│   │   ├── build.gradle    # App-level Gradle config with signing
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       └── kotlin/     # Kotlin source files
│   ├── gradle/
│   │   └── wrapper/
│   ├── settings.gradle      # Project-level Gradle config
│   ├── gradle.properties
│   └── key.properties.example
├── lib/
│   └── main.dart           # Flutter app entry point
├── pubspec.yaml            # Flutter dependencies
└── README.md               # This file
```

## Troubleshooting

### Flutter Doctor Issues

Run `flutter doctor -v` to diagnose issues. Common fixes:

- **Android licenses**: Run `flutter doctor --android-licenses`
- **Java version**: Ensure Java 17 is installed and `JAVA_HOME` is set
- **SDK not found**: Set `ANDROID_HOME` environment variable

### Build Failures

- **Gradle sync failed**: Delete `android/.gradle` and rebuild
- **Out of memory**: Increase Gradle memory in `android/gradle.properties`
- **Signing failed**: Verify paths and passwords in `key.properties`

### APK Won't Install

- **Signature mismatch**: Uninstall existing app first
- **Min SDK**: Ensure device runs Android 5.0 or later

## Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Android Developer Guides](https://developer.android.com/guide)
- [Flutter Build and Release](https://flutter.dev/docs/deployment/android)
