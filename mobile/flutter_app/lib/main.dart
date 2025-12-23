import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'services/xray_controller.dart';
import 'services/subscription_service.dart';
import 'services/validators.dart';
import 'screens/settings_screen.dart';

const kPeriodicTaskName = 'subscription_refresh';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // TODO: Implement subscription refresh in background
    // This requires access to shared preferences to get subscription URL
    // and proper error handling for background execution
    return Future.value(true);
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  Workmanager().registerPeriodicTask(
    kPeriodicTaskName,
    kPeriodicTaskName,
    frequency: const Duration(hours: 6),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    existingWorkPolicy: ExistingWorkPolicy.replace,
    backoffPolicy: BackoffPolicy.linear,
    backoffDelay: const Duration(minutes: 15),
  );

  runApp(const GozarApp());
}

class GozarApp extends StatelessWidget {
  const GozarApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: MaterialApp(
        title: 'GOZAR VPN',
        theme: ThemeData(
          colorSchemeSeed: Colors.teal,
          brightness: Brightness.dark,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class AppState extends ChangeNotifier {
  static const allowedDomain = 'persiangames.online';
  final XrayController _xray = XrayController();
  bool isConnected = false;
  DateTime? _connectedAt;
  Duration elapsed = Duration.zero;
  Timer? _timer;

  final List<String> connectionLinks = [];
  String? subscriptionUrl;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> connect() async {
    if (isConnected) return;
    final config = await _xray.buildConfig(connectionLinks);
    final ok = await _xray.start(config);
    if (ok) {
      isConnected = true;
      _connectedAt = DateTime.now();
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_connectedAt != null) {
          elapsed = DateTime.now().difference(_connectedAt!);
          notifyListeners();
        }
      });
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    if (!isConnected) return;
    await _xray.stop();
    isConnected = false;
    _connectedAt = null;
    elapsed = Duration.zero;
    _timer?.cancel();
    notifyListeners();
  }

  void addLink(String link) {
    final result = Validators.validateLink(link, allowedDomain);
    if (!result.valid) {
      throw Exception(result.message ?? 'Invalid link');
    }
    if (!connectionLinks.contains(link)) {
      connectionLinks.add(link);
      notifyListeners();
    }
  }

  void setSubscriptionUrl(String url) {
    final ok = Validators.isAllowedSubscriptionUrl(url, allowedDomain);
    if (!ok) {
      throw Exception('Subscription URL must be from $allowedDomain');
    }
    subscriptionUrl = url;
    notifyListeners();
  }

  Future<void> refreshSubscription() async {
    if (subscriptionUrl == null) return;
    final newLinks = await SubscriptionService.fetchLinks(subscriptionUrl!);
    final filtered = newLinks.where((l) => Validators.validateLink(l, allowedDomain).valid);
    for (final l in filtered) {
      if (!connectionLinks.contains(l)) {
        connectionLinks.add(l);
      }
    }
    notifyListeners();
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _linkController = TextEditingController();
  final _subController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final app = context.read<AppState>();
      try {
        await app.refreshSubscription();
      } catch (e) {
        // Silently ignore subscription refresh errors on startup
        // User can manually trigger refresh if needed
      }
    });
  }

  @override
  void dispose() {
    _linkController.dispose();
    _subController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final elapsedText = _formatDuration(app.elapsed);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GOZAR VPN'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTap: () async {
                if (app.isConnected) {
                  await app.disconnect();
                } else {
                  try {
                    await app.connect();
                  } catch (e) {
                    _showSnack(context, 'Connect failed: $e');
                  }
                }
              },
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: app.isConnected
                        ? [Colors.greenAccent, Colors.green]
                        : [Colors.blueAccent, Colors.blue],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      app.isConnected ? Icons.power : Icons.power_settings_new,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      app.isConnected ? 'Connected' : 'Connect',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (app.isConnected)
                      Text(
                        elapsedText,
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _linkController,
            decoration: InputDecoration(
              labelText: 'Add connection link (vmess/vless/trojan/ss)',
              hintText: 'e.g., vmess://...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  final text = _linkController.text.trim();
                  if (text.isEmpty) return;
                  try {
                    context.read<AppState>().addLink(text);
                    _linkController.clear();
                    _showSnack(context, 'Link added');
                  } catch (e) {
                    _showSnack(context, e.toString());
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _subController,
            decoration: InputDecoration(
              labelText: 'Subscription URL (persiangames.online only)',
              hintText: 'https://persiangames.online/subscription',
              suffixIcon: IconButton(
                icon: const Icon(Icons.cloud_download),
                onPressed: () async {
                  final text = _subController.text.trim();
                  if (text.isEmpty) return;
                  try {
                    context.read<AppState>().setSubscriptionUrl(text);
                    await context.read<AppState>().refreshSubscription();
                    _showSnack(context, 'Subscription refreshed');
                  } catch (e) {
                    _showSnack(context, e.toString());
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Connections', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...app.connectionLinks.map((l) => Card(
                child: ListTile(
                  title: Text(
                    l,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  leading: const Icon(Icons.link),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      app.connectionLinks.remove(l);
                      app.notifyListeners();
                    },
                  ),
                ),
              )),
          if (app.connectionLinks.isEmpty)
            const Text(
              'No connection links added yet.',
              style: TextStyle(color: Colors.white70),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(d.inHours);
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return '$h:$m:$s';
  }

  void _showSnack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
  }
}
