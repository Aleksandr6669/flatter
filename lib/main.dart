import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:myapp/gesture_overlay_view.dart';
import 'package:myapp/webview_provider.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU', null);
  runApp(
    ChangeNotifierProvider(
      create: (context) => WebViewProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: WeatherClockScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WeatherClockScreen extends StatefulWidget {
  const WeatherClockScreen({super.key});

  @override
  WeatherClockScreenState createState() => WeatherClockScreenState();
}

class WeatherClockScreenState extends State<WeatherClockScreen> {
  String _time = '';
  String _date = '';
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _updateTime();

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000));

    // Передаем контроллер в провайдер
    Provider.of<WebViewProvider>(context, listen: false)
        .setController(_webViewController);
  }

  void _updateTime() {
    final now = DateTime.now();
    final newTime = DateFormat('HH:mm').format(now);
    final newDate =
        DateFormat('EEEE, d MMMM yyyy', 'ru_RU').format(now).toUpperCase();

    if (newTime != _time || newDate != _date) {
      if (mounted) {
        setState(() {
          _time = newTime;
          _date = newDate;
        });
      }
    }
    Future.delayed(const Duration(seconds: 1), _updateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureOverlayView(
        webViewController: _webViewController,
        child: Stack(
          children: [
            // --- Основной контент (часы, иконки) ---
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildClockWidget(),
                      ],
                    ),
                    const SizedBox(height: 40),
                    _buildAppLauncher(),
                    const Spacer(),
                  ],
                ),
              ),
            ),

            // --- Слой WebView ---
            Consumer<WebViewProvider>(
              builder: (context, webViewProvider, child) {
                return Visibility(
                  visible: webViewProvider.isVisible,
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: WebViewWidget(controller: _webViewController),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClockWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          _time,
          style: const TextStyle(
              color: Colors.white, fontSize: 60, fontWeight: FontWeight.w200, height: 1.1),
        ),
        Text(
          _date,
          style: const TextStyle(
              color: Colors.white70, fontSize: 14, letterSpacing: 1.2),
        ),
      ],
    );
  }

  Widget _buildAppLauncher() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
             _buildAppIcon(context, 'FilmixTV', 'http://filmix.tv/msx/msx-logo.png', 'http://filmix.tv'),
            const SizedBox(width: 30),
            _buildAppIcon(context, 'LampaTV',
                'https://two-d-screen-62382642-9d450.web.app/icons/lampa-logo.svg',
                'http://lampa.mx/'),
            const SizedBox(width: 30),
            _buildAppIcon(context, 
                'LampaSTV',
                'https://two-d-screen-62382642-9d450.web.app/icons/lampa-logo.svg',
                'http://lampa.stream/'),
            const SizedBox(width: 30),
            _buildAppIcon(context, 'YoutubeTV',
                'https://www.gstatic.com/youtube/img/branding/favicon/favicon_144x144_v2.png',
                'https://www.youtube.com/tv'),
          ],
        ),
      ],
    );
  }

  Widget _buildAppIcon(BuildContext context, String name, String imageUrl, String url) {
    final isSvg = imageUrl.toLowerCase().endsWith('.svg');
    
    return Column(
      children: [
        GestureDetector(
          onTap: () {
             Provider.of<WebViewProvider>(context, listen: false).show(url);
          },
          child: Container(
            height: 60,
            width: 90,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(77),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: isSvg 
                  ? SvgPicture.network(
                      imageUrl, 
                      height: 40, 
                      width: 40,
                      fit: BoxFit.contain,
                    )
                  : Image.network(
                      imageUrl,
                      height: 40,
                      width: 40,
                      fit: BoxFit.contain,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        )
      ],
    );
  }
}
