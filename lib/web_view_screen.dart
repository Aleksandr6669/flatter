
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';

// Import the core webview package
import 'package:webview_flutter/webview_flutter.dart';
// Import the Android-specific package
import 'package:webview_flutter_android/webview_flutter_android.dart';

class WebViewScreen extends StatefulWidget {
  final String url;

  const WebViewScreen({super.key, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _hasInternet = true;
  bool _isLoading = true; // To show a loading indicator

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _requestAllPermissions();
    await _initializeWebView();
    await _checkConnectivityAndLoad();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestAllPermissions() async {
    await [ 
      Permission.camera,
      Permission.microphone,
      Permission.locationWhenInUse,
    ].request();
  }

  Future<void> _initializeWebView() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
        ),
      );

    // CORRECTED: This is the modern and correct way to handle permission requests on Android.
    if (_controller.platform is AndroidWebViewController) {
      (_controller.platform as AndroidWebViewController)
          .setOnPlatformPermissionRequest(
        (PlatformWebViewPermissionRequest request) {
          request.grant();
        },
      );
    }
  }

  Future<void> _checkConnectivityAndLoad() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _updateConnectionStatus(connectivityResult, isInitialCheck: true);
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result, {bool isInitialCheck = false}) {
    final hasConnection = !result.contains(ConnectivityResult.none);
    if (mounted) {
      if (!isInitialCheck && hasConnection && !_isLoading) {
        _controller.loadRequest(Uri.parse(widget.url));
      }
      setState(() {
        _hasInternet = hasConnection;
        if (isInitialCheck && hasConnection) {
           _controller.loadRequest(Uri.parse(widget.url));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _hasInternet
                ? WebViewWidget(controller: _controller)
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, size: 80, color: Colors.grey),
                        SizedBox(height: 20),
                        Text(
                          'Нет подключения к интернету',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
