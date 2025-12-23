# Domain Validation Verification

This document verifies that the domain validation logic in `mobile/flutter_app/lib/services/validators.dart` correctly implements the requirements.

## Requirements

1. Subscription URL host must be exactly `persiangames.online` (no subdomains)
2. Connection links (vmess, vless, trojan, ss) must have server host that is either:
   - Exactly `persiangames.online`, OR
   - Ends with `.persiangames.online` (subdomains allowed)

## Implementation Review

### Subscription URL Validation (`isAllowedSubscriptionUrl`)

```dart
return uri.host == allowedDomain;
```

✅ **Correct**: Uses exact equality check, rejects subdomains

**Test Cases:**
- ✅ `https://persiangames.online/subscription` → VALID
- ✅ `http://persiangames.online/api` → VALID
- ❌ `https://sub.persiangames.online/subscription` → INVALID (subdomain)
- ❌ `https://example.com/subscription` → INVALID (different domain)
- ❌ `persiangames.online/subscription` → INVALID (no scheme)

### Connection Link Validation (`validateLink`)

Uses `_hostAllowed` helper:

```dart
static bool _hostAllowed(String host, String allowedDomain) {
  if (host.isEmpty) return false;
  return host == allowedDomain || host.endsWith('.$allowedDomain');
}
```

✅ **Correct**: Accepts exact match OR subdomain (ending with `.persiangames.online`)

**Test Cases:**

#### VLESS
- ✅ `vless://uuid@persiangames.online:443` → VALID
- ✅ `vless://uuid@server.persiangames.online:443` → VALID
- ❌ `vless://uuid@example.com:443` → INVALID

#### VMess
- ✅ `vmess://base64({"add":"persiangames.online",...})` → VALID
- ✅ `vmess://base64({"add":"cdn.persiangames.online",...})` → VALID
- ❌ `vmess://base64({"add":"badhost.com",...})` → INVALID

#### Trojan
- ✅ `trojan://password@persiangames.online:443` → VALID
- ✅ `trojan://password@node1.persiangames.online:443` → VALID
- ❌ `trojan://password@evil.com:443` → INVALID

#### Shadowsocks
- ✅ `ss://base64@persiangames.online:8388` → VALID
- ✅ `ss://base64@proxy.persiangames.online:8388` → VALID
- ❌ `ss://base64@unauthorized.net:8388` → INVALID

#### Unsupported
- ❌ `http://persiangames.online/config` → INVALID (unsupported scheme)

## Error Messages

The implementation provides clear error messages:
- "Empty link" for empty strings
- "vmess/vless/trojan/shadowsocks host must end with persiangames.online" for domain mismatches
- "Unsupported scheme" for unknown protocols
- "Invalid link: <error>" for parse errors

## Conclusion

✅ The domain validation logic correctly implements all requirements.
