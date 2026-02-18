
import 'package:flutter/material.dart';
import 'package:myapp/web_view_screen.dart'; // Corrected import

void main() {
  // Ensure that Flutter bindings are initialized.
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multyclet',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // The app will now always start directly with the WebViewScreen.
      home: const WebViewScreen(url: "https://mediaflet.pp.ua"),
    );
  }
}
