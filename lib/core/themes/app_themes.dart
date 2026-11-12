import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get lightTheme => _theme(Brightness.light);
  static ThemeData get darkTheme => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final colorScheme = dark
        ? const ColorScheme.dark(
            primary: Color(0xFF9AA8FF),
            secondary: Color(0xFF9ABEFF),
            surface: Color(0xFF1D2028),
            error: AppColors.danger,
            onPrimary: Color(0xFF171923),
            onSecondary: Color(0xFF171923),
            onSurface: Color(0xFFE4E7EF),
            onError: AppColors.white,
          )
        : const ColorScheme.light(
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            surface: AppColors.background,
            error: AppColors.danger,
            onPrimary: AppColors.white,
            onSecondary: AppColors.white,
            onSurface: AppColors.textPrimary,
            onError: AppColors.white,
          );
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      brightness: brightness,
      scaffoldBackgroundColor: dark
          ? const Color(0xFF12141A)
          : AppColors.background,
      colorScheme: colorScheme,
      textTheme: AppTypography.textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: dark ? const Color(0xFF1D2028) : AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
          elevation: 0,
        ),
      ),
    );
  }
}
