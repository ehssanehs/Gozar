import 'dart:async';
import 'package:http/http.dart' as http;

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
    // Note: Timer.periodic for desktop/web in-app refresh.
    // For mobile, WorkManager (Android) and BGAppRefreshTask (iOS) handle background refresh.
    // This timer runs only when app is active and should be managed by the calling widget.
    Timer.periodic(const Duration(hours: 6), (_) {
      final appState = getAppState();
      // Call appState.refreshSubscription() in-app runtime for desktop targets if desired.
    });
  }
}
