import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final colorScheme = const ColorScheme.dark().copyWith(
      brightness: Brightness.dark,
      surface: AppColors.background,
      primary: AppColors.primaryIndigo,
      secondary: AppColors.primaryCyan,
      error: AppColors.errorCoral,
      onSurface: AppColors.textPrimary,
      onPrimary: Colors.white,
      outline: AppColors.surfaceBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: colorScheme,
      textTheme: AppTypography.textTheme,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.heading(fontSize: 18),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTypography.body(fontSize: 14, color: AppColors.textMuted),
        labelStyle: AppTypography.body(fontSize: 13, color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryIndigo, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.errorCoral),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryIndigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: AppTypography.badge(fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.surfaceBorderStrong),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: AppTypography.badge(fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryCyan,
          textStyle: AppTypography.badge(fontSize: 14),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevated,
        labelStyle: AppTypography.badge(fontSize: 12.5, color: AppColors.textPrimary),
        side: const BorderSide(color: AppColors.surfaceBorder),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceBorder,
        thickness: 1,
        space: 1,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryCyan,
        linearTrackColor: AppColors.surfaceElevated,
        circularTrackColor: AppColors.surfaceElevated,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: AppTypography.body(fontSize: 13.5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
