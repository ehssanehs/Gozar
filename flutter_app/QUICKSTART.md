# Flutter Android App - Quick Reference

## 🚀 Quick Start

### Build Locally (Unsigned)
```bash
cd flutter_app
flutter pub get
flutter build apk --release
```
**Output**: `build/app/outputs/apk/release/app-release.apk`

### Build Locally (Signed)
Create `android/keystore.properties`:
```properties
storeFile=/path/to/keystore.jks
storePassword=YOUR_PASSWORD
keyAlias=YOUR_ALIAS
keyPassword=YOUR_PASSWORD
```

Then build:
```bash
flutter build apk --release
```

## 🔐 CI Signing Setup

Add GitHub repository secrets (Settings → Secrets → Actions):
- `ANDROID_KEYSTORE_BASE64` - Run: `cat keystore.jks | base64 -w 0`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

## 🏗️ Triggering CI Builds

### Manual Build
Actions → Flutter Android Release → Run workflow

### Tag Build (Creates Release)
```bash
git tag android-v1.0.0
git push origin android-v1.0.0
```

## 📦 Download APK

**From Actions**: Actions → workflow run → Artifacts → gozar-android-apk

**From Releases**: Releases page (for tag builds)

## 📚 Documentation

- **BUILD.md** - Build instructions
- **SIGNING.md** - Signing configuration guide
- **IMPLEMENTATION.md** - Complete technical documentation
- **README.md** - Overview

## ⚙️ Project Info

- **Package**: com.ehssanehs.gozar
- **Min SDK**: 21 (Android 5.0)
- **Target SDK**: 34 (Android 14)
- **Kotlin**: 1.9.0
- **Java**: 17

## 🧪 Testing

```bash
cd flutter_app
flutter test                    # Run tests
flutter doctor -v               # Check setup
./verify_build.sh              # Full verification
```

## 🔍 Troubleshooting

**Build fails?** Check `flutter doctor -v`

**Unsigned APK?** Verify signing secrets are set

**Can't install APK?** Enable "Unknown Sources" on device

For detailed help, see SIGNING.md
