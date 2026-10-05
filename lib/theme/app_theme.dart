import 'package:flutter/material.dart';

class AppTheme {
  // Application Color Palette
  static const Color background = Color(0xFFFBFBFA);
  static const Color cardBg = Colors.white;
  static const Color sidebarBg = Color(0xFFF7F6F3);
  static const Color border = Color(0xFFE9E9E7);
  static const Color textPrimary = Color(0xFF37352F);
  static const Color textSecondary = Color(0xFF787774);
  static const Color primaryAccent = Color(0xFF2EAADC);

  // Soft Pastel Tag Colors
  static const Color tagGrayBg = Color(0xFFF1F1EF);
  static const Color tagGrayText = Color(0xFF5A5A58);

  static const Color tagBlueBg = Color(0xFFE8F3F8);
  static const Color tagBlueText = Color(0xFF1D6F93);

  static const Color tagGreenBg = Color(0xFFEDF3EC);
  static const Color tagGreenText = Color(0xFF2B593F);

  static const Color tagYellowBg = Color(0xFFFBF3DB);
  static const Color tagYellowText = Color(0xFF89632A);

  static const Color tagOrangeBg = Color(0xFFFAEBDD);
  static const Color tagOrangeText = Color(0xFF854C1D);

  static const Color tagRedBg = Color(0xFFFDEBEC);
  static const Color tagRedText = Color(0xFF9F2B2B);

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: textPrimary,
        primary: textPrimary,
        surface: cardBg,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tagGrayBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: textPrimary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
      ),
    );
  }
}
