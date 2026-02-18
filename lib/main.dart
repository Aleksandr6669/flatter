import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myapp/config_model.dart';
import 'package:myapp/web_view.dart';

Future<AppConfig> loadConfig() async {
  final configString = await rootBundle.loadString('assets/config.json');
  final configJson = jsonDecode(configString) as Map<String, dynamic>;
  return AppConfig.fromJson(configJson);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await loadConfig();
  runApp(MyApp(config: config));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: config.appName,
      home: WebViewScreen(config: config),
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
