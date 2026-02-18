
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';
import 'package:myapp/config_model.dart';
import 'package:myapp/error_screen.dart';
import 'package:myapp/web_view.dart';

// Use a global key to access the navigator state
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load the configuration file
  final AppConfig config = await _loadConfig();
  final Uri trustedUri = Uri.parse(config.url);

  // Create the router instance with a new, simpler logic
  final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/', // Set initial location for normal app start
    routes: <RouteBase>[
      // This single, catch-all route handles both normal app starts and deep links.
      GoRoute(
        path: '/:path(.*)', // Matches '/' and any other path like '/auth'
        builder: (BuildContext context, GoRouterState state) {
          String finalUrl;

          // Check if it's a normal app start (path is '/' and no query params)
          // GoRouter automatically navigates to initialLocation on first launch.
          if (state.uri.path == '/' && state.uri.query.isEmpty) {
            // On normal start, just use the base URL from the config
            finalUrl = config.url;
          } else {
            // It's a deep link! Construct the full URL.
            // The URI from the state contains the path and query from the deep link.
            // e.g., for 'myapp://auth?token=123', state.uri is '/auth?token=123'
            final Uri constructedUri = trustedUri.replace(
              path: state.uri.path,
              query: state.uri.query.isEmpty ? null : state.uri.query,
            );
            finalUrl = constructedUri.toString();
          }

          // Load the final URL in the WebView
          return WebViewScreen(url: finalUrl);
        },
      ),
    ],
    // Handle cases where the route is not found
    errorBuilder: (context, state) => const ErrorScreen(),
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
