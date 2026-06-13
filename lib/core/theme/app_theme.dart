import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppThemeData {
  final Color background;
  final Color sidebar;
  final Color primaryText;
  final Color secondaryText;
  final Color accent;
  final Color purpleAccent;
  final Color purpleAccentDark;
  final Color purpleAccentLight;
  final Color cardBackground;
  final Color cardHover;
  final Color borderColor;
  final Brightness brightness;

  const AppThemeData({
    required this.background,
    required this.sidebar,
    required this.primaryText,
    required this.secondaryText,
    required this.accent,
    required this.purpleAccent,
    required this.purpleAccentDark,
    required this.purpleAccentLight,
    required this.cardBackground,
    required this.cardHover,
    required this.borderColor,
    required this.brightness,
  });
}

class AppTheme {
  AppTheme._();

  static const AppThemeData dark = AppThemeData(
    background: Color.fromRGBO(18, 18, 20, 0.98),
    sidebar: Color.fromRGBO(24, 24, 28, 0.95),
    primaryText: Color(0xFFF5F5F7),
    secondaryText: Color(0xFF9A9AA5),
    accent: Color(0xFF007AFF),
    purpleAccent: AppColors.accent,
    purpleAccentDark: AppColors.accentDark,
    purpleAccentLight: AppColors.accentLight,
    cardBackground: Color(0xFF1F1F23),
    cardHover: Color(0xFF2A2A2E),
    borderColor: AppColors.accentBorder,
    brightness: Brightness.dark,
  );

  static const AppThemeData light = AppThemeData(
    background: Color.fromRGBO(245, 245, 250, 0.98),
    sidebar: Color.fromRGBO(227, 227, 235, 0.95),
    primaryText: Color(0xFF1A1A1A),
    secondaryText: Color(0xFF6B6B7A),
    accent: Color(0xFF007AFF),
    purpleAccent: AppColors.accent,
    purpleAccentDark: AppColors.accentDark,
    purpleAccentLight: AppColors.accentLight,
    cardBackground: Color(0xFFF9F9FB),
    cardHover: Color(0xFFF0F0F5),
    borderColor: AppColors.accentBorder,
    brightness: Brightness.light,
  );

  static AppThemeData of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? light : dark;
  }

  static ThemeData themeDataFor(String theme) {
    final data = theme == 'light' ? light : dark;
    return ThemeData(
      brightness: data.brightness,
      scaffoldBackgroundColor: data.background,
      useMaterial3: true,
      fontFamily: 'PingFang SC',
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: data.primaryText, fontSize: 13),
        bodySmall: TextStyle(color: data.secondaryText, fontSize: 12),
        titleMedium: TextStyle(
          color: data.primaryText,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconTheme: IconThemeData(color: data.secondaryText, size: 18),
    );
  }
}
