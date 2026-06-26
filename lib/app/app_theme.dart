import 'package:flutter/material.dart';

class AppTheme {
  static const background = Color(0xFF09111B);
  static const backgroundSoft = Color(0xFF101B28);
  static const surface = Color(0xFF121C28);
  static const surfaceRaised = Color(0xFF172331);
  static const outline = Color(0xFF243344);
  static const mint = Color(0xFF35D0BD);
  static const mintSoft = Color(0xFF6DE8D8);
  static const pink = Color(0xFFE45CA6);
  static const amber = Color(0xFFF6B24D);
  static const danger = Color(0xFFFF6D72);
  static const success = Color(0xFF44D884);

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: mint,
      secondary: mintSoft,
      surface: surface,
      onSurface: Colors.white,
      error: danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      splashFactory: NoSplash.splashFactory,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.1,
          height: 1.02,
        ),
        headlineMedium: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          height: 1.05,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(
          fontSize: 15,
          color: Color(0xFFBECCD9),
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: Color(0xFF9CB0C2),
          height: 1.4,
        ),
        labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: const BorderSide(color: outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: Color(0xFF70869A)),
        labelStyle: const TextStyle(color: Color(0xFF9CB0C2)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: mint, width: 1.2),
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      dividerColor: outline,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: mint,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(58),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(58),
          foregroundColor: Colors.white,
          side: const BorderSide(color: outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceRaised,
        selectedColor: mint,
        side: const BorderSide(color: outline),
        disabledColor: surfaceRaised,
        labelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}
