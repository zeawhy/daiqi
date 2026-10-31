import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color textPrimary = Color(0xFF2C2C2B);
  static const Color textSecondary = Color(0xFF7D7A75);
  static const Color background = Color(0xFFF9F8F7);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardPacked = Color(0xFFF0EFED);
  static const Color secondaryBg = Color(0xFFF0EFED);
  static const Color border = Color(0xFFE6E5E3);

  // Primary Blue
  static const Color primary = Color(0xFF2783DE);
  static const Color primaryLight = Color(0xFFE5F2FC);

  // Done Green
  static const Color done = Color(0xFF46A171);
  static const Color doneLight = Color(0xFFE8F1EC);

  // Warning / Remaining Orange
  static const Color orange = Color(0xFFD5803B);
  static const Color orangeLight = Color(0xFFFBEBDE);

  // High-Risk Danger Red
  static const Color danger = Color(0xFFE56458);
  static const Color dangerLight = Color(0xFFFCE9E7);

  // Backpack Handle & Zipper
  static const Color backpackHardware = Color(0xFF5F7C99);
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.primaryLight,
        onSecondary: AppColors.primary,
        surface: AppColors.card,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
        onError: Colors.white,
      ),
      fontFamilyFallback: const [
        'PingFang SC',
        'Source Han Sans SC',
        'Noto Sans CJK SC',
        'sans-serif',
      ],
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
