import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'mid_colors.dart';

abstract final class MidTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: MidColors.sand,
      colorScheme: ColorScheme.fromSeed(
        seedColor: MidColors.teal,
        primary: MidColors.teal,
        secondary: MidColors.coral,
        surface: MidColors.white,
        onPrimary: MidColors.white,
        onSecondary: MidColors.white,
        onSurface: MidColors.navy,
      ),
    );

    final textTheme = GoogleFonts.soraTextTheme(base.textTheme).apply(
      bodyColor: MidColors.navy,
      displayColor: MidColors.navy,
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: MidColors.white,
        foregroundColor: MidColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: MidColors.navy,
        ),
      ),
      cardTheme: CardThemeData(
        color: MidColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: MidColors.mist),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MidColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MidColors.mist),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MidColors.mist),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MidColors.teal, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: MidColors.teal,
          foregroundColor: MidColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: MidColors.navy,
        selectedIconTheme: IconThemeData(color: MidColors.white),
        unselectedIconTheme: IconThemeData(color: Color(0xFF9BB0C3)),
        selectedLabelTextStyle: TextStyle(color: MidColors.white),
        unselectedLabelTextStyle: TextStyle(color: Color(0xFF9BB0C3)),
        indicatorColor: MidColors.teal,
      ),
    );
  }
}
