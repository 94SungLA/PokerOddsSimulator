import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Slate Dark Theme Colors
  static const Color background = Color(0xFF07090E); // Deep matte black/blue
  static const Color surface = Color(0xFF0E131F);    // Sleek slate dark container
  static const Color cardBackground = Color(0xFF151C2C); // Card slot default background
  
  // Neon Gold/Amber Accents
  static const Color primary = Color(0xFFFFA000);   // Amber Gold
  static const Color accent = Color(0xFFFF6F00);    // Warm Gold
  
  // Table visual panels
  static const Color tableBgStart = Color(0xFF0F1424);
  static const Color tableBgEnd = Color(0xFF080B14);
  
  // Card Visuals (Modern Red & Slate Black)
  static const Color suitRed = Color(0xFFFF3B30);    // Vibrant Crimson Red
  static const Color suitBlack = Color(0xFF1E293B);  // Slate Dark Blue-Black
  
  // UI Element Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8F9CAE);
  static const Color border = Color(0xFF1F293D);
  static const Color borderActive = Color(0xFFFFA000);
  static const Color disabledCard = Color(0xFF131824);
  
  // Charts / Results Colors
  static const Color winColor = Color(0xFF34C759);   // Modern green
  static const Color tieColor = Color(0xFF8E8E93);   // Modern gray
  static const Color loseColor = Color(0xFFFF3B30);  // Modern red
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.cardBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: Colors.redAccent,
      ),
      dividerColor: AppColors.border,
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: AppColors.textPrimary, fontSize: 30, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 14),
          bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          labelLarge: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: const Color(0xFFF1F5F9), // Light slate gray background
      cardColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: Colors.white,
        error: Colors.redAccent,
      ),
      dividerColor: const Color(0xFFE2E8F0),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: Color(0xFF0F172A), fontSize: 30, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: Color(0xFF334155), fontSize: 14),
          bodyMedium: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          labelLarge: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
      useMaterial3: true,
    );
  }
}

