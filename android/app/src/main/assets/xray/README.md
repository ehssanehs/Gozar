# Xray assets (Android native)

Place the following files in this directory before building release:

- `geosite.dat`: domain lists (ads, local, geolocation categories)
- `geoip.dat`: IP ranges (private networks, country blocks)

At app startup, `GozarApplication` copies these files to the app's internal storage at `files/xray/`, so Xray-core can read them by file path.

If these files are missing, the app will log an error and routing will not function correctly.
