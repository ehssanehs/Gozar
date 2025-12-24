# Android Signing Configuration

This document explains how to configure Android app signing for the Flutter app.

## Overview

The Flutter app in `flutter_app/` supports both signed and unsigned release builds. The signing configuration is flexible and supports multiple methods:

1. Environment variables (recommended for CI/CD)
2. `keystore.properties` file (recommended for local development)
3. Base64-encoded keystore (recommended for CI/CD)

If no signing configuration is provided, the build system will create an **unsigned** APK that can still be installed for testing purposes.

## Generating a Keystore

If you don't have a keystore yet, generate one:

```bash
keytool -genkey -v -keystore release-keystore.jks -alias gozar -keyalg RSA -keysize 2048 -validity 10000
```

You will be prompted for:
- Keystore password
- Key password
- Your organizational information

**Important**: Keep your keystore and passwords secure! Store them in a password manager.

## Local Development Setup

### Option 1: Using keystore.properties (Recommended)

1. Create `flutter_app/android/keystore.properties`:

```properties
storeFile=/absolute/path/to/release-keystore.jks
storePassword=your_keystore_password
keyAlias=gozar
keyPassword=your_key_password
```

2. Build signed APK:

```bash
cd flutter_app
flutter build apk --release
```

### Option 2: Using Environment Variables

```bash
export ANDROID_KEYSTORE_PATH=/path/to/release-keystore.jks
export ANDROID_KEYSTORE_PASSWORD=your_keystore_password
export ANDROID_KEY_ALIAS=gozar
export ANDROID_KEY_PASSWORD=your_key_password

cd flutter_app
flutter build apk --release
```

## CI/CD Setup (GitHub Actions)

The repository includes a GitHub Actions workflow that supports signed builds using repository secrets.

### Configuring Repository Secrets

1. Navigate to your GitHub repository
2. Go to **Settings** → **Secrets and variables** → **Actions**
3. Add the following secrets:

#### Required Secrets

- **ANDROID_KEYSTORE_BASE64**: Base64-encoded keystore file
- **ANDROID_KEYSTORE_PASSWORD**: Keystore password
- **ANDROID_KEY_ALIAS**: Key alias (e.g., `gozar`)
- **ANDROID_KEY_PASSWORD**: Key password

#### Encoding the Keystore

To encode your keystore to base64:

```bash
# Linux/macOS
cat release-keystore.jks | base64 -w 0

# Or save to clipboard
cat release-keystore.jks | base64 -w 0 | pbcopy  # macOS
cat release-keystore.jks | base64 -w 0 | xclip   # Linux with xclip
```

Copy the output and paste it as the `ANDROID_KEYSTORE_BASE64` secret.

### How CI Signing Works

The GitHub Actions workflow:

1. Checks if `ANDROID_KEYSTORE_BASE64` secret exists
2. If yes:
   - Decodes the base64 keystore to a temporary file
   - Sets environment variables for the build
   - Builds a **signed** APK
3. If no:
   - Builds an **unsigned** APK
   - Prints a message indicating unsigned build

Both signed and unsigned builds are uploaded as artifacts.

## Verifying the Signature

To verify an APK is signed:

```bash
# Check signature
jarsigner -verify -verbose -certs app-release.apk

# Or use apksigner (from Android SDK)
apksigner verify --verbose app-release.apk
```

## Security Best Practices

1. **Never commit keystores or passwords to version control**
   - The `.gitignore` already excludes `*.jks`, `*.keystore`, and `keystore.properties`

2. **Use strong passwords**
   - Minimum 12 characters
   - Mix of uppercase, lowercase, numbers, and symbols

3. **Backup your keystore securely**
   - Store in multiple secure locations
   - If you lose the keystore, you cannot update your app on Play Store

4. **Restrict access to secrets**
   - Only grant necessary team members access to GitHub secrets
   - Use environment-specific secrets if needed

5. **Rotate keys periodically**
   - Consider rotating signing keys every few years
   - Plan migration strategy for existing users

## Troubleshooting

### Build shows "Building UNSIGNED release APK"

This means signing configuration was not found. Check:
- Environment variables are set correctly
- `keystore.properties` exists and has correct values
- File paths in configuration are absolute, not relative

### "Keystore was tampered with, or password was incorrect"

- Verify keystore password is correct
- Check keystore file is not corrupted
- Ensure you're using the correct keystore file

### CI build fails with keystore error

- Verify all four secrets are set in GitHub
- Ensure base64 encoding was done correctly (no line breaks with `-w 0`)
- Check secret names match exactly (case-sensitive)

### APK install fails on device

For unsigned APKs:
- Some devices block unsigned APK installation
- Enable "Install from Unknown Sources" in device settings
- Consider building a signed APK for wider compatibility

## References

- [Android App Signing Documentation](https://developer.android.com/studio/publish/app-signing)
- [Flutter Build and Release Documentation](https://docs.flutter.dev/deployment/android)
- [GitHub Actions Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
