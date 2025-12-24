# GOZAR VPN - Play Store Submission Guide

This guide explains how to build, sign, and submit the GOZAR VPN app to the Google Play Store.

## Prerequisites

Before you begin, ensure you have:
- A Google Play Console developer account ($25 one-time registration fee)
- Android development environment (Java 17+, Android SDK)
- The app source code with all required assets
- A signing key for release builds

## Building for Release

### 1. Automated Build (Recommended)

Use the provided build script for a guided, automated build process:

```bash
cd scripts
./build_android_native.sh
```

Select option **6** for "Full build (install prereqs + build release)".

This will:
- Install all prerequisites (Java, Android SDK, Gradle)
- Guide you through creating a signing key if needed
- Build both release APK and AAB (Android App Bundle)
- Output files to `dist/android/`

### 2. Manual Build

If you prefer to build manually:

#### Install Prerequisites

```bash
# Install Java 17
sudo apt-get install openjdk-17-jdk

# Set JAVA_HOME
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))

# Install Android SDK (or use Android Studio)
# Download from: https://developer.android.com/studio#command-tools
```

#### Create Signing Key

```bash
cd android

# Generate keystore
keytool -genkeypair \
    -alias gozar \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -keystore app/gozar-release.keystore

# Create keystore.properties
cat > keystore.properties <<EOF
storeFile=gozar-release.keystore
storePassword=YOUR_STORE_PASSWORD
keyAlias=gozar
keyPassword=YOUR_KEY_PASSWORD
EOF

chmod 600 keystore.properties
```

⚠️ **IMPORTANT**: Keep your keystore and passwords secure! You'll need the same key to update your app in the future.

#### Build Release APK/AAB

```bash
cd android

# Clean previous builds
./gradlew clean

# Build release AAB (recommended for Play Store)
./gradlew bundleRelease

# Build release APK (for direct distribution)
./gradlew assembleRelease
```

Output files:
- AAB: `android/app/build/outputs/bundle/release/app-release.aab`
- APK: `android/app/build/outputs/apk/release/app-release.apk`

## Preparing for Play Store

### 1. App Bundle Requirements

Google Play Store requires an **Android App Bundle (AAB)** for new apps. Use the `.aab` file, not the `.apk`.

### 2. Version Management

Update version information in `android/app/build.gradle`:

```gradle
defaultConfig {
    versionCode 1      // Increment for each release
    versionName "1.0.0" // Semantic version
}
```

- **versionCode**: Integer that must increase with each release
- **versionName**: User-visible version string

### 3. Required Assets

Prepare the following assets for Play Store listing:

#### App Icons
✅ Already included in the app

#### Screenshots
Required sizes (minimum 2 per category):
- Phone: 1080x1920 or higher (16:9 ratio)
- 7-inch tablet (optional): 1536x2048 or higher
- 10-inch tablet (optional): 2048x2732 or higher

Capture screenshots using:
```bash
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png
```

#### Feature Graphic
- Size: 1024 x 500 pixels
- Format: PNG or JPEG
- Use for Play Store banner

#### Privacy Policy
✅ Template included in `docs/PRIVACY_POLICY.md`

Host your privacy policy on a publicly accessible URL (required for VPN apps).

### 4. App Description

**Short Description** (80 characters max):
```
Secure VPN client powered by Xray-core for private internet access
```

**Full Description** (4000 characters max):
```
GOZAR VPN - Secure & Private Internet Access

GOZAR is a professional VPN client powered by the advanced Xray-core engine, 
providing secure and private internet access on your Android device.

KEY FEATURES:
• Full device VPN protection
• Support for multiple protocols (VMess, VLESS, Trojan, Shadowsocks)
• QR code and clipboard import for easy setup
• Connection management and switching
• Persistent VPN connection
• Auto-reconnect on app restart
• Battery-friendly operation
• No ads, no tracking, no data collection

PRIVACY & SECURITY:
• All traffic encrypted through VPN tunnel
• No logs or analytics collected
• Open source components
• Transparent privacy practices

REQUIREMENTS:
• Android 5.0 (Lollipop) or higher
• VPN permission (required for functionality)
• Valid connection configuration

PERMISSIONS:
• VPN Service: Required to create and manage VPN tunnel
• Internet: Required for VPN connectivity
• Notifications: Shows VPN connection status
• Camera: Optional, for QR code scanning

DOMAIN RESTRICTION:
For security, this app only accepts connections from the persiangames.online 
domain and its subdomains.

SUPPORT:
For issues or questions, please visit our GitHub repository or contact support.

Note: This app requires a valid VPN server configuration to function. It does 
not provide VPN servers.
```

## Google Play Console Submission

### 1. Create App

1. Go to [Google Play Console](https://play.google.com/console)
2. Click "Create app"
3. Fill in:
   - App name: **GOZAR VPN**
   - Default language: English (United States)
   - App or game: App
   - Free or paid: Free
   - Developer Program Policies: Accept

### 2. App Content

#### Privacy Policy
- URL: Your hosted privacy policy URL
- Required for VPN apps

#### App Access
- All functionality available without special access

#### Ads
- Contains ads: **No**

#### Content Rating
Complete the questionnaire:
- App category: Productivity or Tools
- VPN functionality: Yes
- Answer all questions honestly

#### Target Audience
- Age groups: 18+
- VPN apps are for adult users

#### Data Safety
Declare data handling:
- **No data collected or shared** (if true)
- Declare VPN usage
- Submit for review

### 3. Store Listing

Upload all required assets:
- ✅ App icon (automated from app)
- 📷 Screenshots (minimum 2)
- 🖼️ Feature graphic
- 📝 App description (from above)
- 🏷️ Category: Tools
- 📧 Contact email
- 🌐 Privacy policy URL

### 4. Release

#### Production Release

1. Go to "Production" release track
2. Click "Create new release"
3. Upload your AAB file (`GOZAR-release.aab`)
4. Fill in release notes:

```
Initial release of GOZAR VPN

Features:
- Full device VPN protection with Xray-core
- Support for VMess, VLESS, Trojan, Shadowsocks protocols
- Easy connection management
- QR code and clipboard import
- Auto-reconnect functionality
- Battery-friendly operation
```

5. Review and rollout release

#### Staged Rollout (Recommended)

Start with a small percentage (e.g., 20%) and increase gradually:
- Allows you to catch issues before full rollout
- Can halt or increase rollout percentage
- Monitor crash reports and reviews

### 5. App Review

Google will review your app (typically 1-7 days):
- Policy compliance check
- Security scan
- Functionality verification

Monitor review status in Play Console.

## Post-Release

### Update Process

For each update:

1. Increment version code and name in `build.gradle`:
   ```gradle
   versionCode 2
   versionName "1.0.1"
   ```

2. Build new release:
   ```bash
   ./scripts/build_android_native.sh release
   ```

3. Upload to Play Console:
   - Create new release in Production track
   - Upload new AAB
   - Add release notes describing changes

4. Submit for review

### Monitoring

- **Crashes**: Monitor in Play Console → Quality → Android vitals
- **Reviews**: Respond to user reviews promptly
- **Pre-launch Report**: Check automated testing results
- **Statistics**: Track installs, ratings, and engagement

## Compliance Notes

### VPN App Requirements

Google Play requires VPN apps to:
- ✅ Clearly disclose VPN functionality
- ✅ Request VPN permission explicitly
- ✅ Show persistent notification when VPN is active
- ✅ Have a clear privacy policy
- ✅ Not engage in deceptive behavior
- ✅ Comply with local laws

### Data Safety

VPN apps must clearly declare:
- What data is collected (if any)
- How data is used
- Whether data is shared with third parties
- Security practices

GOZAR collects:
- ✅ No personal data
- ✅ Connection configurations (stored locally)
- ✅ No analytics or tracking

### Export Regulations

If distributing globally, be aware of:
- Encryption export regulations
- Country-specific VPN restrictions
- Compliance requirements for different regions

## Troubleshooting

### Build Errors

**Gradle build fails**:
```bash
# Clear Gradle cache
./gradlew clean
rm -rf ~/.gradle/caches
./gradlew assembleRelease --refresh-dependencies
```

**Signing errors**:
- Verify `keystore.properties` file exists and has correct paths
- Ensure keystore file is in `android/app/` directory
- Check passwords are correct

### Upload Issues

**App Bundle rejected**:
- Ensure AAB is signed with release key
- Check version code is higher than previous release
- Verify app bundle is for correct architecture

**Review rejection**:
- Read rejection reason carefully
- Address specific issues mentioned
- Resubmit with fixes and explanation

## Resources

- [Android Developer Documentation](https://developer.android.com/)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [Play Store Policies](https://play.google.com/about/developer-content-policy/)
- [App Signing Best Practices](https://developer.android.com/studio/publish/app-signing)
- [Android App Bundle](https://developer.android.com/guide/app-bundle)

## Support

For issues with the build process or app:
- GitHub Issues: https://github.com/ehssanehs/Gozar/issues
- Email: [Your support email]

## Security Notes

### Keystore Security

⚠️ **CRITICAL**: Your keystore is the key to updating your app!

- **Backup** your keystore file and passwords securely
- **Never commit** keystore or passwords to version control
- **Store** in multiple secure locations (encrypted backups)
- **Lost keystore** = Cannot update app (must create new app listing)

### Google Play App Signing

Consider enabling Google Play App Signing:
- Google securely manages your app signing key
- You upload with an upload key (can be reset if lost)
- Additional security layer
- Recommended for production apps

Enable in Play Console → Setup → App integrity → App signing

## Checklist

Before submission, verify:

- [ ] App builds without errors
- [ ] Release is signed with release keystore
- [ ] Version code and name are correct
- [ ] All required assets are prepared (screenshots, feature graphic)
- [ ] Privacy policy is hosted and accessible
- [ ] App description is complete and accurate
- [ ] Content rating questionnaire is completed
- [ ] Data safety form is filled out
- [ ] App has been tested on real devices
- [ ] VPN functionality works correctly
- [ ] Notification appears when VPN is active
- [ ] Auto-reconnect works after app restart
- [ ] No crashes or major bugs
- [ ] Release notes are written
- [ ] Support email is set up
- [ ] Keystore is backed up securely

Good luck with your Play Store submission! 🚀
