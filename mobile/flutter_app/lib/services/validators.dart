import 'dart:convert';

class ValidationResult {
  final bool valid;
  final String? message;
  ValidationResult(this.valid, [this.message]);
}

class Validators {
  static bool isAllowedSubscriptionUrl(String url, String allowedDomain) {
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || !(uri.scheme == 'http' || uri.scheme == 'https')) {
        return false;
      }
      return uri.host == allowedDomain;
    } catch (_) {
      return false;
    }
  }

  static ValidationResult validateLink(String link, String allowedDomain) {
    if (link.isEmpty) {
      return ValidationResult(false, 'Empty link');
    }
    try {
      if (link.startsWith('vmess://')) {
        final b64 = link.substring('vmess://'.length);
        try {
          final jsonStr = utf8.decode(base64.decode(_normalizeB64(b64)));
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          final host = (map['add'] ?? '').toString();
          if (_hostAllowed(host, allowedDomain)) {
            return ValidationResult(true);
          }
          return ValidationResult(false, 'vmess host must end with $allowedDomain');
        } on FormatException {
          return ValidationResult(false, 'Invalid vmess link: base64 decode failed');
        }
      } else if (link.startsWith('vless://')) {
        final uri = Uri.parse(link);
        final host = uri.host;
        if (_hostAllowed(host, allowedDomain)) return ValidationResult(true);
        return ValidationResult(false, 'vless host must end with $allowedDomain');
      } else if (link.startsWith('trojan://')) {
        final uri = Uri.parse(link);
        final host = uri.host;
        if (_hostAllowed(host, allowedDomain)) return ValidationResult(true);
        return ValidationResult(false, 'trojan host must end with $allowedDomain');
      } else if (link.startsWith('ss://')) {
        final uri = Uri.parse(link);
        String host = uri.host;
        if (host.isEmpty) {
          final b64 = link.substring('ss://'.length);
          try {
            final decoded = utf8.decode(base64.decode(_normalizeB64(b64)));
            final atIdx = decoded.lastIndexOf('@');
            if (atIdx != -1) {
              final after = decoded.substring(atIdx + 1);
              final parts = after.split(':');
              host = parts.isNotEmpty ? parts.first : '';
            }
          } on FormatException {
            return ValidationResult(false, 'Invalid shadowsocks link: base64 decode failed');
          }
        }
        if (_hostAllowed(host, allowedDomain)) return ValidationResult(true);
        return ValidationResult(false, 'shadowsocks host must end with $allowedDomain');
      } else {
        return ValidationResult(false, 'Unsupported scheme');
      }
    } catch (e) {
      return ValidationResult(false, 'Invalid link: $e');
    }
  }

  static bool _hostAllowed(String host, String allowedDomain) {
    if (host.isEmpty) return false;
    return host == allowedDomain || host.endsWith('.$allowedDomain');
  }

  static String _normalizeB64(String s) {
    final pad = s.length % 4;
    if (pad != 0) {
      return s + '=' * (4 - pad);
    }
    return s;
  }
}
