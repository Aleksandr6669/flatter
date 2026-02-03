import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: Colors.lightBlue,
    brightness: Brightness.light,
    textTheme: GoogleFonts.poppinsTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.black87,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white.withAlpha(220),
    ),
    bottomAppBarTheme: const BottomAppBarThemeData( // Corrected to BottomAppBarThemeData
      color: Colors.transparent,
      elevation: 0,
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: Colors.lightBlue,
    brightness: Brightness.dark,
    textTheme: GoogleFonts.poppinsTextTheme().apply(bodyColor: Colors.white, displayColor: Colors.white),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.grey[850]?.withAlpha(220),
    ),
    bottomAppBarTheme: const BottomAppBarThemeData( // Corrected to BottomAppBarThemeData
      color: Colors.transparent,
      elevation: 0,
    ),
  );
}
