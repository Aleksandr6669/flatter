
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';
import 'package:myapp/config_model.dart';
import 'package:myapp/web_view.dart';

// Use a global key to access the navigator state
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load the configuration file
  final AppConfig config = await _loadConfig();

  // Create the router instance
  final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          // Default route loads the WebView with the URL from the config file
          return WebViewScreen(url: config.url);
        },
      ),
      GoRoute(
        // This route handles deep links
        // e.g., myapp://webview?url=https%3A%2F%2Fyour-site.com%2Fauth-path
        path: '/webview',
        builder: (BuildContext context, GoRouterState state) {
          // Get the URL from the query parameter
          final String? url = state.uri.queryParameters['url'];
          if (url != null) {
            // Decode the URL (it's usually URL-encoded in a deep link)
            final String decodedUrl = Uri.decodeComponent(url);
            return WebViewScreen(url: decodedUrl);
          } else {
            // If no URL is in the deep link, fall back to the default URL
            return WebViewScreen(url: config.url);
          }
        },
      ),
    ],
  );

  runApp(MyApp(router: router));
}

Future<AppConfig> _loadConfig() async {
  final String configString = await rootBundle.loadString('assets/config.json');
  final Map<String, dynamic> configJson = json.decode(configString);
  return AppConfig.fromJson(configJson);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      title: 'Deep Linking WebView App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}
