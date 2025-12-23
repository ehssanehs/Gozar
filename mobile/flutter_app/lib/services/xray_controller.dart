import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class XrayController {
  // Ensure geosite.dat and geoip.dat are available on the filesystem and return the directory path.
  Future<String> _ensureXrayAssets() async {
    final supportDir = await getApplicationSupportDirectory();
    final xrayDir = Directory('${supportDir.path}/xray');
    if (!await xrayDir.exists()) {
      await xrayDir.create(recursive: true);
    }

    final files = {
      'geosite.dat': 'assets/xray/geosite.dat',
      'geoip.dat': 'assets/xray/geoip.dat',
    };

    for (final entry in files.entries) {
      final out = File('${xrayDir.path}/${entry.key}');
      if (!await out.exists() || (await out.length()) == 0) {
        try {
          final bytes = await rootBundle.load(entry.value);
          await out.writeAsBytes(bytes.buffer.asUint8List());
        } catch (_) {
          // Create a readable placeholder to make the failure explicit at runtime.
          await out.writeAsString('// Missing ${entry.key}. Please provide real file in assets/xray and rebuild.');
        }
      }
    }

    return xrayDir.path;
  }

  // Build default Xray config with routing using geosite/geoip.
  Future<String> buildConfig(List<String> links) async {
    final assetDir = await _ensureXrayAssets();

    // TODO: Parse `links` (vmess/vless/trojan/ss) and build actual outbound(s) tagged "proxy".
    final config = {
      'log': {'loglevel': 'warning'},
      'dns': {
        'servers': [
          'https://1.1.1.1/dns-query',
          'https://8.8.8.8/dns-query',
        ],
        'queryStrategy': 'UseIP',
      },
      'routing': {
        'domainStrategy': 'AsIs',
        'rules': [
          // Block ads
          {
            'type': 'field',
            'domain': ['geosite:category-ads-all'],
            'outboundTag': 'blocked',
          },
          // Direct for private/local networks
          {
            'type': 'field',
            'ip': ['geoip:private'],
            'outboundTag': 'direct',
          },
          {
            'type': 'field',
            'domain': ['geosite:private', 'geosite:category-local'],
            'outboundTag': 'direct',
          },
          // Proxy for international/default
          {
            'type': 'field',
            'domain': ['geosite:geolocation-!cn'],
            'outboundTag': 'proxy',
          },
          // Fallback
          {'type': 'field', 'outboundTag': 'proxy'},
        ]
      },
      'inbounds': [
        {
          'port': 10808,
          'listen': '127.0.0.1',
          'protocol': 'socks',
          'settings': {'auth': 'noauth'}
        },
        {
          'port': 10809,
          'listen': '127.0.0.1',
          'protocol': 'http'
        }
      ],
      'outbounds': [
        {'protocol': 'freedom', 'tag': 'direct'},
        {'protocol': 'blackhole', 'tag': 'blocked'},
        // Placeholder; will be replaced by parsed connection links
        {'protocol': 'freedom', 'tag': 'proxy'},
      ],
      // Hint for native layer to locate geoip/geosite; Go bridge will set XRAY_LOCATION_ASSET using this.
      'gozarAssetDir': assetDir,
    };

    return const JsonEncoder.withIndent('  ').convert(config);
  }

  // Stub: Replace with native start via gomobile/FFI
  Future<bool> start(String configJson) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  Future<void> stop() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
