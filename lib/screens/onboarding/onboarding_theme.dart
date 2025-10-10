import 'package:flutter/material.dart';

class OnboardingTheme {
  // Colors matching DigitalBasics style
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color deepPurple = Color(0xFF1E1B4B);
  static const Color accentIndigo = Color(0xFF4F46E5);
  static const Color lightIndigo = Color(0xFF818CF8);
  static const Color indigoGlow = Color(0xFFE0E7FF);
  
  // Health-focused colors
  static const Color healthGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);
  
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
  
  // Neon glow effect
  static List<BoxShadow> neonGlow({Color color = accentIndigo}) {
    return [
      BoxShadow(
        color: Colors.white.withOpacity(0.5),
        blurRadius: 5,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: color.withOpacity(0.5),
        blurRadius: 10,
        spreadRadius: 0,
      ),
    ];
  }
  
  // Card decoration
  static BoxDecoration cardDecoration({bool withGlow = false}) {
    return BoxDecoration(
      color: Colors.black.withOpacity(0.4),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: accentIndigo.withOpacity(0.3),
        width: 1,
      ),
      boxShadow: withGlow ? neonGlow() : null,
    );
  }
  
  // Input decoration
  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    Widget? prefix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix,
      filled: true,
      fillColor: Colors.black.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: accentIndigo.withOpacity(0.5),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: accentIndigo.withOpacity(0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: accentIndigo,
          width: 2,
        ),
      ),
      labelStyle: TextStyle(
        color: indigoGlow.withOpacity(0.8),
      ),
      hintStyle: TextStyle(
        color: lightIndigo.withOpacity(0.5),
      ),
    );
  }
  
  // Button styles
  static ButtonStyle primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: accentIndigo,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      shadowColor: Colors.transparent,
    );
  }
  
  static ButtonStyle secondaryButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: BorderSide(
        color: accentIndigo.withOpacity(0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
  
  // Text styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    height: 1.2,
  );
  
  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    color: indigoGlow,
    height: 1.5,
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: indigoGlow,
    height: 1.6,
  );
  
  static TextStyle neonTextStyle({double fontSize = 32}) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      shadows: [
        Shadow(
          color: Colors.white.withOpacity(0.8),
          blurRadius: 5,
        ),
        Shadow(
          color: accentIndigo.withOpacity(0.8),
          blurRadius: 10,
        ),
      ],
    );
  }
}
