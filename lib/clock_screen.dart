import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import the SVG package
import 'package:intl/intl.dart';
import 'webview_screen.dart'; // Import the WebView screen

class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  late DateTime _currentTime;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String formattedTime = DateFormat('HH:mm').format(_currentTime);
    final String formattedDate = DateFormat('d MMMM yyyy, EEEE', 'ru_RU').format(_currentTime);

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Centered Launcher Tile
          Center(
            child: _buildTile(
              context,
              title: 'Lampa.mx',
              iconPath: 'assets/icons/lampa.svg', // Path to the SVG icon
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WebViewScreen(url: 'http://lampa.mx/'),
                  ),
                );
              },
            ),
          ),

          // Top-right Clock Display
          Positioned(
            top: 60,
            right: 55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formattedTime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 90,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(blurRadius: 12.0, color: Colors.black87, offset: Offset(2.0, 2.0)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(blurRadius: 8.0, color: Colors.black54, offset: Offset(1.0, 1.0)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tile widget for the launcher
  Widget _buildTile(BuildContext context, {required String title, required String iconPath, required VoidCallback onTap}) {
    return FocusableActionDetector(
      onFocusChange: (hasFocus) {
        // This is where you could add visual feedback for focus, e.g., changing the border color.
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 300, // Fixed width for the tile
          height: 250, // Fixed height for the tile
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(4, 4),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Use SvgPicture.asset to display the SVG icon
              SvgPicture.asset(
                iconPath,
                width: 80,
                height: 80,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn), // Keep the icon white
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
