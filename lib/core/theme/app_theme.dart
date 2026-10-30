import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../design/design_tokens.dart';

class AppFonts {
  static const List<String> fontFallback = [
    'Microsoft YaHei UI',
    'Microsoft YaHei',
    'PingFang SC',
    'Hiragino Sans GB',
    'Noto Sans SC',
    'Segoe UI',
    'sans-serif',
  ];

  static String? get primaryFont {
    if (kIsWeb) return null;
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return 'Microsoft YaHei UI';
      case TargetPlatform.macOS:
      case TargetPlatform.iOS:
        return 'PingFang SC';
      case TargetPlatform.android:
        return 'Noto Sans SC';
      default:
        return null;
    }
  }

  static TextStyle textStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontFamily: primaryFont,
      fontFamilyFallback: fontFallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }
}

class AppTheme {
  static ThemeData lightTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppFonts.primaryFont,
      fontFamilyFallback: AppFonts.fontFallback,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        brightness: Brightness.light,
        surface: AppColors.lightSurface,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lightBg,
      textTheme: base.textTheme.apply(
        fontFamily: AppFonts.primaryFont,
        fontFamilyFallback: AppFonts.fontFallback,
      ),
      primaryTextTheme: base.primaryTextTheme.apply(
        fontFamily: AppFonts.primaryFont,
        fontFamilyFallback: AppFonts.fontFallback,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightTextPrimary,
        titleTextStyle: AppFonts.textStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusMd,
          side: const BorderSide(color: AppColors.lightBorder),
        ),
        color: AppColors.lightSurface,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusLg,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData darkTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppFonts.primaryFont,
      fontFamilyFallback: AppFonts.fontFallback,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        brightness: Brightness.dark,
        surface: AppColors.darkSurface,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.darkBg,
      textTheme: base.textTheme.apply(
        fontFamily: AppFonts.primaryFont,
        fontFamilyFallback: AppFonts.fontFallback,
      ),
      primaryTextTheme: base.primaryTextTheme.apply(
        fontFamily: AppFonts.primaryFont,
        fontFamilyFallback: AppFonts.fontFallback,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        titleTextStyle: AppFonts.textStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusMd,
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        color: AppColors.darkSurface,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusLg,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
