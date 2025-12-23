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
    // Note: For desktop targets, implement periodic refresh using a timer.
    // For mobile, WorkManager (Android) and BGAppRefreshTask (iOS) handle this.
    // This method is kept as a placeholder for desktop implementation.
  }
}
