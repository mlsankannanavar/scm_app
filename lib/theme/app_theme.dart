import 'package:flutter/material.dart';

class AppTheme {
  // Color scheme based on provided CSS variables
  static const Color primaryColor = Color(0xFFFFFFFF);      // --primary-color: #FFFFFF
  static const Color primaryHover = Color(0xFFF0F0F0);      // --primary-hover: #F0F0F0
  static const Color secondaryColor = Color(0xFF2196F3);    // --secondary-color: #2196F3
  static const Color successColor = Color(0xFF10B981);      // --success-color: #10b981
  static const Color errorColor = Color(0xFFEF4444);        // --error-color: #ef4444
  static const Color backgroundColor = Color(0xFFF5F5F5);   // --background-color: #f5f5f5
  static const Color textColor = Color(0xFF000000);         // --text-color: #000000
  static const Color buttonColor = Color(0xFFF8BBD0);       // --button-color: #F8BBD0
  static const Color buttonHover = Color(0xFFF48FB1);       // --button-hover: #F48FB1
  static const Color borderColor = Color(0xFFE5E7EB);       // --border-color: #e5e7eb
  static const Color warningColor = Color(0xFFF59E0B);      // --warning-color: #f59e0b
  
  static const double borderRadius = 8.0;                   // --border-radius: 8px

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: secondaryColor,
      brightness: Brightness.light,
      primary: secondaryColor,
      secondary: buttonColor,
      surface: primaryColor,
      background: backgroundColor,
      error: errorColor,
      onPrimary: primaryColor,
      onSecondary: textColor,
      onSurface: textColor,
      onBackground: textColor,
      onError: primaryColor,
    ),
    
    // App Bar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: textColor,
      elevation: 2,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Card Theme
    cardTheme: CardTheme(
      color: primaryColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: const BorderSide(color: borderColor, width: 1),
      ),
      shadowColor: Colors.black.withOpacity(0.1),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textColor,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: secondaryColor,
        side: const BorderSide(color: secondaryColor, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: secondaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: primaryColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: secondaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),

    // Dialog Theme
    dialogTheme: DialogTheme(
      backgroundColor: primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius * 2),
      ),
      elevation: 8,
      titleTextStyle: const TextStyle(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: const TextStyle(
        color: textColor,
        fontSize: 16,
      ),
    ),

    // Scaffold Background
    scaffoldBackgroundColor: backgroundColor,

    // Text Theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: textColor, fontWeight: FontWeight.w300),
      displayMedium: TextStyle(color: textColor, fontWeight: FontWeight.w400),
      displaySmall: TextStyle(color: textColor, fontWeight: FontWeight.w400),
      headlineLarge: TextStyle(color: textColor, fontWeight: FontWeight.w400),
      headlineMedium: TextStyle(color: textColor, fontWeight: FontWeight.w400),
      headlineSmall: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      titleLarge: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      titleMedium: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: textColor, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(color: textColor, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(color: textColor, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(color: textColor, fontWeight: FontWeight.w500),
    ),
  );

  // Status indicator colors
  static Color statusColor(bool isConnected) {
    return isConnected ? successColor : errorColor;
  }

  // Button variants
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: buttonColor,
    foregroundColor: textColor,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
  );

  static ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: secondaryColor,
    side: const BorderSide(color: secondaryColor, width: 2),
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
  );

  static ButtonStyle successButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: successColor,
    foregroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
  );

  static ButtonStyle errorButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: errorColor,
    foregroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
  );
}
