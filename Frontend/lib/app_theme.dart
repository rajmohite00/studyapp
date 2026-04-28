import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Primary Brand ─────────────────────────────────────────
  static const primary = Color(0xFF2563EB);       // Bold Royal Blue
  static const primaryDark = Color(0xFF1D4ED8);   // Deep Blue
  static const primaryLight = Color(0xFFDBEAFE);  // Soft Blue tint

  // ── Accents ──────────────────────────────────────────────
  static const accent = Color(0xFFFF6B35);        // Energetic Orange
  static const accentGreen = Color(0xFF10B981);   // Emerald Green
  static const accentOrange = Color(0xFFF59E0B);  // Amber
  static const accentBlue = Color(0xFF0EA5E9);    // Sky Blue
  static const accentPurple = Color(0xFF8B5CF6);  // Violet
  static const accentTeal = Color(0xFF14B8A6);    // Teal

  // ── Backgrounds & Surfaces ───────────────────────────────
  static const background = Color(0xFFF5F7FA);    // Clean neutral white
  static const surface = Color(0xFFEEF2F7);       // Light blue-grey surface
  static const card = Color(0xFFFFFFFF);          // Pure white cards
  static const divider = Color(0xFFE2E8F0);       // Soft blue-grey divider

  // ── Dark Mode (not used, kept for safety) ────────────────
  static const darkBg = Color(0xFF0F172A);
  static const darkSurface = Color(0xFF1E293B);
  static const darkCard = Color(0xFF334155);

  // ── Text ─────────────────────────────────────────────────
  static const textPrimary = Color(0xFF0F172A);   // Dark slate
  static const textSecondary = Color(0xFF64748B); // Slate grey
  static const textLight = Color(0xFF94A3B8);     // Light slate

  // ── Gradient Presets ─────────────────────────────────────
  static const heroGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],  // Deep navy → Royal blue
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cardGradientBlue = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cardGradientGreen = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cardGradientOrange = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cardGradientPink = LinearGradient(
    colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Subject Colors ───────────────────────────────────────
  static const subjectColors = [
    Color(0xFF2563EB), // Royal Blue
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFFF6B35), // Orange
    Color(0xFF0EA5E9), // Sky Blue
    Color(0xFF8B5CF6), // Violet
    Color(0xFF14B8A6), // Teal
    Color(0xFFEC4899), // Pink
  ];
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          background: AppColors.background,
          surface: AppColors.card,
        ),
        scaffoldBackgroundColor: AppColors.background,
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
          shadowColor: AppColors.primary.withOpacity(0.08),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: const BorderSide(color: AppColors.primary, width: 2),
            textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
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
          indicatorColor: AppColors.primary.withOpacity(0.12),
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

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          surface: AppColors.darkSurface,
        ),
        scaffoldBackgroundColor: AppColors.darkBg,
        textTheme: GoogleFonts.outfitTextTheme().apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ).copyWith(
          displayLarge: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800),
          displayMedium: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800),
          displaySmall: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800),
          headlineLarge: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800),
          headlineMedium: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800),
          headlineSmall: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkCard,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: const BorderSide(color: Colors.white24, width: 2),
            textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurface,
          labelStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.white10),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.white10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.darkBg,
          indicatorColor: AppColors.primary.withValues(alpha: 0.12),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary);
            }
            return const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white54);
          }),
        ),
      );
}
