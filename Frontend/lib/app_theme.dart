import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Neo-Brutalist / Cyber-Retro Palette
  static const primary = Color(0xFFFFD800); // Electric Yellow
  static const primaryDark = Color(0xFF050505); // True Black
  static const primaryLight = Color(0xFFFFF099); 

  // Accents
  static const accent = Color(0xFFFF006E); // Magenta Pink
  static const accentGreen = Color(0xFF06D6A0); // Mint Green
  static const accentOrange = Color(0xFFFF8B00); // Vibrant Orange
  static const accentPurple = Color(0xFF8338EC); // Deep Purple
  static const accentBlue = Color(0xFF3A86FF); // Azure Blue

  // Neutral (Backgrounds & Surfaces)
  static const surface = Color(0xFFF4F0EA); // Raw Paper / Cream (Fixes yellow blindness)
  static const card = Color(0xFFFFFFFF); // White cards
  static const divider = Color(0xFF050505); // Thick black dividers

  // Dark Mode
  static const darkBg = Color(0xFF111111);
  static const darkSurface = Color(0xFF1A1A1A);
  static const darkCard = Color(0xFF222222);

  // Text
  static const textPrimary = Color(0xFF050505); // Ink Black
  static const textSecondary = Color(0xFF4A4A4A); // Charcoal
  static const textLight = Color(0xFF888888);

  // Subject Colors (Bold Neo-Brutalist)
  static const subjectColors = [
    Color(0xFFF368A9), // Pink
    Color(0xFFD8B4FE), // Purple
    Color(0xFF4ADE80), // Green
    Color(0xFF60A5FA), // Blue
    Color(0xFFFB923C), // Orange
    Color(0xFFF87171), // Red
    Color(0xFF2DD4BF), // Teal
    Color(0xFFFDE047), // Light Yellow
  ];
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          background: AppColors.surface,
          surface: AppColors.card,
        ),
        scaffoldBackgroundColor: AppColors.surface,
        textTheme: GoogleFonts.outfitTextTheme().apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ).copyWith(
          displayLarge: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
          displayMedium: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
          displaySmall: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
          headlineLarge: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
          headlineMedium: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
          headlineSmall: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shadowColor: Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textPrimary,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: const BorderSide(color: AppColors.textPrimary, width: 2),
            textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Outfit'),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 24,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          indicatorColor: AppColors.primary.withOpacity(0.1),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary);
            }
            return const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary);
          }),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.primary;
            return Colors.transparent;
          }),
          side: const BorderSide(color: AppColors.divider, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      );
}
