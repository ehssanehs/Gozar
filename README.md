# GOZAR VPN

Cross-platform VPN client for Android, iOS, Windows, and macOS powered by Xray-core. Supports VLESS, VMess, and other Xray protocols. Includes:
- Large connect circle UI with elapsed time display
- Domain restriction: only accepts connection and subscription links from `persiangames.online`
- Routing rules configurable in Settings
- Periodic subscription refresh (on startup and every ~6 hours)
- Battery-friendly operation

## Platforms & Architecture

- UI Layer: Flutter (Android, iOS, Windows, macOS)
- Core Layer: Go wrapper around Xray-core
  - Mobile: Built via gomobile (`AAR` for Android, `.xcframework` for iOS)
  - Desktop: Shared library loaded via FFI
- iOS: NEPacketTunnelProvider network extension for App Store-compliant VPN
- Android: `VpnService` implementation to route traffic through Xray

## Features

- Protocols: VLESS, VMess, Trojan, Shadowsocks (and more supported by Xray)
- Link acceptance restriction:
  - Subscription links must have host `persiangames.online`
  - Direct connection links (e.g., `vmess://`, `vless://`, `trojan://`, `ss://`) must have server host ending with `persiangames.online`
- Routing rules: editable and saved, applied to Xray config
- Subscription refresh: on app start and every ~6 hours (platform schedulers used)
- Battery minimization: controlled keepalives, reduced logging, no wake-locks, idle disconnect

## Compliance Notes

- iOS: Requires Network Extensions capability (Packet Tunnel). Ensure compliance with Apple App Store Review Guidelines:
  - Legitimate VPN use cases
  - Transparent privacy practices
  - Avoid claims encouraging illegal/unlawful usage
- Android: Implemented via `VpnService`. Comply with Google Play policies:
  - Clear disclosures for data handling
  - No deceptive behavior
- Export controls: If distributing globally, review encryption export regulations.

## Building

### Prerequisites
- Flutter SDK (3.24+ recommended)
- Go (1.21+) and gomobile (`go install golang.org/x/mobile/cmd/gomobile@latest`)
- Xray-core module
- Android Studio and Xcode (for respective platforms)
- Apple Developer account with Network Extensions enabled (for iOS)
- Windows/macOS toolchains for desktop builds

### Steps (high-level)
1. Build core:
   - `cd core/go`
   - `go mod tidy`
   - `gomobile bind -target=android -o ../mobile-bind/android/gozar.aar ./...`
   - `gomobile bind -target=ios -o ../mobile-bind/ios/Gozar.xcframework ./...`
2. Integrate bindings:
   - Android: add AAR to `android/app/libs` and update Gradle
   - iOS: add `.xcframework` to the iOS Runner and Packet Tunnel extension targets
3. Flutter setup:
   - `cd mobile/flutter_app`
   - `flutter pub get`
   - Platform configs:
     - Android: add VpnService, WorkManager
     - iOS: Add Network Extensions, BGAppRefreshTask
4. Desktop:
   - Build shared library from Go core; configure FFI in Flutter desktop project

## Repository Structure

```
core/
  go/
    go.mod
    xray_controller.go
  mobile-bind/
    android/
      gozar.aar (generated)
    ios/
      Gozar.xcframework (generated)
mobile/
  flutter_app/
    pubspec.yaml
    lib/
      main.dart
      services/
        xray_controller.dart
        subscription_service.dart
        validators.dart
      screens/
        settings_screen.dart
    android/ (Flutter android)
    ios/ (Flutter ios, plus integration with extension)
android/
  app/
    src/main/java/.../XrayVpnService.kt
ios/
  GozarPacketTunnel/
    PacketTunnelProvider.swift
desktop/
  (FFI setup for Windows/macOS)
docs/
  PRIVACY_POLICY.md
  STORE_COMPLIANCE.md
LICENSE.md
```

## Privacy & Security

- Minimal data collection (only app settings and local configuration)
- No analytics by default
- Optional crash logging (off by default)
- Clear privacy policy is included in `docs/PRIVACY_POLICY.md` (template)

## Subscription Refresh

- On app startup
- Scheduled ~every 6 hours
  - Android: WorkManager periodic work
  - iOS: BGAppRefreshTask (not guaranteed exact intervals)
  - Desktop: timer-based refresh while app runs

## Domain Restrictions

- Accepting links only from `persiangames.online`:
  - Subscription URL host must be `persiangames.online`
  - Direct connection URIs must have server host ending with `persiangames.online`
  - Reject all other domains

## Next Steps

- Wire gomobile/FFI for Xray-core start/stop
- Persist routing rules and apply to generated Xray config
- Complete background schedulers (Android/iOS)
- Prepare store listings (metadata and privacy policy)
