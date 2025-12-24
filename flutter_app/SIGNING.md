# Android Signing Configuration Guide

This document explains how to configure Android app signing for the Gozar Flutter app.

## Overview

The Flutter Android app supports both signed and unsigned release builds:
- **Signed builds**: Required for Play Store distribution and production use
- **Unsigned builds**: Suitable for testing and development

## Local Signing Setup

### Step 1: Create a Keystore (if you don't have one)

```bash
keytool -genkey -v -keystore ~/gozar-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias gozar
```

You'll be prompted for:
- Keystore password
- Key password
- Your name and organization details

**Important**: Store these passwords securely. You'll need them for every release build.

### Step 2: Configure key.properties

Create `flutter_app/android/key.properties`:

```properties
storeFile=/path/to/your/gozar-release.jks
storePassword=your_keystore_password
keyAlias=gozar
keyPassword=your_key_password
```

**Note**: The `key.properties` file is gitignored for security. Never commit it to version control.

### Step 3: Build Signed APK

```bash
cd flutter_app
flutter build apk --release
```

The signed APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

## CI/CD Signing Setup (GitHub Actions)

### Step 1: Encode Your Keystore

```bash
base64 -w 0 ~/gozar-release.jks > keystore-base64.txt
```

### Step 2: Add GitHub Secrets

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** for each of the following:

| Secret Name | Value |
|-------------|-------|
| `ANDROID_KEYSTORE_BASE64` | Contents of `keystore-base64.txt` |
| `ANDROID_KEYSTORE_PASSWORD` | Your keystore password |
| `ANDROID_KEY_ALIAS` | Your key alias (e.g., `gozar`) |
| `ANDROID_KEY_PASSWORD` | Your key password |

### Step 3: Trigger Build

**Option 1 - Manual dispatch**:
1. Go to **Actions** tab
2. Select **Flutter Android Release** workflow
3. Click **Run workflow**

**Option 2 - Tag push**:
```bash
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

The workflow will automatically build a signed APK and create a GitHub Release.

## Signing via Environment Variables

As an alternative to `key.properties`, you can use environment variables:

```bash
export ANDROID_KEYSTORE_PATH=/path/to/keystore.jks
export ANDROID_KEYSTORE_PASSWORD=your_keystore_password
export ANDROID_KEY_ALIAS=gozar
export ANDROID_KEY_PASSWORD=your_key_password

cd flutter_app
flutter build apk --release
```

This method is used automatically in the GitHub Actions workflow.

## Unsigned Builds (Development)

If no signing configuration is provided, the build will produce an unsigned APK:

```bash
cd flutter_app
flutter build apk --release
```

**Limitations of unsigned APKs**:
- Cannot be published to Google Play Store
- Will show a warning when installed on devices
- Suitable only for internal testing

## Troubleshooting

### "Keystore file not found"
- Verify the path in `key.properties` is absolute and correct
- Ensure the keystore file exists at the specified location

### "Incorrect keystore password"
- Double-check your password
- Ensure no extra spaces or special characters in `key.properties`

### "Key alias not found"
- Verify the alias matches the one used when creating the keystore
- List aliases: `keytool -list -v -keystore your-keystore.jks`

### CI build produces unsigned APK
- Verify all four secrets are correctly set in GitHub
- Check the workflow logs for "Signing configuration detected" message
- Ensure secret names match exactly (case-sensitive)

## Security Best Practices

1. **Never commit** `key.properties` or keystore files to Git
2. **Store keystore** in a secure location with backups
3. **Use strong passwords** for keystore and key
4. **Limit access** to signing credentials (only trusted team members)
5. **Rotate keys** if compromised
6. **Use different keys** for debug and release builds

## For Play Store Publishing

1. Build a signed **App Bundle** (recommended):
   ```bash
   flutter build appbundle --release
   ```
   Output: `build/app/outputs/bundle/release/app-release.aab`

2. Upload to Google Play Console
3. Google Play will sign the APK for distribution using its own key

## Additional Resources

- [Android App Signing Documentation](https://developer.android.com/studio/publish/app-signing)
- [Flutter Release Build Guide](https://docs.flutter.dev/deployment/android)
- [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)
