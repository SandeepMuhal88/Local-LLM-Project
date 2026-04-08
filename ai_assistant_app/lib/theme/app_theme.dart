import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Dark Color Palette (Gemini-inspired) ──────────────────────────────────────
class DarkColors {
  static const Color bgDeep    = Color(0xFF0A0A0F);
  static const Color bgBase    = Color(0xFF0F0F17);
  static const Color bgSurface = Color(0xFF1A1A2E);
  static const Color bgCard    = Color(0xFF16213E);
  static const Color bgInputBar= Color(0xFF0D0D1A);
  static const Color bgGlass   = Color(0x1AFFFFFF);

  // Gemini standard: Blue-purple + teal
  static const Color accentPrimary   = Color(0xFF4A90D9); // Google blue
  static const Color accentSecondary = Color(0xFF8B5CF6); // Purple
  static const Color accentTertiary  = Color(0xFF06B6D4); // Cyan/Teal
  static const Color accentGold      = Color(0xFFF59E0B); // Amber

  static const Color gradStart = Color(0xFF4A90D9);
  static const Color gradMid   = Color(0xFF8B5CF6);
  static const Color gradEnd   = Color(0xFF06B6D4);

  static const Color userBubble        = Color(0xFF1E3A5F);
  static const Color aiBubble          = Color(0xFF111827);
  static const Color aiBubbleBorder    = Color(0xFF1E293B);
  static const Color glassBorder       = Color(0x22FFFFFF);

  static const Color textPrimary   = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted     = Color(0xFF475569);

  static const Color success = Color(0xFF10B981);
  static const Color error   = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  static const Color drawerBg      = Color(0xFF0C0C18);
  static const Color drawerSurface = Color(0xFF141428);
  static const Color divider       = Color(0xFF1E293B);
}

// ─── Light Color Palette ──────────────────────────────────────────────────────
class LightColors {
  static const Color bgDeep    = Color(0xFFE8EFF8);
  static const Color bgBase    = Color(0xFFF0F4FC);
  static const Color bgSurface = Color(0xFFFFFFFF);
  static const Color bgCard    = Color(0xFFF8FAFF);
  static const Color bgInputBar= Color(0xFFFFFFFF);
  static const Color bgGlass   = Color(0x1A4A90D9);

  static const Color accentPrimary   = Color(0xFF2563EB); // Google blue
  static const Color accentSecondary = Color(0xFF7C3AED); // Purple
  static const Color accentTertiary  = Color(0xFF0891B2); // Cyan
  static const Color accentGold      = Color(0xFFD97706); // Amber

  static const Color gradStart = Color(0xFF2563EB);
  static const Color gradMid   = Color(0xFF7C3AED);
  static const Color gradEnd   = Color(0xFF0891B2);

  static const Color userBubble     = Color(0xFF2563EB);
  static const Color aiBubble       = Color(0xFFFFFFFF);
  static const Color aiBubbleBorder = Color(0xFFE2E8F0);
  static const Color glassBorder    = Color(0x222563EB);

  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted     = Color(0xFFCBD5E1);

  static const Color success = Color(0xFF059669);
  static const Color error   = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);

  static const Color drawerBg      = Color(0xFFEEF2FF);
  static const Color drawerSurface = Color(0xFFFFFFFF);
  static const Color divider       = Color(0xFFE2E8F0);
}

// ─── Unified interface ────────────────────────────────────────────────────────
class AppColors {
  static bool _dark = true;
  static void init(bool isDark) => _dark = isDark;

  static Color get bgDeep      => _dark ? DarkColors.bgDeep      : LightColors.bgDeep;
  static Color get bgBase      => _dark ? DarkColors.bgBase      : LightColors.bgBase;
  static Color get bgSurface   => _dark ? DarkColors.bgSurface   : LightColors.bgSurface;
  static Color get bgCard      => _dark ? DarkColors.bgCard      : LightColors.bgCard;
  static Color get bgInputBar  => _dark ? DarkColors.bgInputBar  : LightColors.bgInputBar;
  static Color get bgGlass     => _dark ? DarkColors.bgGlass     : LightColors.bgGlass;

  static Color get accentPrimary   => _dark ? DarkColors.accentPrimary   : LightColors.accentPrimary;
  static Color get accentSecondary => _dark ? DarkColors.accentSecondary : LightColors.accentSecondary;
  static Color get accentTertiary  => _dark ? DarkColors.accentTertiary  : LightColors.accentTertiary;
  static Color get accentGold      => _dark ? DarkColors.accentGold      : LightColors.accentGold;

  static Color get gradStart => _dark ? DarkColors.gradStart : LightColors.gradStart;
  static Color get gradMid   => _dark ? DarkColors.gradMid   : LightColors.gradMid;
  static Color get gradEnd   => _dark ? DarkColors.gradEnd   : LightColors.gradEnd;

  static Color get aiBubble       => _dark ? DarkColors.aiBubble       : LightColors.aiBubble;
  static Color get aiBubbleBorder => _dark ? DarkColors.aiBubbleBorder : LightColors.aiBubbleBorder;
  static Color get glassBorder    => _dark ? DarkColors.glassBorder    : LightColors.glassBorder;

  static Color get textPrimary   => _dark ? DarkColors.textPrimary   : LightColors.textPrimary;
  static Color get textSecondary => _dark ? DarkColors.textSecondary : LightColors.textSecondary;
  static Color get textMuted     => _dark ? DarkColors.textMuted     : LightColors.textMuted;

  static Color get success => _dark ? DarkColors.success : LightColors.success;
  static Color get error   => _dark ? DarkColors.error   : LightColors.error;
  static Color get warning => _dark ? DarkColors.warning : LightColors.warning;

  static Color get drawerBg      => _dark ? DarkColors.drawerBg      : LightColors.drawerBg;
  static Color get drawerSurface => _dark ? DarkColors.drawerSurface : LightColors.drawerSurface;
  static Color get divider       => _dark ? DarkColors.divider       : LightColors.divider;

  // Gradient helpers
  static List<Color> get primaryGradient => [gradStart, gradMid, gradEnd];
  static List<Color> get subtleGradient  => [gradStart.withValues(alpha: 0.8), gradEnd.withValues(alpha: 0.8)];
}

// ─── Theme Data ───────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get dark {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: DarkColors.bgBase,
      colorScheme: const ColorScheme.dark(
        primary: DarkColors.accentPrimary,
        secondary: DarkColors.accentSecondary,
        tertiary: DarkColors.accentTertiary,
        surface: DarkColors.bgSurface,
        error: DarkColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      drawerTheme: const DrawerThemeData(
        backgroundColor: DarkColors.drawerBg,
      ),
      dividerColor: DarkColors.divider,
      cardColor: DarkColors.bgCard,
    );
  }

  static ThemeData get light {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: LightColors.bgBase,
      colorScheme: const ColorScheme.light(
        primary: LightColors.accentPrimary,
        secondary: LightColors.accentSecondary,
        tertiary: LightColors.accentTertiary,
        surface: LightColors.bgSurface,
        error: LightColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      drawerTheme: const DrawerThemeData(
        backgroundColor: LightColors.drawerBg,
      ),
      dividerColor: LightColors.divider,
      cardColor: LightColors.bgCard,
    );
  }
}
