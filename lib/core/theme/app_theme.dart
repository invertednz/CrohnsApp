import 'package:flutter/material.dart';

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();
  
  // DigitalBasics inspired colors
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color deepPurple = Color(0xFF1E1B4B);
  static const Color accentIndigo = Color(0xFF4F46E5);
  static const Color lightIndigo = Color(0xFF818CF8);
  static const Color indigoGlow = Color(0xFFE0E7FF);
  
  // Semantic colors
  static const Color healthGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);
  
  // Legacy color mappings for compatibility
  static const Color primaryColor = accentIndigo;
  static const Color secondaryColor = lightIndigo;
  static const Color accentColor = healthGreen;
  static const Color neutralColor = Color(0xFFF3F4F6);
  static const Color backgroundColor = darkNavy;
  static const Color textColor = Colors.white;
  static const Color lightTextColor = indigoGlow;
  
  // Gradient backgrounds
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkNavy, deepPurple],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentIndigo, lightIndigo],
  );
  
  // Subtle shadow effect
  static List<BoxShadow> subtleShadow() {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];
  }
  
  // Card decoration
  static BoxDecoration cardDecoration({bool withShadow = false}) {
    return BoxDecoration(
      color: Colors.black.withOpacity(0.3),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: accentIndigo.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: withShadow ? subtleShadow() : null,
    );
  }
  
  // Light theme (now dark-themed)
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: accentIndigo,
    scaffoldBackgroundColor: darkNavy,
    colorScheme: const ColorScheme.dark(
      primary: accentIndigo,
      secondary: lightIndigo,
      tertiary: healthGreen,
      background: darkNavy,
      surface: deepPurple,
      error: errorRed,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.none,
      ),
      displayMedium: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.none,
      ),
      displaySmall: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.none,
      ),
      headlineMedium: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.none,
      ),
      headlineSmall: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.none,
      ),
      titleLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.none,
      ),
      titleMedium: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.none,
      ),
      titleSmall: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.none,
      ),
      bodyLarge: TextStyle(
        color: indigoGlow,
        decoration: TextDecoration.none,
      ),
      bodyMedium: TextStyle(
        color: indigoGlow,
        decoration: TextDecoration.none,
      ),
      bodySmall: TextStyle(
        color: indigoGlow,
        decoration: TextDecoration.none,
      ),
      labelLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.none,
      ),
      labelMedium: TextStyle(
        color: indigoGlow,
        decoration: TextDecoration.none,
      ),
      labelSmall: TextStyle(
        color: indigoGlow,
        decoration: TextDecoration.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentIndigo,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: accentIndigo.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: lightIndigo,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.black.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accentIndigo.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accentIndigo.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accentIndigo.withOpacity(0.6), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorRed, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorRed, width: 1.5),
      ),
      labelStyle: TextStyle(color: indigoGlow.withOpacity(0.8)),
      hintStyle: TextStyle(color: lightIndigo.withOpacity(0.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    cardTheme: CardTheme(
      color: Colors.black.withOpacity(0.4),
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: accentIndigo.withOpacity(0.3)),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: deepPurple,
      selectedItemColor: accentIndigo,
      unselectedItemColor: indigoGlow.withOpacity(0.6),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
  
  // Dark theme (same as light theme for consistency)
  static final ThemeData darkTheme = lightTheme;
}
