import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_color_scheme.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final ext = AppColorScheme.light();
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'NotoSansJP',
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.surfaceLight,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryLight,
        onPrimary: AppColors.onPrimaryLight,
        surface: AppColors.surfaceCardLight,
        onSurface: AppColors.textBodyLight,
        error: AppColors.dangerLight,
      ),
      extensions: [ext],
      textTheme: _textTheme(
        heading: AppColors.textHeadingLight,
        body: AppColors.textBodyLight,
        muted: AppColors.textMutedLight,
      ),
    );
  }

  static ThemeData get dark {
    final ext = AppColorScheme.dark();
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'NotoSansJP',
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.surfaceDark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryDark,
        onPrimary: AppColors.onPrimaryDark,
        surface: AppColors.surfaceCardDark,
        onSurface: AppColors.textBodyDark,
        error: AppColors.dangerDark,
      ),
      extensions: [ext],
      textTheme: _textTheme(
        heading: AppColors.textHeadingDark,
        body: AppColors.textBodyDark,
        muted: AppColors.textMutedDark,
      ),
    );
  }

  static TextTheme _textTheme({
    required Color heading,
    required Color body,
    required Color muted,
  }) {
    return TextTheme(
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: heading,
        height: 1.3,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: heading,
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: body,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: body,
        height: 1.6,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: muted,
        height: 1.5,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: heading,
        height: 1.4,
      ),
    );
  }
}
