import 'package:flutter/material.dart';

/// Warm, quiet palette shared by the three premium mobile surfaces.
class AppColors {
  static const bgBase = Color(0xFFF5F1E8);
  static const bgDeep = Color(0xFFECE5D8);
  static const bgSurface = Color(0xFFFFFFFF);
  static const bgCard = Color(0xFFFFFDF9);
  static const bgInputBar = Color(0xFFFFFFFF);
  static const bgGlass = Color(0xD9FFFFFF);
  static const accentPrimary = Color(0xFF22211F);
  static const accentSecondary = Color(0xFF9C7B5B);
  static const accentTertiary = Color(0xFF55756B);
  static const accentGold = Color(0xFFD5A85D);
  static const gradStart = Color(0xFFC79B72);
  static const gradMid = Color(0xFFA88668);
  static const gradEnd = Color(0xFF6F5A49);
  static const userBubble = Color(0xFF242321);
  static const aiBubble = Color(0xFFFFFFFF);
  static const aiBubbleBorder = Color(0xFFEAE3D8);
  static const glassBorder = Color(0x80FFFFFF);
  static const textPrimary = Color(0xFF201F1D);
  static const textSecondary = Color(0xFF6F6A62);
  static const textMuted = Color(0xFFA49E94);
  static const success = Color(0xFF55756B);
  static const error = Color(0xFFB85C4C);
  static const warning = Color(0xFFD5A85D);
  static const drawerBg = bgBase;
  static const drawerSurface = bgSurface;
  static const divider = Color(0xFFE7E0D5);

  static void init(bool _) {}
  static List<Color> get primaryGradient => const [gradStart, gradEnd];
  static List<Color> get subtleGradient =>
      const [Color(0xFFD9BEA5), Color(0xFF9C7B5B)];
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accentSecondary,
      brightness: Brightness.light,
      surface: AppColors.bgSurface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgBase,
      colorScheme: scheme,
      fontFamily: 'SF Pro Display',
      splashFactory: InkSparkle.splashFactory,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontSize: 52,
            height: .98,
            fontWeight: FontWeight.w700,
            letterSpacing: -2.2),
        headlineLarge: TextStyle(
            fontSize: 40,
            height: 1.02,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.7),
        headlineMedium: TextStyle(
            fontSize: 28,
            height: 1.08,
            fontWeight: FontWeight.w700,
            letterSpacing: -1),
        titleLarge: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -.35),
        bodyLarge:
            TextStyle(fontSize: 16, height: 1.45, fontWeight: FontWeight.w500),
        bodyMedium:
            TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w500),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ).apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary),
      cardColor: AppColors.bgSurface,
      dividerColor: AppColors.divider,
      inputDecorationTheme:
          const InputDecorationTheme(border: InputBorder.none),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      }),
    );
  }

  // Kept for API compatibility; the product intentionally ships in light mode.
  static ThemeData get dark => light;
}

class AppShadows {
  static List<BoxShadow> get card => const [
        BoxShadow(
            color: Color(0x140D0B08), blurRadius: 28, offset: Offset(0, 12)),
        BoxShadow(
            color: Color(0xA6FFFFFF), blurRadius: 1, offset: Offset(0, -1)),
      ];

  static List<BoxShadow> get floating => const [
        BoxShadow(
            color: Color(0x260D0B08), blurRadius: 34, offset: Offset(0, 16)),
      ];
}
