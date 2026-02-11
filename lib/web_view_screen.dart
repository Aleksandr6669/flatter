import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _hasInternet = true;
  bool _isLoading = true;
  bool _permissionsGranted = false;
  String _handTrackingJs = "";

  final String _initialUrl = 'https://mediaflet.pp.ua/'; // Starting page
  final String _handTrackingScriptUrl = 'https://mediaflet.pp.ua/hand-tracking.js'; // Static script URL

  @override
  void initState() {
    super.initState();
    _loadHandTrackingJs();
    _requestPermissions();
    _initializeWebView();
    _checkConnectivity();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _loadHandTrackingJs() async {
    try {
      final response = await http.get(Uri.parse(_handTrackingScriptUrl));
      if (response.statusCode == 200) {
        setState(() {
          _handTrackingJs = response.body;
        });
      }
    } catch (e) {
      debugPrint("Failed to load hand tracking script: $e");
      // Handle script loading failure
    }
  }

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();

    if (cameraStatus.isGranted && microphoneStatus.isGranted) {
      setState(() {
        _permissionsGranted = true;
      });
      if (_hasInternet) {
        _controller.loadRequest(Uri.parse(_initialUrl));
      }
    } else {
      // Handle the case where permissions are denied
    }
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _updateConnectionStatus(connectivityResult);
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    final hasConnection = result.isNotEmpty && result.first != ConnectivityResult.none;
    if (mounted) {
      setState(() {
        _hasInternet = hasConnection;
      });
      if (_hasInternet && _permissionsGranted) {
        _controller.loadRequest(Uri.parse(_initialUrl));
      }
    }
  }

  void _initializeWebView() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            if (_handTrackingJs.isNotEmpty) {
              _controller.runJavaScript(_handTrackingJs);
            }
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''Page resource error:
              code: ${error.errorCode}
              description: ${error.description}
              errorType: ${error.errorType}
              isForMainFrame: ${error.isForMainFrame}
            ''');
          },
        ),
      )
      ..addJavaScriptChannel(
        'Toaster',
        onMessageReceived: (JavaScriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        },
      );

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      final androidController = controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
      androidController.setOnPlatformPermissionRequest(
        (PlatformWebViewPermissionRequest request) {
          if (request.types.contains(WebViewPermissionResourceType.camera) ||
              request.types.contains(WebViewPermissionResourceType.microphone)) {
            request.grant();
          } else {
            request.deny();
          }
        },
      );
    }

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) {
            return;
          }
          final bool canGoBack = await _controller.canGoBack();
          if (canGoBack) {
            _controller.goBack();
          }
        },
        child: SafeArea(
          child: _permissionsGranted
              ? _hasInternet
                  ? Stack(
                      children: [
                        WebViewWidget(controller: _controller),
                        if (_isLoading)
                          const Center(
                            child: CircularProgressIndicator(),
                          ),
                      ],
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off, size: 64),
                          SizedBox(height: 16),
                          Text('Нет подключения к интернету'),
                        ],
                      ),
                    )
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64),
                      SizedBox(height: 16),
                      Text('Необходимы разрешения для доступа к камере и микрофону.'),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
