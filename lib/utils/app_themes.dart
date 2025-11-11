import 'package:flutter/material.dart';

class AppThemes {
  // light theme
  static final light = ThemeData(
    primaryColor: const Color(0xFF7F1618),
    primaryColorDark: const Color(0xFF141414),
    scaffoldBackgroundColor: Colors.white,
    brightness: Brightness.light,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
    ),
    colorScheme: ColorScheme.fromSeed(
      onBackground: const Color(0xFF7F1618),
      seedColor: const Color(0xFF7F1618),
      primary: const Color(0xFF7F1618),
      brightness: Brightness.light,
      surface: const Color(0xFF7F1618),
    ),
    cardColor: const Color(0xFF7E5555),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white,
    ),
  );

  // dark theme
  static final dark = ThemeData(
    primaryColor: const Color(0xFF7F1618),
    primaryColorDark: const Color(0xFF141414),
    scaffoldBackgroundColor: const Color(0xFF141414),
    brightness: Brightness.dark,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF7F1618),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    colorScheme: ColorScheme.fromSeed(
      onBackground: Colors.white,
      seedColor: const Color(0xFF7F1618),
      primary: const Color(0xFF7F1618),
      brightness: Brightness.dark,
      surface: const Color(0xFF7F1618),
    ),
    cardColor: const Color(0xFF7E5555),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white,
    ),
  );
}
