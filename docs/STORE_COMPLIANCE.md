# Store Compliance Notes

## iOS (Apple App Store)
- Enable Network Extensions capability for Packet Tunnel in your Apple Developer account.
- Provide a clear Privacy Policy URL in App Store Connect.
- Avoid misleading claims; describe legitimate use cases.
- Confirm encryption export compliance if distributing outside the US.
- Background refresh via `BGAppRefreshTask` is best-effort; do not rely on exact timing.

## Android (Google Play)
- Use `VpnService` to implement VPN functionality.
- Declare foreground service and proper notifications if running persistent background tasks.
- Provide a clear privacy policy and data safety form.
- Use WorkManager for periodic tasks; interval may be flexed by the OS.

## General
- Do not encourage unlawful use.
- Ensure clear user consent for any data collection.
- Localize disclosures as needed.
