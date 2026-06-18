import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static bool _isDark = true;

  /// Call this from the root widget to sync the theme state.
  static void setTheme(BuildContext context) {
    _isDark = Theme.of(context).brightness == Brightness.dark;
  }

  // ── Background & Surface ──
  static Color get background =>
      _isDark ? const Color(0xFF07090E) : const Color(0xFFF1F5F9);
  static Color get surface =>
      _isDark ? const Color(0xFF0E131F) : const Color(0xFFFFFFFF);
  static Color get cardBackground =>
      _isDark ? const Color(0xFF151C2C) : const Color(0xFFF0F4FA);

  // ── Accent / Primary ──
  static const Color primary = Color(0xFFFFA000);
  static const Color accent = Color(0xFFFF6F00);

  // ── Table visuals ──
  static Color get tableBgStart =>
      _isDark ? const Color(0xFF0F1424) : const Color(0xFFE2E8F0);
  static Color get tableBgEnd =>
      _isDark ? const Color(0xFF080B14) : const Color(0xFFCBD5E1);

  // ── Card suit colours (stay fixed) ──
  static const Color suitRed = Color(0xFFFF3B30);
  static Color get suitBlack =>
      _isDark ? const Color(0xFF94A3B8) : const Color(0xFF1E293B);

  // ── Text ──
  static Color get textPrimary =>
      _isDark ? Colors.white : const Color(0xFF0F172A);
  static Color get textSecondary =>
      _isDark ? const Color(0xFF8F9CAE) : const Color(0xFF64748B);

  // ── Border ──
  static Color get border =>
      _isDark ? const Color(0xFF1F293D) : const Color(0xFFCBD5E1);
  static const Color borderActive = Color(0xFFFFA000);
  static Color get disabledCard =>
      _isDark ? const Color(0xFF131824) : const Color(0xFFE2E8F0);

  // ── Result colours (stay fixed) ──
  static const Color winColor = Color(0xFF34C759);
  static const Color tieColor = Color(0xFF8E8E93);
  static const Color loseColor = Color(0xFFFF3B30);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: const Color(0xFF07090E),
      cardColor: const Color(0xFF151C2C),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: Color(0xFF0E131F),
        error: Colors.redAccent,
      ),
      dividerColor: const Color(0xFF1F293D),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: Colors.white, fontSize: 14),
          bodyMedium: TextStyle(color: Color(0xFF8F9CAE), fontSize: 13),
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
      scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      cardColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: Colors.white,
        error: Colors.redAccent,
      ),
      dividerColor: const Color(0xFFCBD5E1),
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

