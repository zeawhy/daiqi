import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color textPrimary = Color(0xFF1C1917);
  static const Color textSecondary = Color(0xFF57534E);
  static const Color background = Color(0xFFF5F5F4);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardPacked = Color(0xFFF0EFED);
  static const Color secondaryBg = Color(0xFFEEEEEC);
  static const Color border = Color(0xFFE7E5E4);
  static const Color borderStrong = Color(0xFF96908A);

  // Disabled Control States (6.57:1 contrast: #57534E on #EEEEEC)
  static const Color disabledBg = secondaryBg;
  static const Color disabledFg = textSecondary;

  // On-Dark Foreground Tokens
  static const Color onDark = Color(0xFFFFFFFF);
  static const Color onDarkSubtle = Color(0x66FFFFFF);

  // Warm Charcoal Diffused Shadows (derived from textPrimary #1C1917)
  static const Color shadowHairline = Color.fromRGBO(28, 25, 23, 0.03);
  static const Color shadowLight = Color.fromRGBO(28, 25, 23, 0.04);
  static const Color shadowSoft = Color.fromRGBO(28, 25, 23, 0.05);
  static const Color shadowMedium = Color.fromRGBO(28, 25, 23, 0.06);

  // Primary Charcoal (Santorini Warm Editorial Minimalist)
  static const Color primary = Color(0xFF262626);
  static const Color primaryLight = Color(0xFFECEAE6);
  static const Color primaryAccent = Color(0xFF3A3835);

  // Done Forest Green
  static const Color done = Color(0xFF1F6F4A);
  static const Color doneAccent = Color(0xFF2A855B);
  static const Color doneLight = Color(0xFFEAF5EF);

  // Warning / Remaining Amber-Brown
  static const Color orange = Color(0xFF8A5200);
  static const Color orangeLight = Color(0xFFFEF3C7);

  // High-Risk Danger Coral Red
  static const Color danger = Color(0xFFB82E2E);
  static const Color dangerLight = Color(0xFFFDECEC);

  // Editorial Soft Pastel Pills
  static const Color pastelLavender = Color(0xFFEDE9FE);
  static const Color pastelAmber = Color(0xFFFEF3C7);
  static const Color pastelSky = Color(0xFFE0F2FE);
  static const List<Color> pastelPills = [
    pastelLavender,
    pastelAmber,
    pastelSky,
  ];

  // Hardware & Accents
  static const Color backpackHardware = Color(0xFF57534E);

  // Masthead Backdrop Gradients & Frosted Glass (Santorini Warm Travertine)
  static const Color headerBackdropTop = Color(0xFFEAE7E1);
  static const Color headerBackdropBottom = Color(0xFFF5F5F4);
  static const Color headerSunGlow = Color(0x28FEF3C7);
  static const Color headerSunGlowEnd = Color(0x00FEF3C7);
  static const Color headerScrimStart = Color(0xB8FAF8F5);
  static const Color headerScrimMid = Color(0x66FAF8F5);
  static const Color headerScrimEnd = Color(0x00FAF8F5);
  static const Color headerFadeStart = Color(0x00F5F5F4);
  static const Color headerFadeMid = Color(0x8CF5F5F4);
  static const Color glassSurface = Color(0xF5FFFFFF);
  static const Color glassBorder = Color(0xEBFFFFFF);

  // Editorial Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF262626), Color(0xFF3A3835)],
  );

  static const LinearGradient doneGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F6F4A), Color(0xFF2A855B)],
  );
}

class AppTheme {
  AppTheme._();

  /// 首页「带齐了」大标题专属展示字体（阿里妈妈东方大楷子集，非思源宋体）
  static const String homeDisplayFontFamily = 'DaiqiDisplay';

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onDark,
        secondary: AppColors.primaryLight,
        onSecondary: AppColors.primary,
        surface: AppColors.card,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.borderStrong,
        outlineVariant: AppColors.border,
        surfaceContainerLowest: AppColors.card,
        surfaceContainerLow: AppColors.background,
        surfaceContainer: AppColors.secondaryBg,
        surfaceContainerHigh: AppColors.primaryLight,
        surfaceContainerHighest: AppColors.border,
        error: AppColors.danger,
        onError: AppColors.onDark,
      ),
      fontFamilyFallback: const [
        'HarmonyOS Sans SC',
        'MiSans',
        'PingFang SC',
        'Source Han Sans SC',
        'Noto Sans CJK SC',
        'sans-serif',
      ],
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          height: 1.20,
          color: AppColors.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          height: 1.25,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          height: 1.28,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          height: 1.35,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          height: 1.35,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
          height: 1.45,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
          height: 1.40,
          color: AppColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          height: 1.20,
          color: AppColors.textPrimary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          height: 1.20,
          color: AppColors.textSecondary,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 21,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          height: 1.25,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onDark,
          disabledBackgroundColor: AppColors.disabledBg,
          disabledForegroundColor: AppColors.disabledFg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onDark,
          disabledBackgroundColor: AppColors.disabledBg,
          disabledForegroundColor: AppColors.disabledFg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.disabledFg,
          side: const BorderSide(color: AppColors.borderStrong, width: 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.disabledFg,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        helperStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
        errorStyle: const TextStyle(
          color: AppColors.danger,
          fontSize: 12,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.borderStrong, width: 0.9),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.borderStrong, width: 0.9),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.onDark;
          return AppColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.secondaryBg;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return AppColors.borderStrong;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.onDark),
        side: const BorderSide(color: AppColors.textSecondary, width: 1.6),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.card,
        selectedColor: AppColors.primary,
        checkmarkColor: AppColors.onDark,
        surfaceTintColor: Colors.transparent,
        labelStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.onDark,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: AppColors.borderStrong, width: 0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textPrimary,
        textColor: AppColors.textPrimary,
        subtitleTextStyle: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(
          color: AppColors.onDark,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: AppColors.pastelAmber,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          height: 1.45,
          color: AppColors.textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.card,
        dialBackgroundColor: AppColors.background,
        dialHandColor: AppColors.primary,
        dialTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.onDark;
          return AppColors.textPrimary;
        }),
        hourMinuteColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.secondaryBg;
        }),
        hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.onDark;
          return AppColors.textPrimary;
        }),
        dayPeriodColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.secondaryBg;
        }),
        dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.onDark;
          return AppColors.textPrimary;
        }),
        dayPeriodBorderSide: const BorderSide(
          color: AppColors.borderStrong,
          width: 0.9,
        ),
        entryModeIconColor: AppColors.textSecondary,
        helpTextStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.secondaryBg,
        circularTrackColor: AppColors.secondaryBg,
      ),
    );
  }
}
