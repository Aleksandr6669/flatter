import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

// Import the config model
import 'package:myapp/config_model.dart';

class WebViewScreen extends StatefulWidget {
  // Add config to the constructor
  const WebViewScreen({super.key, required this.config});

  final AppConfig config;

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _hasInternet = true;
  bool _isLoading = true;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _initializeWebView();
    _checkConnectivity();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();

    if (cameraStatus.isGranted && microphoneStatus.isGranted) {
      setState(() {
        _permissionsGranted = true;
      });
      if (_hasInternet) {
        // Use the URL from the config
        _controller.loadRequest(Uri.parse(widget.config.url));
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
        // Use the URL from the config
        _controller.loadRequest(Uri.parse(widget.config.url));
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

    if (controller.platform is WebKitWebViewPlatform) {
      (controller.platform as WebKitWebViewController).setInspectable(true);
    }

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
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) {
            return;
          }
          final bool canGoBack = await _controller.canGoBack();
          if (canGoBack) {
            _controller.goBack();
          }
        },
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
    );
  }
}
