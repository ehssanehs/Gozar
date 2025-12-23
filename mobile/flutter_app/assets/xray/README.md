# Xray assets

Place the following files here before building:
- `geosite.dat`: domain lists (ads, local, geolocation categories)
- `geoip.dat`: IP ranges (private networks, country blocks)

Routing depends on these files:
- Ads blocked via `geosite:category-ads-all`
- Local/private routed direct via `geosite:private` and `geoip:private`
- International domains (e.g., `geosite:geolocation-!cn`) routed via proxy

Place the real files before building; placeholders are included to prevent build failures but routing will not function without real data.
