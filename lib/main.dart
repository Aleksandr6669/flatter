import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'dart:math';
import 'dart:ui' show lerpDouble;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Simple App',
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _previousIndex = 0;
  late AnimationController _controller;
  late Animation<double> _animation;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    CharacterScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: const Text('Character App'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: _widgetOptions.elementAt(_currentIndex),
          ),
          _buildGlassNavBar(), // Custom glass navigation bar
        ],
      ),
    );
  }

  Widget _buildGlassNavBar() {
    const double navBarHeight = 65;
    final Color unselectedColor = Colors.white70;
    final Color selectedColor = Colors.amber[600]!;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20.0, left: 20, right: 20),
        child: LayoutBuilder( // Use LayoutBuilder for robust width calculation
          builder: (context, constraints) {
            final double navBarWidth = max(0, constraints.maxWidth);
            const int itemCount = 3;
            final double itemWidth = navBarWidth / itemCount;

            return SizedBox(
              height: navBarHeight,
              width: double.infinity,
              child: LiquidGlass.withOwnLayer(
                settings: const LiquidGlassSettings(
                  blur: 10.0,
                  thickness: 15,
                  glassColor: Color(0x33FFFFFF),
                ),
                shape: LiquidRoundedSuperellipse(borderRadius: 25),
                // The entire child is now an AnimatedBuilder for full sync
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    // --- Animation Value Calculations ---
                    // 1. Drop Position
                    final double startLeft = (_previousIndex * itemWidth) + (itemWidth / 2);
                    final double endLeft = (_currentIndex * itemWidth) + (itemWidth / 2);
                    final currentLeft = lerpDouble(startLeft, endLeft, _animation.value);

                    // 2. Drop Size (Pulse)
                    final double sizePulse = 0.2 * sin(_animation.value * pi);
                    final double baseSize = navBarHeight * 0.8;
                    final double currentSize = baseSize + (baseSize * sizePulse);

                    // 3. Item Color (Icon & Text)
                    Color getItemColor(int index) {
                      if (index == _currentIndex) {
                        return Color.lerp(unselectedColor, selectedColor, _animation.value)!;
                      } else if (index == _previousIndex) {
                        return Color.lerp(selectedColor, unselectedColor, _animation.value)!;
                      } else {
                        return unselectedColor;
                      }
                    }

                    // --- Build UI based on animated values ---
                    return Stack(
                      children: [
                        // Pulsing drop indicator
                        if (currentLeft != null)
                          Positioned(
                            left: currentLeft - (currentSize / 2),
                            top: (navBarHeight - currentSize) / 2,
                            width: currentSize,
                            height: currentSize,
                            child: LiquidGlass.withOwnLayer(
                              settings: const LiquidGlassSettings(
                                blur: 5.0,
                                thickness: 30,
                                glassColor: Color(0x4DFFFFFF),
                              ),
                              shape: LiquidRoundedSuperellipse(borderRadius: currentSize / 2), // Correct way to make a circle
                              child: const SizedBox.shrink(),
                            ),
                          ),
                        // Navigation items with animated colors
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildNavItem(Icons.home, 'Главная', 0, itemWidth, getItemColor(0)),
                            _buildNavItem(Icons.person, 'Персонаж', 1, itemWidth, getItemColor(1)),
                            _buildNavItem(Icons.settings, 'Настройки', 2, itemWidth, getItemColor(2)),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // This widget is now simpler, just rendering the state passed to it.
  Widget _buildNavItem(IconData icon, String label, int index, double itemWidth, Color color) {
    return SizedBox(
      width: itemWidth,
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Главный экран',
        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      width: 300,
      child: LiquidGlass.withOwnLayer(
        settings: const LiquidGlassSettings(
          blur: 10.0,
          thickness: 20,
          glassColor: Color(0x33FFFFFF),
        ),
        shape: LiquidRoundedSuperellipse(borderRadius: 30),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=a042581f4e29026704d'), // Placeholder avatar
              ),
              const SizedBox(height: 20),
              const Text(
                'Элара',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Уровень 12 | Волшебница',
                style: TextStyle(color: Colors.amber[200], fontSize: 16),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Сила', '10'),
                  _buildStatColumn('Ловкость', '14'),
                  _buildStatColumn('Интеллект', '18'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Экран настроек',
        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
