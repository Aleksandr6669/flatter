import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:myapp/webview_provider.dart';

class AssistantOverlay extends StatefulWidget {
  const AssistantOverlay({super.key});

  @override
  State<AssistantOverlay> createState() => _AssistantOverlayState();
}

class _AssistantOverlayState extends State<AssistantOverlay> with TickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechInitialized = false;
  final List<Map<String, String>> _conversation = [];
  bool _conversationVisible = false;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late AnimationController _shimmerController;
  bool _isRecognizing = false;

   @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initSpeech();
    }
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shimmerController = AnimationController(
        vsync: this, 
        duration: const Duration(seconds: 2)
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _speechToText.stop();
    _scrollController.dispose();
    _animationController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _initSpeech() async {
    _speechInitialized = await _speechToText.initialize(
      onStatus: (status) {
        if (mounted) {
          setState(() {});
        }

        if (!kIsWeb &&
            (status == SpeechToText.notListeningStatus ||
                status == SpeechToText.doneStatus)) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _startListening();
          });
        }
      },
    );
    if (_speechInitialized) {
      _startListening();
    }
  }

  void _startListening() {
    if (!_speechInitialized || _speechToText.isListening) return;
    _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: 'ru_RU',
      listenFor: const Duration(minutes: 5),
    );
    if (mounted) {
      setState(() {});
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (result.finalResult) {
      String recognizedText = result.recognizedWords;
      if (recognizedText.toLowerCase().contains('вика')) {
        setState(() {
          _isRecognizing = true;
          _animationController.forward(from: 0).whenComplete(() {
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                setState(() {
                  _isRecognizing = false;
                });
              }
            });
          });

          if (!_conversationVisible) {
            _conversationVisible = true;
          }
          _conversation.add({'speaker': 'user', 'text': recognizedText});
          _processCommand(recognizedText);
        });
      }
    }
  }

  void _processCommand(String command) {
    String response = "Я вас не совсем поняла.";
    final lowerCaseCommand = command.toLowerCase();
    final webViewProvider = Provider.of<WebViewProvider>(context, listen: false);

    if (lowerCaseCommand.contains('погода')) {
      response = "Погоду я пока не умею показывать, но скоро научусь!";
    } else if (lowerCaseCommand.contains('привет')) {
      response = "Привет! Чем могу помочь?";
    } else if (lowerCaseCommand.contains('открой filmix')) {
      webViewProvider.show("http://filmix.tv");
      response = "Открываю FilmixTV";
    } else if (lowerCaseCommand.contains('открой lampa')) {
      webViewProvider.show("http://lampa.mx/");
      response = "Открываю LampaTV";
    } else if (lowerCaseCommand.contains('открой lampa stv')) {
      webViewProvider.show("http://lampa.stream/");
      response = "Открываю LampaSTV";
    } else if (lowerCaseCommand.contains('открой youtube')) {
      webViewProvider.show("https://www.youtube.com/tv");
      response = "Открываю YoutubeTV";
    } else if (lowerCaseCommand.contains('закрой') || lowerCaseCommand.contains('сверни')) {
      webViewProvider.hide();
      response = "Готово!";
    }

    setState(() {
        _conversation.add({'speaker': 'assistant', 'text': response});
        _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
         if (_conversationVisible)
          Positioned(
            bottom: 80,
            right: 40,
            child: _buildAssistantUI(),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: _buildAssistantIcon(),
          ),
      ],
    );
  }

   Widget _buildAssistantIcon() {
    return ScaleTransition(
      scale: _isRecognizing
          ? Tween<double>(begin: 1.0, end: 1.5).animate(_animationController)
          : const AlwaysStoppedAnimation(1.0),
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: const [
                  Color(0xFF4B0082),
                  Color(0xFF0000FF),
                  Color(0xFF8A2BE2),
                ],
                stops: [
                  _shimmerController.value - 0.5,
                  _shimmerController.value,
                  _shimmerController.value + 0.5,
                ],
                tileMode: TileMode.repeated,
              ).createShader(bounds);
            },
            child: child,
          );
        },
        child: SizedBox(
          width: 60,
          height: 60,
          child: SvgPicture.asset(
            'assets/icons/assistant_icon_star.svg',
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantUI() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400, maxWidth: 350),
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2B3A52).withAlpha(102),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(51))
        ),
         child: ClipRRect(
           borderRadius: BorderRadius.circular(16),
           child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _conversation.length,
              itemBuilder: (context, index) {
                final message = _conversation[index];
                final bool isUser = message['speaker'] == 'user';

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.blue.withAlpha(128)
                          : Colors.grey.withAlpha(77),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message['text']!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                );
              },
            ),
                 ),
        ),
      ),
    );
  }
}
