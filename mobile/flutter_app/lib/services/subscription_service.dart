import 'dart:async';
import 'package:http/http.dart' as http;
import 'validators.dart';

class SubscriptionService {
  static Future<List<String>> fetchLinks(String url) async {
    final res = await http.get(Uri.parse(url), headers: {
      'Accept': 'text/plain',
      'Cache-Control': 'no-cache',
    });
    if (res.statusCode != 200) {
      throw Exception('Subscription fetch failed: ${res.statusCode}');
    }
    final body = res.body.trim();
    final lines = body.split(RegExp(r'\r?\n')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    return lines;
  }

  static Future<void> schedulePeriodicRefresh(Function() getAppState) async {
    Timer.periodic(const Duration(hours: 6), (_) async {
      final appState = getAppState();
      // Hook to call appState.refreshSubscription() for desktop targets.
    });
  }
}
