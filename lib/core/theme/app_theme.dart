import 'package:flutter/material.dart';

/// AppTheme
/// Centralized modern mobile theme definition for the Phone Parts Finder application.
/// Clean, high-contrast light design system optimized for mobile displays.
class AppTheme {
  AppTheme._();

  // Color Tokens
  static const Color primaryColor = Color(0xff2563EB); // Tech Blue
  static const Color primaryDark = Color(0xff1E40AF);
  static const Color backgroundColor = Color(0xffFAFAFA); // Soft White
  static const Color surfaceColor = Color(0xffF1F5F9); // Light Slate Surface
  static const Color cardColor = Color(0xffFFFFFF); // Pure White Card
  static const Color primaryTextColor = Color(0xff0F172A); // Deep Slate Text
  static const Color secondaryTextColor = Color(0xff64748B); // Muted Slate Text
  static const Color borderColor = Color(0xffE2E8F0); // Light Slate Border
  static const Color errorColor = Color(0xffDC2626); // Clean Red
  static const Color successColor = Color(0xff16A34A); // Clean Green

  static ThemeData get appTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: surfaceColor,
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: primaryColor,
        surface: surfaceColor,
        error: errorColor,
      ),

      // Text Theme
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: primaryTextColor, fontSize: 16),
        bodyMedium: TextStyle(color: secondaryTextColor, fontSize: 14),
        titleLarge: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold, fontSize: 20),
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: cardColor,
        foregroundColor: primaryTextColor,
        elevation: 1,
        shadowColor: Color(0x1A000000),
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: primaryTextColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: primaryTextColor),
      ),

      // Button Theme (Mobile 48px+ touch targets)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: borderColor),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Form / Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        hintStyle: const TextStyle(color: secondaryTextColor, fontSize: 14),
        labelStyle: const TextStyle(color: secondaryTextColor, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 1,
        shadowColor: const Color(0x0F000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor),
        ),
      ),
    );
  }
}
