# GOZAR VPN - Post-Scaffold Checklist

This checklist outlines the work needed after the initial scaffold to create a fully functional VPN application.

## Phase 1: Xray-core Integration

### Go Module
- [ ] Add actual Xray-core integration to `core/go/xray_controller.go`
- [ ] Parse JSON config and start Xray instance
- [ ] Handle Xray runtime logs and errors
- [ ] Implement proper shutdown sequence
- [ ] Add connection status monitoring
- [ ] Build gomobile bindings:
  ```bash
  cd core/go
  gomobile bind -target=android -o ../mobile-bind/android/gozar.aar ./...
  gomobile bind -target=ios -o ../mobile-bind/ios/Gozar.xcframework ./...
  ```

### Android Integration
- [ ] Add AAR to `android/app/libs/`
- [ ] Update `android/app/build.gradle` to include AAR
- [ ] Wire `XrayVpnService` to gomobile bindings
- [ ] Pass TUN file descriptor to Xray
- [ ] Add foreground service notification
- [ ] Handle VPN permission requests
- [ ] Add WorkManager background task implementation

### iOS Integration
- [ ] Add xcframework to Xcode project
- [ ] Link framework to both main app and network extension targets
- [ ] Wire `PacketTunnelProvider` to gomobile bindings
- [ ] Pass packet flow to Xray
- [ ] Configure Network Extensions entitlement
- [ ] Add BGAppRefreshTask registration
- [ ] Handle VPN permission prompts

### Desktop (Windows/macOS)
- [ ] Build Go shared library (.so/.dylib/.dll)
- [ ] Create Flutter FFI bindings
- [ ] Implement platform-specific VPN routing
- [ ] Handle admin/root permissions for routing table modification

## Phase 2: Data Persistence

### Settings Storage
- [ ] Implement SharedPreferences wrapper
- [ ] Save/load connection links
- [ ] Save/load subscription URL
- [ ] Save/load routing rules
- [ ] Save/load battery settings (idle disconnect, low power mode)
- [ ] Auto-restore connections on app start

### State Management
- [ ] Persist connection state across app restarts
- [ ] Handle app backgrounding/foregrounding
- [ ] Maintain connection during device sleep (if settings allow)

## Phase 3: Features Enhancement

### Connection Management
- [ ] Generate proper Xray config from connection links
- [ ] Support multiple outbound protocols (VLESS, VMess, Trojan, SS)
- [ ] Implement connection link selection (currently uses all)
- [ ] Add connection testing/ping
- [ ] Show upload/download statistics
- [ ] Add connection history

### Routing Rules
- [ ] Parse routing rules from Settings
- [ ] Apply rules to Xray config
- [ ] Validate routing rules syntax
- [ ] Provide rule templates (bypass LAN, bypass China, etc.)
- [ ] Support domain-based routing
- [ ] Support IP-based routing

### Battery Optimization
- [ ] Implement idle disconnect logic
- [ ] Implement low power mode (reduced keepalives)
- [ ] Adjust logging level based on settings
- [ ] Monitor battery level and adjust behavior

### Subscription Management
- [ ] Test subscription fetch on real server
- [ ] Handle subscription formats (base64, plain text, etc.)
- [ ] Implement subscription update UI feedback
- [ ] Show last update time
- [ ] Handle subscription errors gracefully
- [ ] Add manual refresh button

## Phase 4: User Experience

### UI Polish
- [ ] Add loading indicators
- [ ] Improve error messages
- [ ] Add connection animations
- [ ] Show network type (WiFi/Cellular)
- [ ] Add app icon
- [ ] Add splash screen
- [ ] Implement dark/light theme toggle
- [ ] Add localization (English, Persian, etc.)

### Notifications
- [ ] Android foreground service notification
- [ ] Connection established notification
- [ ] Connection dropped notification
- [ ] Subscription update notification

### Logging
- [ ] Implement in-app log viewer
- [ ] Add log export functionality
- [ ] Respect low power mode for logging
- [ ] Add log rotation

## Phase 5: Testing

### Unit Tests
- [ ] Test all validators
- [ ] Test subscription parsing
- [ ] Test config generation
- [ ] Test routing rule parsing
- [ ] Test settings persistence

### Integration Tests
- [ ] Test full connection flow
- [ ] Test subscription refresh
- [ ] Test background tasks
- [ ] Test app lifecycle handling

### Platform Tests
- [ ] Test on Android devices (various API levels)
- [ ] Test on iOS devices (various iOS versions)
- [ ] Test on Windows 10/11
- [ ] Test on macOS
- [ ] Test VPN killswitch
- [ ] Test DNS leak prevention

## Phase 6: Store Preparation

### Apple App Store
- [ ] Complete privacy policy with specific details
- [ ] Create app screenshots (all required sizes)
- [ ] Write app description and keywords
- [ ] Get Network Extensions entitlement approved
- [ ] Submit for review
- [ ] Address review feedback

### Google Play Store
- [ ] Complete privacy policy
- [ ] Fill out data safety form
- [ ] Create app screenshots and feature graphic
- [ ] Write app description
- [ ] Submit for review
- [ ] Address review feedback

### Compliance
- [ ] Review export control regulations
- [ ] Ensure GDPR compliance (if applicable)
- [ ] Add terms of service
- [ ] Add user agreement

## Phase 7: Infrastructure

### Backend (Optional)
- [ ] Set up subscription server at persiangames.online
- [ ] Implement subscription API
- [ ] Add authentication (if needed)
- [ ] Monitor server health
- [ ] Set up CDN for distribution

### Analytics (Optional)
- [ ] Integrate crash reporting (Sentry/Firebase Crashlytics)
- [ ] Add anonymous usage analytics (opt-in)
- [ ] Monitor connection success rates
- [ ] Track subscription refresh success

### Updates
- [ ] Implement in-app update check
- [ ] Add changelog display
- [ ] Handle config format migrations

## Phase 8: Security Hardening

### Security Review
- [ ] Conduct security audit
- [ ] Test for DNS leaks
- [ ] Test for IP leaks (WebRTC, etc.)
- [ ] Verify TLS certificate validation
- [ ] Test credential storage security
- [ ] Review code for secrets

### Hardening
- [ ] Implement certificate pinning (if applicable)
- [ ] Add tamper detection
- [ ] Obfuscate sensitive strings
- [ ] Implement killswitch
- [ ] Add VPN leak protection

## Success Criteria

### Functional
- [ ] App connects successfully on all platforms
- [ ] Domain validation rejects non-persiangames.online links
- [ ] Subscription refresh works in background
- [ ] Settings persist correctly
- [ ] Connection remains stable during normal use

### Performance
- [ ] Connection establishes in < 5 seconds
- [ ] Battery drain is minimal (< 5% per hour idle)
- [ ] No memory leaks
- [ ] Smooth UI animations (60fps)

### Quality
- [ ] No crashes during normal use
- [ ] All tests pass
- [ ] Code review approved
- [ ] Security scan passed
- [ ] Store review approved

## Current Status

✅ **Scaffold Complete** - All initial files created  
⏳ **Phase 1** - Xray-core integration needed  
⏳ **Phase 2** - Persistence layer needed  
⏳ **Phase 3** - Feature enhancements needed  
⏳ **Phase 4** - UI polish needed  
⏳ **Phase 5** - Testing needed  
⏳ **Phase 6** - Store submission pending  
⏳ **Phase 7** - Infrastructure optional  
⏳ **Phase 8** - Security hardening recommended  

---

**Note**: This checklist is comprehensive and some items may be optional depending on your specific requirements and priorities.
