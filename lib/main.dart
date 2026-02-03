import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'dart:math';

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

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    CharacterScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
            child: _widgetOptions.elementAt(_selectedIndex),
          ),
          _buildGlassNavBar(), // Custom glass navigation bar
        ],
      ),
    );
  }

  Widget _buildGlassNavBar() {
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
              height: 65,
              width: double.infinity,
              child: LiquidGlass.withOwnLayer(
                settings: const LiquidGlassSettings(
                  blur: 10.0,
                  thickness: 15,
                  glassColor: Color(0x33FFFFFF),
                ),
                shape: LiquidRoundedSuperellipse(borderRadius: 25),
                child: Stack(
                  children: [
                    // The sliding glass indicator
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                      left: _selectedIndex * itemWidth,
                      top: 0,
                      height: 65,
                      width: itemWidth,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: LiquidGlass.withOwnLayer(
                          settings: const LiquidGlassSettings(
                            blur: 8.0,
                            thickness: 40,
                            glassColor: Color(0x4DFFFFFF),
                          ),
                          shape: LiquidRoundedSuperellipse(borderRadius: 21),
                          child: const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    // The navigation items on top
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(Icons.home, 'Главная', 0, itemWidth),
                        _buildNavItem(Icons.person, 'Персонаж', 1, itemWidth),
                        _buildNavItem(Icons.settings, 'Настройки', 2, itemWidth),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, double itemWidth) {
    final bool isSelected = _selectedIndex == index;
    final Color unselectedColor = Colors.white70;
    final Color selectedColor = Colors.amber[600]!;

    return SizedBox(
      width: itemWidth,
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animate the icon color
            TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: isSelected ? selectedColor : unselectedColor),
              duration: const Duration(milliseconds: 300),
              builder: (context, color, child) {
                return Icon(
                  icon,
                  color: color,
                  size: 28,
                );
              },
            ),
            const SizedBox(height: 2),
            // Animate the text style (color)
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: isSelected ? selectedColor : unselectedColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              child: Text(label),
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
