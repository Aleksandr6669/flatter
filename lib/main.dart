
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'clock_screen.dart'; 
import 'overlay_widget.dart';

@pragma("vm:entry-point")
void overlayMain() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayWidget(),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ClockScreenWithButton(),
    );
  }
}

class ClockScreenWithButton extends StatelessWidget {
  const ClockScreenWithButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const ClockScreen(),
          Positioned(
            bottom: 20,
            left: 20,
            child: ElevatedButton(
              onPressed: () async {
                final bool? res = await FlutterOverlayWindow.requestPermission();
                if (res ?? false) {
                  await FlutterOverlayWindow.showOverlay(
                    height: 100,
                    width: 200,
                    alignment: OverlayAlignment.bottomRight,
                    flag: OverlayFlag.focusPointer,
                  );
                }
              },
              child: const Text('Показать оверлей'),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () async {
                 await FlutterOverlayWindow.closeOverlay();
              },
              child: const Text('Закрыть оверлей'),
            ),
          ),
        ],
      ),
    );
  }
}
