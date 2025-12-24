# GOZAR VPN - Build Instructions

This document provides comprehensive instructions for building the GOZAR native Android VPN application.

## Quick Start

For an automated build with all prerequisites:

```bash
cd scripts
./build_android_native.sh
# Select option 6: Full build (install prereqs + build release)
```

## Prerequisites

### System Requirements
- **Operating System**: Linux (Debian/Ubuntu recommended), macOS, or Windows with WSL
- **RAM**: 8 GB minimum, 16 GB recommended
- **Disk Space**: 10 GB free space
- **Internet Connection**: Required for downloading dependencies

### Required Software
- **Java Development Kit (JDK)**: OpenJDK 17 or later
- **Android SDK**: API Level 34 (Android 14)
- **Build Tools**: 34.0.0 or later
- **Gradle**: 8.2.2 (wrapper included)

## Installation Methods

### Method 1: Automated Installation (Recommended)

The build script will install all prerequisites automatically:

```bash
cd scripts
./build_android_native.sh
# Select option 1: Install all prerequisites
```

This will install:
- OpenJDK 17
- Android SDK and command-line tools
- Android platform and build tools
- Configure environment variables

### Method 2: Manual Installation

#### Install Java

**Debian/Ubuntu:**
```bash
sudo apt-get update
sudo apt-get install openjdk-17-jdk
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
```

**macOS (via Homebrew):**
```bash
brew install openjdk@17
export JAVA_HOME=/usr/local/opt/openjdk@17
```

**Verify installation:**
```bash
java -version
# Should show: openjdk version "17.x.x"
```

#### Install Android SDK

**Download Command Line Tools:**
```bash
mkdir -p $HOME/Android/Sdk/cmdline-tools
cd /tmp
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip commandlinetools-linux-*_latest.zip
mv cmdline-tools $HOME/Android/Sdk/cmdline-tools/latest
```

**Set Environment Variables:**
```bash
export ANDROID_SDK_ROOT=$HOME/Android/Sdk
export PATH=$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH
```

**Install Android Components:**
```bash
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

**Add to ~/.bashrc (optional but recommended):**
```bash
echo 'export ANDROID_SDK_ROOT=$HOME/Android/Sdk' >> ~/.bashrc
echo 'export PATH=$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH' >> ~/.bashrc
source ~/.bashrc
```

## Building the App

### Debug Build

For development and testing:

```bash
cd android
./gradlew assembleDebug
```

Output: `android/app/build/outputs/apk/debug/app-debug.apk`

Or use the build script:
```bash
cd scripts
./build_android_native.sh debug
```

### Release Build

For production/Play Store submission:

#### 1. Create Signing Key (First Time Only)

**Using the build script (guided):**
```bash
cd scripts
./build_android_native.sh
# Select option 2: Setup signing configuration
```

**Manual creation:**
```bash
cd android

# Generate keystore
keytool -genkeypair \
    -alias gozar \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -keystore app/gozar-release.keystore

# You'll be prompted for:
# - Keystore password
# - Key password
# - Certificate information (name, organization, etc.)

# Create keystore.properties file
cat > keystore.properties <<EOF
storeFile=gozar-release.keystore
storePassword=YOUR_STORE_PASSWORD
keyAlias=gozar
keyPassword=YOUR_KEY_PASSWORD
EOF

chmod 600 keystore.properties
```

**⚠️ CRITICAL**: Backup your keystore and passwords securely! You'll need the same key to update your app.

#### 2. Build Release APK/AAB

**Using the build script:**
```bash
cd scripts
./build_android_native.sh release
```

**Manual build:**
```bash
cd android
./gradlew clean
./gradlew assembleRelease   # For APK
./gradlew bundleRelease     # For AAB (Play Store)
```

**Outputs:**
- APK: `android/app/build/outputs/apk/release/app-release.apk`
- AAB: `android/app/build/outputs/bundle/release/app-release.aab`
- Copied to: `dist/android/GOZAR-release.{apk,aab}`

## Testing

### Run Unit Tests

```bash
cd android
./gradlew test
```

Or:
```bash
cd scripts
./build_android_native.sh test
```

### Manual Testing

**Install on Device:**
```bash
# Debug build
adb install dist/android/GOZAR-debug.apk

# Release build (for testing before Play Store)
adb install dist/android/GOZAR-release.apk
```

**Test Checklist:**
- [ ] App launches successfully
- [ ] Can add connection via manual input
- [ ] Can paste connection from clipboard
- [ ] Can scan QR code for connection
- [ ] Can select a connection
- [ ] Connect button is disabled without selection
- [ ] VPN connects successfully
- [ ] Notification appears when connected
- [ ] VPN stays connected when app is minimized
- [ ] VPN stays connected when app is closed
- [ ] VPN auto-reconnects after app restart
- [ ] Can switch connections while connected
- [ ] Can disconnect VPN
- [ ] Can delete connections
- [ ] Domain validation rejects invalid domains

## Troubleshooting

### Network Issues During Build

**Problem:** Cannot download dependencies from `dl.google.com`

**Solution:** The build environment may have restricted internet access. Ensure:
- Internet connection is active
- No firewall blocking dl.google.com
- No proxy issues
- Try alternative DNS servers

**Workaround for restricted environments:**
If building in a sandboxed environment with limited internet:
1. Download dependencies on an unrestricted machine
2. Copy Gradle cache: `~/.gradle/caches`
3. Copy Android SDK: `$ANDROID_SDK_ROOT`
4. Transfer to build environment

### Gradle Wrapper Issues

**Problem:** `./gradlew: No such file or directory`

**Solution:** The Gradle wrapper needs to be generated:
```bash
cd android
gradle wrapper --gradle-version 8.2.2
```

Or copy from this repository (wrapper files are included).

### Signing Configuration Issues

**Problem:** Release build uses debug signing

**Solution:** Ensure `keystore.properties` exists in `android/` directory:
```bash
ls -la android/keystore.properties
# Should exist and contain storeFile, storePassword, keyAlias, keyPassword
```

**Problem:** "Keystore was tampered with, or password was incorrect"

**Solution:** Verify passwords in `keystore.properties` match the keystore.

### Build Errors

**OutOfMemoryError during build:**
```bash
# Increase Gradle memory in gradle.properties
org.gradle.jvmargs=-Xmx4096m -Dfile.encoding=UTF-8
```

**Dependency resolution errors:**
```bash
# Clear Gradle cache and rebuild
cd android
./gradlew clean
rm -rf ~/.gradle/caches
./gradlew assembleRelease --refresh-dependencies
```

**Android SDK not found:**
```bash
# Set ANDROID_SDK_ROOT environment variable
export ANDROID_SDK_ROOT=$HOME/Android/Sdk
# Or specify in local.properties:
echo "sdk.dir=$HOME/Android/Sdk" > android/local.properties
```

## Build Script Reference

The `build_android_native.sh` script provides these options:

### Interactive Mode
```bash
./build_android_native.sh
```

Menu options:
1. Install all prerequisites
2. Setup signing configuration
3. Build debug APK
4. Build release APK + AAB
5. Run unit tests
6. Full build (install prereqs + build release)
0. Exit

### Non-Interactive Mode
```bash
./build_android_native.sh [command]
```

Commands:
- `install` - Install prerequisites
- `debug` - Build debug APK
- `release` - Build release APK and AAB
- `test` - Run unit tests
- `full` - Install prerequisites and build release

## Directory Structure

```
Gozar/
├── android/                          # Native Android app
│   ├── app/
│   │   ├── build.gradle             # App build configuration
│   │   ├── proguard-rules.pro       # ProGuard rules
│   │   ├── gozar-release.keystore   # Release signing key (not in git)
│   │   └── src/
│   │       ├── main/
│   │       │   ├── AndroidManifest.xml
│   │       │   ├── java/com/persiangames/gozar/
│   │       │   │   ├── ui/          # UI components
│   │       │   │   ├── data/        # Database and models
│   │       │   │   ├── utils/       # Utilities
│   │       │   │   ├── GozarApplication.kt
│   │       │   │   └── XrayVpnService.kt
│   │       │   └── res/             # Resources (layouts, icons, etc.)
│   │       └── test/                # Unit tests
│   ├── build.gradle                 # Project build configuration
│   ├── gradle.properties            # Gradle properties
│   ├── settings.gradle              # Gradle settings
│   ├── keystore.properties          # Signing configuration (not in git)
│   ├── gradlew                      # Gradle wrapper script
│   └── gradle/wrapper/              # Gradle wrapper files
├── dist/                            # Build outputs
│   └── android/
│       ├── GOZAR-debug.apk
│       ├── GOZAR-release.apk
│       └── GOZAR-release.aab
├── scripts/
│   └── build_android_native.sh      # Build automation script
└── docs/
    └── PLAY_STORE_SUBMISSION.md     # Play Store submission guide
```

## Version Management

Update version information in `android/app/build.gradle`:

```gradle
defaultConfig {
    versionCode 1      // Increment for each release (must be > previous)
    versionName "1.0.0" // User-visible version (semantic versioning)
}
```

**Version Code Rules:**
- Must be an integer
- Must increase with each release
- Cannot decrease
- Used by Play Store for update detection

**Version Name Guidelines:**
- Use semantic versioning: MAJOR.MINOR.PATCH
- Example: 1.0.0 → 1.0.1 (patch) → 1.1.0 (minor) → 2.0.0 (major)
- User-visible in Play Store and app info

## Continuous Integration

### GitHub Actions Example

```yaml
name: Build Android

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up JDK 17
      uses: actions/setup-java@v3
      with:
        java-version: '17'
        distribution: 'temurin'
    
    - name: Setup Android SDK
      uses: android-actions/setup-android@v2
    
    - name: Build with Gradle
      run: |
        cd android
        chmod +x gradlew
        ./gradlew assembleDebug
    
    - name: Run tests
      run: |
        cd android
        ./gradlew test
    
    - name: Upload APK
      uses: actions/upload-artifact@v3
      with:
        name: app-debug
        path: android/app/build/outputs/apk/debug/app-debug.apk
```

## Security Best Practices

### Keystore Management
- ✅ Keep keystore file secure and backed up
- ✅ Never commit keystore to version control
- ✅ Use strong passwords (16+ characters)
- ✅ Store passwords in a password manager
- ✅ Consider using Google Play App Signing
- ✅ Keep backup in multiple secure locations

### Code Security
- ✅ Enable ProGuard/R8 for release builds (already enabled)
- ✅ Review ProGuard rules for proper obfuscation
- ✅ Run security scans before release
- ✅ Keep dependencies updated
- ✅ Follow Android security best practices

## Play Store Submission

After building the release AAB, follow the detailed guide in:
```
docs/PLAY_STORE_SUBMISSION.md
```

This includes:
- Play Console setup
- Required assets preparation
- Privacy policy requirements
- Content rating questionnaire
- Release process
- Post-release monitoring

## Getting Help

### Build Issues
1. Check this README's troubleshooting section
2. Review Gradle build output for specific errors
3. Check Android Studio logs if using IDE
4. Search Android Developer documentation

### App Issues
1. Check logcat: `adb logcat | grep Gozar`
2. Review crash reports in Play Console
3. File issue on GitHub: https://github.com/ehssanehs/Gozar/issues

### Resources
- [Android Developer Docs](https://developer.android.com/)
- [Gradle Build Tool](https://gradle.org/)
- [Kotlin Documentation](https://kotlinlang.org/)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)

## License

See LICENSE.md in the repository root.

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

**Last Updated:** December 2024  
**Gradle Version:** 8.2.2  
**Android Target SDK:** 34 (Android 14)  
**Minimum SDK:** 21 (Android 5.0)
