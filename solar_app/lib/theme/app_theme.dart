import 'package:flutter/material.dart';

class AppColors {
  static const Color ink = Color(0xFF19342D);
  static const Color muted = Color(0xFF5D7068);
  static const Color paper = Color(0xFFF6F4ED);
  static const Color cream = Color(0xFFEBE9DF);
  static const Color sun = Color(0xFFF4B942);
  static const Color coral = Color(0xFFE9785D);
  static const Color teal = Color(0xFF2B6E68);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkCard = Color(0xFF22423A);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: ColorScheme.light(
        primary: AppColors.ink,
        secondary: AppColors.sun,
        surface: AppColors.paper,
        error: AppColors.coral,
        onPrimary: AppColors.white,
        onSecondary: AppColors.ink,
        onSurface: AppColors.ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
          letterSpacing: -0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.ink,
        selectedItemColor: AppColors.sun,
        unselectedItemColor: AppColors.cream,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.cream, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.ink.withOpacity(0.15), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.ink, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      cardTheme: CardTheme(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.ink.withOpacity(0.08), width: 1),
        ),
      ),
    );
  }
}
