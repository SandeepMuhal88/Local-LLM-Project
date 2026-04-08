import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Dark Color Palette ───────────────────────────────────────────────────────
class DarkColors {
  static const Color bgDeep = Color(0xFF060810);
  static const Color bgBase = Color(0xFF0B0E1A);
  static const Color bgSurface = Color(0xFF111827);
  static const Color bgCard = Color(0xFF1A2235);
  static const Color bgInputBar = Color(0xFF0F1520);

  static const Color accentPrimary = Color(0xFF7C6FFF);
  static const Color accentSecondary = Color(0xFF00D9FF);
  static const Color accentTertiary = Color(0xFF9D4EDD);

  static const Color gradStart = Color(0xFF7C6FFF);
  static const Color gradMid = Color(0xFF9D4EDD);
  static const Color gradEnd = Color(0xFF00D9FF);

  static const Color userBubble = Color(0xFF1E1B4B);
  static const Color aiBubble = Color(0xFF131D2E);
  static const Color aiBubbleBorder = Color(0xFF1E3A5F);

  static const Color textPrimary = Color(0xFFF0F4FF);
  static const Color textSecondary = Color(0xFF8896AD);
  static const Color textMuted = Color(0xFF4A5568);

  static const Color success = Color(0xFF10D9A0);
  static const Color error = Color(0xFFFF5670);
  static const Color warning = Color(0xFFFFB830);

  static const Color drawerBg = Color(0xFF0D1220);
  static const Color drawerSurface = Color(0xFF141C2E);
}

// ─── Light Color Palette ──────────────────────────────────────────────────────
class LightColors {
  static const Color bgDeep = Color(0xFFEEF2FF);
  static const Color bgBase = Color(0xFFF5F7FF);
  static const Color bgSurface = Color(0xFFFFFFFF);
  static const Color bgCard = Color(0xFFF0F4FF);
  static const Color bgInputBar = Color(0xFFFFFFFF);

  static const Color accentPrimary = Color(0xFF6C63FF);
  static const Color accentSecondary = Color(0xFF0099CC);
  static const Color accentTertiary = Color(0xFF9D4EDD);

  static const Color gradStart = Color(0xFF6C63FF);
  static const Color gradMid = Color(0xFF9D4EDD);
  static const Color gradEnd = Color(0xFF0099CC);

  static const Color userBubble = Color(0xFF6C63FF);
  static const Color aiBubble = Color(0xFFFFFFFF);
  static const Color aiBubbleBorder = Color(0xFFDDE3F0);

  static const Color textPrimary = Color(0xFF1A1F36);
  static const Color textSecondary = Color(0xFF4A5270);
  static const Color textMuted = Color(0xFFAAB0C0);

  static const Color success = Color(0xFF0DB07D);
  static const Color error = Color(0xFFE53E3E);
  static const Color warning = Color(0xFFD97706);

  static const Color drawerBg = Color(0xFFEEF2FF);
  static const Color drawerSurface = Color(0xFFFFFFFF);
}

// ─── Unified interface (resolves based on brightness) ─────────────────────────
class AppColors {
  static bool _dark = true;
  static void init(bool isDark) => _dark = isDark;

  static Color get bgDeep => _dark ? DarkColors.bgDeep : LightColors.bgDeep;
  static Color get bgBase => _dark ? DarkColors.bgBase : LightColors.bgBase;
  static Color get bgSurface => _dark ? DarkColors.bgSurface : LightColors.bgSurface;
  static Color get bgCard => _dark ? DarkColors.bgCard : LightColors.bgCard;
  static Color get bgInputBar => _dark ? DarkColors.bgInputBar : LightColors.bgInputBar;

  static Color get accentPrimary => _dark ? DarkColors.accentPrimary : LightColors.accentPrimary;
  static Color get accentSecondary => _dark ? DarkColors.accentSecondary : LightColors.accentSecondary;
  static Color get accentTertiary => _dark ? DarkColors.accentTertiary : LightColors.accentTertiary;

  static Color get gradStart => _dark ? DarkColors.gradStart : LightColors.gradStart;
  static Color get gradEnd => _dark ? DarkColors.gradEnd : LightColors.gradEnd;

  static Color get aiBubble => _dark ? DarkColors.aiBubble : LightColors.aiBubble;
  static Color get aiBubbleBorder => _dark ? DarkColors.aiBubbleBorder : LightColors.aiBubbleBorder;

  static Color get textPrimary => _dark ? DarkColors.textPrimary : LightColors.textPrimary;
  static Color get textSecondary => _dark ? DarkColors.textSecondary : LightColors.textSecondary;
  static Color get textMuted => _dark ? DarkColors.textMuted : LightColors.textMuted;

  static Color get success => _dark ? DarkColors.success : LightColors.success;
  static Color get error => _dark ? DarkColors.error : LightColors.error;

  static Color get drawerBg => _dark ? DarkColors.drawerBg : LightColors.drawerBg;
  static Color get drawerSurface => _dark ? DarkColors.drawerSurface : LightColors.drawerSurface;
}

// ─── Theme Data ───────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get dark {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: DarkColors.bgBase,
      colorScheme: const ColorScheme.dark(
        primary: DarkColors.accentPrimary,
        secondary: DarkColors.accentSecondary,
        surface: DarkColors.bgSurface,
        error: DarkColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      drawerTheme: const DrawerThemeData(
        backgroundColor: DarkColors.drawerBg,
      ),
      dividerColor: DarkColors.aiBubbleBorder,
    );
  }

  static ThemeData get light {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: LightColors.bgBase,
      colorScheme: const ColorScheme.light(
        primary: LightColors.accentPrimary,
        secondary: LightColors.accentSecondary,
        surface: LightColors.bgSurface,
        error: LightColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      drawerTheme: const DrawerThemeData(
        backgroundColor: LightColors.drawerBg,
      ),
      dividerColor: LightColors.aiBubbleBorder,
    );
  }
}
