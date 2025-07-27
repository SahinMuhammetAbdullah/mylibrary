import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    fontFamily: 'Georgia',
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8F6F0),
    primaryColor: const Color(0xFF8B4513), // SaddleBrown
    cardColor: const Color(0xFFFFFFFF),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFDFBF5),
      foregroundColor: Color(0xFF333333),
      elevation: 0.5,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(fontFamily: 'Georgia', fontSize: 20, color: Color(0xFF333333), fontWeight: FontWeight.bold),
    ),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF8B4513), // SaddleBrown
      secondary: Color(0xFFD2B48C), // Tan
      background: Color(0xFFF8F6F0),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF333333),
      onSecondary: Color(0xFF6B7280),
      error: Color(0xFFB00020),
      primaryContainer: Color(0xFFE5E7EB),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xFF333333)),
      titleMedium: TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.bold),
      bodySmall: TextStyle(color: Color(0xFF9CA3AF)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFFDFBF5),
      selectedItemColor: Color(0xFF8B4513),
      unselectedItemColor: Color(0xFF6B7280),
    )
  );

  static final ThemeData darkTheme = ThemeData(
    fontFamily: 'Georgia',
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    primaryColor: const Color(0xFFD2B48C), // Tan
    cardColor: const Color(0xFF1E1E1E),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Color(0xFFE0E0E0),
      elevation: 1,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(fontFamily: 'Georgia', fontSize: 20, color: Color(0xFFE0E0E0), fontWeight: FontWeight.bold),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFD2B48C), // Tan
      secondary: Color(0xFF8B4513), // SaddleBrown
      background: Color(0xFF121212),
      surface: Color(0xFF1E1E1E),
      onSurface: Color(0xFFE0E0E0),
      onSecondary: Color(0xFF9E9E9E),
      error: Color(0xFFCF6679),
      primaryContainer: Color(0xFF404040),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xFFE0E0E0)),
      titleMedium: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.bold),
      bodySmall: TextStyle(color: Color(0xFF9E9E9E)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: Color(0xFFD2B48C),
      unselectedItemColor: Color(0xFF9E9E9E),
    )
  );
}
