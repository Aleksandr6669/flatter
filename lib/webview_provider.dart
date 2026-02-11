import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewProvider with ChangeNotifier {
  bool _isVisible = false;
  String _url = '';
  WebViewController? _controller;

  bool get isVisible => _isVisible;
  String get url => _url;
  WebViewController? get controller => _controller;

  void setController(WebViewController controller) {
    _controller = controller;
  }

  void show(String url) {
    _url = url;
    _isVisible = true;
    _controller?.loadRequest(Uri.parse(url));
    notifyListeners();
  }

  void hide() {
    _isVisible = false;
    notifyListeners();
  }
}
