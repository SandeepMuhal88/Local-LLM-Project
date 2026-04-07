import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Background layers
  static const Color bgDeep = Color(0xFF060810);
  static const Color bgBase = Color(0xFF0B0E1A);
  static const Color bgSurface = Color(0xFF111827);
  static const Color bgCard = Color(0xFF1A2235);
  static const Color bgInputBar = Color(0xFF0F1520);

  // Accent - Electric Indigo / Cyan
  static const Color accentPrimary = Color(0xFF6C63FF);
  static const Color accentSecondary = Color(0xFF00D9FF);
  static const Color accentTertiary = Color(0xFF9D4EDD);

  // Gradient stops
  static const Color gradStart = Color(0xFF6C63FF);
  static const Color gradMid = Color(0xFF9D4EDD);
  static const Color gradEnd = Color(0xFF00D9FF);

  // User bubble
  static const Color userBubble = Color(0xFF1E1B4B);
  static const Color userBubbleBorder = Color(0xFF6C63FF);

  // AI bubble
  static const Color aiBubble = Color(0xFF131D2E);
  static const Color aiBubbleBorder = Color(0xFF1E3A5F);

  // Text
  static const Color textPrimary = Color(0xFFF0F4FF);
  static const Color textSecondary = Color(0xFF8896AD);
  static const Color textMuted = Color(0xFF4A5568);

  // Status
  static const Color success = Color(0xFF10D9A0);
  static const Color error = Color(0xFFFF5670);
  static const Color warning = Color(0xFFFFB830);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.bgBase,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentPrimary,
        secondary: AppColors.accentSecondary,
        surface: AppColors.bgSurface,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        bodyLarge: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
        titleLarge: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.aiBubbleBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.aiBubbleBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accentPrimary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
