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
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    Color getItemColor(int index) {
                      if (index == _currentIndex) {
                        return Color.lerp(unselectedColor, selectedColor, _animation.value)!;
                      } else if (index == _previousIndex) {
                        return Color.lerp(selectedColor, unselectedColor, _animation.value)!;
                      } else {
                        return unselectedColor;
                      }
                    }

                    return Stack(
                      children: [
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

class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  final Map<String, double> _stats = {
    'Логика': 18,
    'Креативность': 12,
    'Скорость': 16,
    'Эмпатия': 14,
    'Точность': 17,
    'Память': 19,
    'Надежность': 20,
    'Адаптивность': 15,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 80.0, left: 20.0, right: 20.0, bottom: 100.0),
      child: Column(
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 24),
          ..._stats.entries.map((entry) {
            return _buildStatCard(entry.key, entry.value);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return SizedBox(
      width: double.infinity,
      child: LiquidGlass.withOwnLayer(
        settings: const LiquidGlassSettings(
          blur: 8.0,
          thickness: 10,
          glassColor: Color(0x2AFFFFFF),
        ),
        shape: LiquidRoundedSuperellipse(borderRadius: 20),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/viktoria_avatar.jpg'), // Using local asset
              ),
              const SizedBox(height: 20),
              const Text(
                'Viktoria',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Виртуальный ассистент',
                style: TextStyle(color: Colors.amber[200], fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: LiquidGlass.withOwnLayer(
          settings: const LiquidGlassSettings(
            blur: 8.0,
            thickness: 10,
            glassColor: Color(0x2AFFFFFF),
          ),
          shape: LiquidRoundedSuperellipse(borderRadius: 20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      value.round().toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(
                  height: 30,
                  child: Slider(
                    value: value,
                    min: 0,
                    max: 20,
                    divisions: 20,
                    label: value.round().toString(),
                    activeColor: Colors.amber[400],
                    inactiveColor: Colors.white.withOpacity(0.3),
                    onChanged: (newValue) {
                      setState(() {
                        _stats[label] = newValue;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
