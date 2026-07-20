import 'package:flutter/material.dart';

/// AppTheme
/// Centralized dark theme definition for the Phone Parts Finder application.
/// Strictly dark-only with a black & gray color scheme.
class AppTheme {
  AppTheme._(); // Private constructor to prevent instantiation

  // Theme colors
  static const Color backgroundColor = Color(0xff121212); // Near-black
  static const Color surfaceColor = Color(0xff1E1E1E); // Dark gray
  static const Color primaryColor = Color(0xff9E9E9E); // Medium gray (accent/buttons)
  
  static const Color primaryTextColor = Color(0xffF5F5F5); // White/light gray
  static const Color secondaryTextColor = Color(0xffB0B0B0); // Medium light gray
  
  static const Color errorColor = Color(0xffCF6679); // Dark mode standard error color

  static ThemeData get appTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: surfaceColor,
      dialogTheme: const DialogThemeData(
        backgroundColor: surfaceColor,
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor,
        surface: surfaceColor,
        error: errorColor,
      ),

      // Text Theme
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: primaryTextColor),
        bodyMedium: TextStyle(color: secondaryTextColor),
        titleLarge: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold),
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: primaryTextColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black, // Dark text on gray button for contrast
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Form / Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        hintStyle: const TextStyle(color: secondaryTextColor),
        labelStyle: const TextStyle(color: secondaryTextColor),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
