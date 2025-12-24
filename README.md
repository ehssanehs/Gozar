# GOZAR VPN

Secure VPN client for Android powered by Xray-core. Supports VLESS, VMess, Trojan, and Shadowsocks protocols.

## ⚠️ Current Status: Native Android Implementation

**The Android app has been migrated to a fully native implementation.** The Flutter UI mentioned in legacy documentation has been replaced with a native Kotlin Android app.

## Features

- **Full Device VPN Protection**: Routes all device traffic through the VPN tunnel
- **Multiple Protocols**: VMess, VLESS, Trojan, Shadowsocks (all Xray protocols supported)
- **Domain Restriction**: Only accepts connections from `persiangames.online` and its subdomains
- **Easy Import**: QR code scanning, clipboard paste, and manual input
- **Connection Management**: Store multiple connections, switch easily
- **Auto-Reconnect**: Restores VPN connection on app restart
- **Persistent Service**: VPN stays active when app is minimized or closed
- **Battery Friendly**: Optimized for minimal battery drain
- **No Tracking**: Zero analytics or data collection

## Platform Support

### Android (Native - Production Ready) ✅
- **Min SDK**: Android 5.0 (API 21)
- **Target SDK**: Android 14 (API 34)
- **Architecture**: Native Kotlin with ViewBinding UI
- **VPN**: Android VpnService with foreground notification
- **Database**: Room for persistent storage
- **Status**: **Production ready** - see [Android Build Guide](BUILD.md)

### iOS, Windows, macOS (Flutter - Legacy)
The Flutter implementation remains available for iOS, Windows, and macOS. See legacy documentation in `mobile/flutter_app/` for these platforms.

## Quick Start (Android)

### Building

```bash
# Automated build with all prerequisites
cd scripts
./build_android_native.sh

# Follow the interactive menu:
# Option 1: Install prerequisites
# Option 2: Setup signing (for release)
# Option 4: Build release APK/AAB
```

For detailed build instructions, see [BUILD.md](BUILD.md).

### Installing

```bash
# Debug build
adb install dist/android/GOZAR-debug.apk

# Or install from Play Store (when published)
```

## Android Architecture

```
┌─────────────────────────────────────────┐
│           UI Layer (MVVM)               │
│  MainActivity, ConnectionAdapter,       │
│  QrScanActivity, MainViewModel          │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│        Service Layer                    │
│  XrayVpnService (ForegroundService)     │
│  - VPN tunnel management                │
│  - Xray-core integration                │
│  - Persistent notification              │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│         Data Layer                      │
│  Room Database (Connection entity)      │
│  ConnectionDao, Repository              │
│  SharedPreferences (state)              │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│        Utility Layer                    │
│  ConnectionParser (validation)          │
│  XrayConfigBuilder (config generation)  │
└─────────────────────────────────────────┘
```
## Key Components

### Android App (Native)

- **Location**: `android/`
- **Language**: Kotlin
- **UI**: ViewBinding (native Android layouts)
- **Build System**: Gradle 8.2.2
- **Database**: Room (SQLite)
- **Key Files**:
  - `app/src/main/java/com/persiangames/gozar/XrayVpnService.kt` - VPN service
  - `app/src/main/java/com/persiangames/gozar/ui/MainActivity.kt` - Main UI
  - `app/src/main/java/com/persiangames/gozar/utils/ConnectionParser.kt` - Link parsing
  - `app/src/main/java/com/persiangames/gozar/utils/XrayConfigBuilder.kt` - Xray config

### Build Scripts

- **Native Android**: `scripts/build_android_native.sh` - Automated build with prerequisites
- **Legacy Flutter**: `scripts/build_release.sh` - For iOS/Windows/macOS builds

### Documentation

- **[BUILD.md](BUILD.md)** - Comprehensive Android build guide
- **[docs/PLAY_STORE_SUBMISSION.md](docs/PLAY_STORE_SUBMISSION.md)** - Play Store submission guide
- **[android/README.md](android/README.md)** - Android implementation details
- **[docs/PRIVACY_POLICY.md](docs/PRIVACY_POLICY.md)** - Privacy policy template

## Domain Restriction

For security, GOZAR only accepts VPN connections from the `persiangames.online` domain:

- ✅ `persiangames.online` - Allowed
- ✅ `subdomain.persiangames.online` - Allowed (any subdomain)
- ❌ `example.com` - Rejected
- ❌ `persiangamesxonline.com` - Rejected

This is enforced at parse time for all connection URIs and subscription URLs.

## Permissions (Android)

GOZAR requires the following permissions:

- **VPN Service** (`BIND_VPN_SERVICE`) - Create and manage VPN tunnel (required)
- **Internet** - Network access (required)
- **Foreground Service** - Keep VPN running in background (required)
- **Notifications** - Show VPN connection status (Android 13+, optional)
- **Camera** - Scan QR codes for import (optional)
- **Network State** - Monitor connectivity (optional)

All permissions are requested at appropriate times with clear explanations.

## Building for Production

See [BUILD.md](BUILD.md) for complete instructions. Quick summary:

```bash
# Install prerequisites and build signed release
cd scripts
./build_android_native.sh full

# Outputs:
# - dist/android/GOZAR-release.apk (for direct distribution)
# - dist/android/GOZAR-release.aab (for Play Store)
```

## Play Store Submission

See [docs/PLAY_STORE_SUBMISSION.md](docs/PLAY_STORE_SUBMISSION.md) for detailed guide including:
- Required assets (screenshots, feature graphic, icons)
- Privacy policy requirements
- Content rating guidance
- Data safety declaration
- Submission process
- Post-release monitoring

## Privacy & Security

- **No data collection**: GOZAR collects no personal data, analytics, or tracking
- **Local storage only**: All connection data stored locally on device
- **Open source components**: Built on Xray-core and other open source projects
- **Domain restriction**: Only connects to validated, approved domains
- **Secure storage**: Room database with Android's built-in encryption support
- **ProGuard/R8**: Code minification and obfuscation enabled for release builds

## Development

### Project Structure

```
Gozar/
├── android/                          # Native Android app (PRODUCTION)
│   ├── app/
│   │   ├── src/main/java/com/persiangames/gozar/
│   │   │   ├── ui/                  # Activities, adapters, view models
│   │   │   ├── data/                # Database, DAOs, repositories
│   │   │   ├── utils/               # Parsers, config builders
│   │   │   ├── GozarApplication.kt
│   │   │   └── XrayVpnService.kt
│   │   └── src/main/res/            # Resources (layouts, icons)
│   ├── build.gradle
│   └── gradlew
├── mobile/flutter_app/              # Flutter app (iOS, Windows, macOS)
├── core/go/                         # Go wrapper for Xray-core
├── scripts/
│   ├── build_android_native.sh      # Android build script
│   └── build_release.sh             # Flutter build script
├── docs/
│   ├── PLAY_STORE_SUBMISSION.md
│   └── PRIVACY_POLICY.md
├── BUILD.md                         # Build instructions
└── README.md                        # This file
```

### Running Tests

```bash
cd android
./gradlew test                       # Unit tests
./gradlew connectedAndroidTest       # Instrumented tests (device required)
```

### Code Style

- **Kotlin**: Follow official Kotlin style guide
- **Android**: Follow Android best practices
- **Formatting**: Use Android Studio default formatter
- **Documentation**: KDoc for public APIs

## Roadmap

### Completed ✅
- [x] Native Android VPN client
- [x] Multi-protocol support (VMess, VLESS, Trojan, Shadowsocks)
- [x] Domain restriction enforcement
- [x] QR code and clipboard import
- [x] Connection management and persistence
- [x] Auto-reconnect functionality
- [x] Foreground service with notification
- [x] Build automation and scripts
- [x] Play Store preparation

### Future Enhancements
- [ ] Xray-core Go integration via gomobile
- [ ] Subscription URL import and auto-refresh
- [ ] Connection statistics and traffic monitoring
- [ ] Custom routing rules editor
- [ ] Settings screen
- [ ] Connection speed test
- [ ] Split tunneling (per-app VPN)
- [ ] IPv6 support
- [ ] Jetpack Compose UI migration (optional)

## Troubleshooting

### Build Issues
See [BUILD.md](BUILD.md) troubleshooting section.

### App Issues

**VPN won't connect:**
- Ensure VPN permission is granted
- Check connection configuration is valid
- Verify domain is persiangames.online or subdomain
- Check logcat: `adb logcat | grep Gozar`

**App crashes on startup:**
- Clear app data: Settings → Apps → GOZAR → Clear Data
- Reinstall the app
- Check Android version compatibility (5.0+)

**QR scanner not working:**
- Grant camera permission
- Ensure QR code contains valid connection URI
- Check lighting and focus

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Follow existing code style
5. Submit a pull request

## Support

- **GitHub Issues**: https://github.com/ehssanehs/Gozar/issues
- **Documentation**: See `docs/` directory
- **Build Help**: See [BUILD.md](BUILD.md)

## License

See [LICENSE.md](LICENSE.md) for details.

## Acknowledgments

- [Xray-core](https://github.com/XTLS/Xray-core) - Core VPN functionality
- Android Open Source Project - Platform and libraries
- Kotlin - Programming language
- All contributors and testers

---

**Application ID**: `com.persiangames.gozar`  
**Current Version**: 1.0.0  
**Minimum Android**: 5.0 (API 21)  
**Target Android**: 14 (API 34)
