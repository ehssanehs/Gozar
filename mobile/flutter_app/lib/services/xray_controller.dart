class XrayController {
  Future<String> buildConfig(List<String> links) async {
    return '''
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    { "port": 10808, "listen": "127.0.0.1", "protocol": "socks", "settings": { "auth": "noauth" } },
    { "port": 10809, "listen": "127.0.0.1", "protocol": "http" }
  ],
  "outbounds": [
    { "protocol": "freedom" }
  ]
}
''';
  }

  Future<bool> start(String configJson) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  Future<void> stop() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
