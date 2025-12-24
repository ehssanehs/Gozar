# Android VPN Client Implementation

This document describes the Android implementation of the GOZAR VPN client.

## Architecture

### Components

1. **XrayVpnService**: Foreground VPN service that manages the VPN tunnel
   - Runs as a foreground service with notification (Android 8+)
   - Handles Android 12+ foreground service restrictions
   - Requests Android 13+ notification runtime permissions
   - Persists connection state across app restarts
   - Supports immediate reconnection when selected connection changes

2. **Data Layer**:
   - **Room Database**: Stores connection configurations
   - **Connection Entity**: Represents a VPN connection (id, name, link, protocol, host, port)
   - **ConnectionDao**: Database access operations
   - **ConnectionRepository**: Repository pattern for data access
   - **SharedPreferences**: Stores selected connection ID and connection state

3. **UI Layer**:
   - **MainActivity**: Main screen with connection list and connect button
   - **ConnectionAdapter**: RecyclerView adapter for connection list
   - **QrScanActivity**: QR code scanner for importing connections
   - **MainViewModel**: ViewModel managing app state and business logic

4. **Utilities**:
   - **ConnectionParser**: Parses and validates connection links (vmess, vless, trojan, ss)
   - **XrayConfigBuilder**: Generates Xray JSON configuration with outbounds and routing rules

## Key Features

### 1. Connect Button Gating
- Connect button is disabled until a connection is selected
- Shows "Select a connection first" error if clicked without selection
- Changes to "Disconnect" when VPN is active

### 2. Domain Restriction
- Only accepts connection links from `persiangames.online` domain
- Validates both subscription URLs and direct connection links
- Rejects all other domains with clear error messages

### 3. Connection Management
- Parse and validate vmess://, vless://, trojan://, ss:// links
- Store connections in Room database
- Generate unique Xray outbound per connection
- Support connection selection and deletion

### 4. Import Methods
- **Manual Entry**: Text input dialog for pasting links
- **Clipboard**: Paste button to import from clipboard
- **QR Code**: Camera-based QR scanner using ML Kit

### 5. Persistence and Lifecycle
- **Room Database**: Persists all connections across app restarts
- **SharedPreferences**: Stores selected connection ID and VPN state
- **Auto-reconnect**: Restores VPN connection on app restart if it was connected before
- **Foreground Service**: Keeps VPN running when app is minimized or closed

### 6. Auto-reconnect on Connection Change
- When a new connection is selected while VPN is active, automatically reconnects
- Seamless switching between connections without manual disconnect/connect

### 7. Permissions Handling
- **VPN Permission**: Requests VpnService permission before connecting
- **Notification Permission**: Requests POST_NOTIFICATIONS on Android 13+
- **Camera Permission**: Requests for QR code scanning

## Building the Android App

### Prerequisites
- Android SDK (API 21+, target API 34)
- Kotlin 1.9.22
- Gradle 8.2.2

### Build Steps

1. Open the `android` directory in Android Studio

2. Build the project:
   ```bash
   cd android
   ./gradlew build
   ```

3. Install on device:
   ```bash
   ./gradlew installDebug
   ```

### Integration with Go Core

The Android app is designed to integrate with the Go core via gomobile:

1. Build the Go module as an Android AAR:
   ```bash
   cd core/go
   gomobile bind -target=android -o ../../android/app/libs/gozar.aar ./...
   ```

2. Update `android/app/build.gradle` to include the AAR:
   ```gradle
   dependencies {
       implementation fileTree(dir: 'libs', include: ['*.aar'])
   }
   ```

3. Call Go functions from Kotlin in `XrayVpnService.kt`:
   ```kotlin
   import gozar.Gozar
   
   // Start Xray
   Gozar.start(configJson)
   
   // Stop Xray
   Gozar.stop()
   ```

## Configuration Generation

The app generates a complete Xray configuration with:

- **Inbounds**: SOCKS5 (port 10808) and HTTP (port 10809) proxies
- **Outbounds**: 
  - One outbound per connection with unique tag `outbound_<id>`
  - Selected connection aliased as `outbound_selected`
  - Direct outbound for local traffic
  - Blackhole outbound for blocked traffic
- **Routing Rules**:
  - Block ads using geosite:category-ads-all
  - Direct route for private IPs (geoip:private)
  - Direct route for local domains
  - Proxy route for international sites
  - Default to proxy

## Testing

### Manual Testing Checklist

1. **Connection Management**:
   - [ ] Add connection via manual input
   - [ ] Add connection via clipboard
   - [ ] Add connection via QR code
   - [ ] Select a connection
   - [ ] Delete a connection
   - [ ] Verify domain validation rejects invalid domains

2. **VPN Lifecycle**:
   - [ ] Connect button disabled without selection
   - [ ] Connect to VPN successfully
   - [ ] VPN notification appears
   - [ ] Minimize app - VPN stays connected
   - [ ] Close app - VPN stays connected
   - [ ] Reopen app - VPN state restored
   - [ ] Disconnect from VPN

3. **Auto-reconnect**:
   - [ ] Connect to VPN
   - [ ] Select different connection
   - [ ] Verify auto-reconnect happens
   - [ ] Close app while connected
   - [ ] Reopen app - verify auto-reconnect

4. **Permissions**:
   - [ ] VPN permission requested before first connect
   - [ ] Notification permission requested on Android 13+
   - [ ] Camera permission requested for QR scan

5. **Android Versions**:
   - [ ] Test on Android 12+ (foreground service restrictions)
   - [ ] Test on Android 13+ (notification runtime permission)

## Known Limitations

1. **Go Integration**: The actual Xray core integration via gomobile is marked as TODO and needs to be implemented
2. **Icons**: Placeholder launcher icons need to be replaced with actual app icons
3. **Settings**: Settings screen is not yet implemented
4. **Subscription Import**: Subscription URL functionality is defined but not fully wired in Android UI

## Security Considerations

- VPN service requires BIND_VPN_SERVICE permission
- All connection links must be from `persiangames.online` domain
- Connections stored in encrypted Room database (if device encryption enabled)
- No analytics or tracking by default

## Future Enhancements

1. Complete Go core integration via gomobile
2. Add subscription URL import and auto-refresh
3. Implement settings screen
4. Add connection statistics and traffic monitoring
5. Add connection speed test
6. Implement custom routing rules editor
