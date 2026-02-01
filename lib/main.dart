
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Filmix TV',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF161616),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF222222),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
        )
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final WebViewController _controller;
  int _currentIndex = 0;

  final List<String> _urls = [
    'https://filmix.tv',
    'https://filmix.tv/movie',
    'https://filmix.tv/series',
    'https://filmix.tv/search'
  ];

  @override
  void initState() {
    super.initState();

    const String mobileUserAgent =
        'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(mobileUserAgent)
      ..setBackgroundColor(const Color(0xFF161616))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            _controller.runJavaScript(
              """
              var style = document.createElement('style');
              style.id = 'adaptive-styles';
              style.type = 'text/css';
              var css = `
                body {
                  min-width: 320px !important;
                  background-color: #161616 !important;
                }
                .f-sidebar, .f-panel, #f-header-full-screen, .f-header__side.f-header__right, .f-auth-page__header-right {
                  display: none !important;
                }
                .f-main-wrap, .f-header, .custom-content {
                  padding-left: 10px !important;
                  padding-right: 10px !important;
                  padding-top: 5px !important;
                  margin-left: 0 !important;
                  width: 100% !important;
                }
                .f-header {
                  position: relative !important;
                  height: auto !important;
                  padding-bottom: 10px;
                }
                 .f-header__row {
                    padding: 5px !important;
                    display: flex;
                    flex-wrap: wrap;
                    justify-content: center !important;
                }
                 .f-header__left {
                    flex-grow: 1;
                    text-align: center;
                }
                .f-slider-intro {
                  min-height: auto !important;
                  padding-bottom: 1rem !important;
                }
                .f-intro__original-title .f-h1-display {
                  font-size: 2.2rem !important;
                }
                .f-intro__description {
                  max-width: 100% !important;
                  -webkit-line-clamp: 3 !important;
                }
                .f-slider__track {
                    display: grid;
                    grid-auto-flow: column;
                    grid-auto-columns: 45%;
                    overflow-x: auto;
                    scroll-snap-type: x mandatory;
                }
                .f-movie-card { width: 100% !important; scroll-snap-align: start; }
                .f-slider__inner { padding: 0; }
                .f-auth-page__content {
                    width: 100% !important;
                    max-width: 100%;
                    padding: 0 10px !important;
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    justify-content: center;
                    height: 80vh;
                }
                .f-auth-tabs, .f-auth-phone__body, .f-auth-tabs__item, .f-auth-form {
                    flex-direction: column;
                    align-items: center;
                    width: 100% !important;
                }
                .f-auth-phone__col { width: 100% !important; max-width: 320px; }
              `;
              var oldStyle = document.getElementById('adaptive-styles');
              if(oldStyle) { oldStyle.remove(); }
              style.innerHTML = css;
              document.head.appendChild(style);
              var meta = document.querySelector('meta[name="viewport"]');
              if(!meta){
                  meta = document.createElement('meta');
                  meta.name = 'viewport';
                  document.getElementsByTagName('head')[0].appendChild(meta);
              }
              meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
              """
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(_urls[_currentIndex]));
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _controller.loadRequest(Uri.parse(_urls[index]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false, // Prevent SafeArea from affecting the BottomNavigationBar
        child: WebViewWidget(controller: _controller),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Important for more than 3 items
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.movie),
            label: 'Фильмы',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tv),
            label: 'Сериалы',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Поиск',
          ),
        ],
      ),
    );
  }
}
