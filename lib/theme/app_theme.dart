import 'package:flutter/material.dart';

class AppTheme {
  // --- AÇIK TEMA ---
  static final ThemeData lightTheme = ThemeData(
    fontFamily: 'Georgia',
    brightness: Brightness.light,

    // Ana Renkler (CSS'den çeviri)
    scaffoldBackgroundColor: const Color(0xFFF8F6F0), // --bg-primary
    cardColor: const Color(0xFFFFFFFF),               // --bg-card
    dividerColor: const Color(0xFFE5E7EB),            // --border

    // AppBar Teması
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFFFFF),       // --bg-secondary (header)
      foregroundColor: Color(0xFF2C2C2C),     // --text-primary
      elevation: 1,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(fontFamily: 'Georgia', fontSize: 20, color: Color(0xFF2C2C2C), fontWeight: FontWeight.bold),
    ),

    // Modern Renk Şeması (ColorScheme)
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFD4AF37),             // --accent
      secondary: Color(0xFFF3E5AB),           // --accent-light
      background: Color(0xFFF8F6F0),          // --bg-primary
      surface: Color(0xFFFFFFFF),             // --bg-card & --bg-secondary
      onSurface: Color(0xFF2C2C2C),           // --text-primary
      onSecondary: Color(0xFF6B7280),         // --text-secondary
      error: Color(0xFFD97706),               // --warning
      primaryContainer: Color(0xFFE5E7EB),     // --border
    ),
    
    // Metin Temaları
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF2C2C2C)),   // --text-primary
      bodyMedium: TextStyle(color: Color(0xFF2C2C2C)),  // --text-primary
      titleMedium: TextStyle(color: Color(0xFF2C2C2C), fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: Color(0xFF2C2C2C), fontWeight: FontWeight.bold),
      bodySmall: TextStyle(color: Color(0xFF9CA3AF)),   // --text-muted
    ),

    // Bottom Navigation Teması
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFFFFFFF),       // --bg-card (nav)
      selectedItemColor: Color(0xFFD4AF37),       // --accent
      unselectedItemColor: Color(0xFF9CA3AF),     // --text-muted
    ),

    // Chip teması (Konular, Kişiler vb. için)
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF3E5AB).withOpacity(0.5), // --accent-light
      labelStyle: const TextStyle(color: Color(0xFFD4AF37)),
      side: BorderSide.none,
    ),
  );

  // --- KOYU TEMA ---
  static final ThemeData darkTheme = ThemeData(
    fontFamily: 'Georgia',
    brightness: Brightness.dark,

    // Ana Renkler
    scaffoldBackgroundColor: const Color(0xFF1A1A1A), // --bg-primary
    cardColor: const Color(0xFF2D2D2D),               // --bg-card
    dividerColor: const Color(0xFF404040),            // --border

    // AppBar Teması
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF262626),       // --bg-secondary
      foregroundColor: Color(0xFFF5F5F5),     // --text-primary
      elevation: 1,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(fontFamily: 'Georgia', fontSize: 20, color: Color(0xFFF5F5F5), fontWeight: FontWeight.bold),
    ),
    
    // Modern Renk Şeması (ColorScheme)
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFFFBBF24),                 // --accent
      secondary: const Color(0xFFFBBF24).withOpacity(0.2), // --accent-light
      background: const Color(0xFF1A1A1A),              // --bg-primary
      surface: const Color(0xFF2D2D2D),                 // --bg-card
      onSurface: const Color(0xFFF5F5F5),               // --text-primary
      onSecondary: const Color(0xFFD1D5DB),             // --text-secondary
      error: const Color(0xFFF59E0B),                   // --warning
      primaryContainer: const Color(0xFF404040),         // --border
    ),
    
    // Metin Temaları
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFF5F5F5)),
      bodyMedium: TextStyle(color: Color(0xFFF5F5F5)),
      titleMedium: TextStyle(color: Color(0xFFF5F5F5), fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: Color(0xFFF5F5F5), fontWeight: FontWeight.bold),
      bodySmall: TextStyle(color: Color(0xFF9CA3AF)),   // --text-muted
    ),

    // Bottom Navigation Teması
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF262626), // --bg-secondary (nav)
      selectedItemColor: Color(0xFFFBBF24),   // --accent
      unselectedItemColor: Color(0xFF9CA3AF), // --text-muted
    ),

    // Chip teması
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFFBBF24).withOpacity(0.2), // --accent-light
      labelStyle: const TextStyle(color: Color(0xFFFBBF24)),
      side: BorderSide.none,
    ),
  );
}
