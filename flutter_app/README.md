# Gozar Flutter App

A simple Flutter-based Android application.

## Building

### Prerequisites

- Flutter SDK (stable channel)
- Java 17
- Android SDK with API 34

### Local Build

1. Install Flutter dependencies:
```bash
cd flutter_app
flutter pub get
```

2. Build unsigned release APK:
```bash
flutter build apk --release
```

The APK will be located at: `build/app/outputs/apk/release/app-release.apk`

### Signed Build

To create a signed release build, you have two options:

#### Option 1: Using keystore.properties file

Create a file `android/keystore.properties` with:
```properties
storeFile=/path/to/your/keystore.jks
storePassword=your_keystore_password
keyAlias=your_key_alias
keyPassword=your_key_password
```

Then build:
```bash
flutter build apk --release
```

#### Option 2: Using environment variables

Set the following environment variables:
```bash
export ANDROID_KEYSTORE_PATH=/path/to/your/keystore.jks
export ANDROID_KEYSTORE_PASSWORD=your_keystore_password
export ANDROID_KEY_ALIAS=your_key_alias
export ANDROID_KEY_PASSWORD=your_key_password
```

Then build:
```bash
flutter build apk --release
```

#### Option 3: Using base64-encoded keystore (for CI)

```bash
export ANDROID_KEYSTORE_BASE64=$(cat keystore.jks | base64 -w 0)
export ANDROID_KEYSTORE_PASSWORD=your_keystore_password
export ANDROID_KEY_ALIAS=your_key_alias
export ANDROID_KEY_PASSWORD=your_key_password
flutter build apk --release
```

## CI/CD

The GitHub Actions workflow automatically builds APKs on:
- Manual workflow dispatch
- Tag pushes matching: `v*`, `release-*`, or `android-*`

### Setting up CI Signing

Configure these secrets in your GitHub repository settings:

1. Go to Settings → Secrets and variables → Actions
2. Add the following repository secrets:
   - `ANDROID_KEYSTORE_BASE64`: Base64-encoded keystore file
   - `ANDROID_KEYSTORE_PASSWORD`: Keystore password
   - `ANDROID_KEY_ALIAS`: Key alias
   - `ANDROID_KEY_PASSWORD`: Key password

To encode your keystore:
```bash
cat your-keystore.jks | base64 -w 0
```

### Downloading Artifacts

After a successful CI build:
1. Go to the Actions tab
2. Click on the workflow run
3. Download the APK from the Artifacts section

For tagged releases, the APK is also attached to the GitHub Release.

## Project Structure

- `lib/main.dart` - Main application entry point
- `android/` - Android platform-specific code
- `android/app/build.gradle` - Build configuration with signing setup
