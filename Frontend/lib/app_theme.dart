import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Primary — Purple/Indigo (matches design) ──────────────
  static const primary       = Color(0xFF5B4CDB);   // Purple
  static const primaryDark   = Color(0xFF4338CA);   // Deep indigo
  static const primaryLight  = Color(0xFFEDE9FE);   // Soft lavender

  // ── Accents ──────────────────────────────────────────────
  static const accent        = Color(0xFFFF6B35);
  static const accentGreen   = Color(0xFF10B981);
  static const accentOrange  = Color(0xFFF59E0B);
  static const accentBlue    = Color(0xFF0EA5E9);
  static const accentPurple  = Color(0xFF8B5CF6);
  static const accentTeal    = Color(0xFF14B8A6);

  // ── Backgrounds ──────────────────────────────────────────
  static const background    = Color(0xFFF8F8FB);
  static const surface       = Color(0xFFF0EEF8);
  static const card          = Color(0xFFFFFFFF);
  static const divider       = Color(0xFFE8E6F0);

  // ── Dark (unused) ─────────────────────────────────────────
  static const darkBg        = Color(0xFF0F0E17);
  static const darkSurface   = Color(0xFF1C1A2E);
  static const darkCard      = Color(0xFF2A2840);

  // ── Text ──────────────────────────────────────────────────
  static const textPrimary   = Color(0xFF1A1730);
  static const textSecondary = Color(0xFF6B6880);
  static const textLight     = Color(0xFFB0AEC0);

  // ── Gradients ─────────────────────────────────────────────
  static const heroGradient = LinearGradient(
    colors: [Color(0xFF5B4CDB), Color(0xFF7C6FE8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cardGradientGreen = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const subjectColors = [
    Color(0xFF5B4CDB),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFFF6B35),
    Color(0xFF0EA5E9),
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
    Color(0xFFEC4899),
  ];
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          surface: AppColors.card,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: GoogleFonts.inter().fontFamily,
        textTheme: GoogleFonts.interTextTheme().apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent),
          side: const BorderSide(color: AppColors.divider, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          surface: AppColors.darkCard,
        ),
        scaffoldBackgroundColor: AppColors.darkBg,
        fontFamily: GoogleFonts.inter().fontFamily,
        textTheme: GoogleFonts.interTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ).apply(
          bodyColor: const Color(0xFFE8E6F8),
          displayColor: const Color(0xFFE8E6F8),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkSurface,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Color(0xFFE8E6F8)),
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkCard,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3A3850)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3A3850)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: const TextStyle(color: Color(0xFF6B6880), fontSize: 14),
        ),
        dividerColor: const Color(0xFF2E2C42),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent),
          side: const BorderSide(color: Color(0xFF3A3850), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      );
}
