import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography scale.
///
/// - Headings & badges  -> Plus Jakarta Sans (bold, geometric, tight tracking)
/// - Body & explanations -> Inter (optimal legibility)
/// - Code & technical queries -> JetBrains Mono (soft syntax highlighting)
class AppTypography {
  AppTypography._();

  static TextTheme get textTheme {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      displayLarge: heading(fontSize: 40, height: 1.05),
      displayMedium: heading(fontSize: 32, height: 1.1),
      displaySmall: heading(fontSize: 28, height: 1.15),
      headlineLarge: heading(fontSize: 24, height: 1.2),
      headlineMedium: heading(fontSize: 20, height: 1.25),
      headlineSmall: heading(fontSize: 18, height: 1.3),
      titleLarge: heading(fontSize: 16, height: 1.3, weight: FontWeight.w700),
      titleMedium: body(fontSize: 15, weight: FontWeight.w600),
      titleSmall: body(fontSize: 13, weight: FontWeight.w600),
      bodyLarge: body(fontSize: 16),
      bodyMedium: body(fontSize: 14),
      bodySmall: body(fontSize: 12, color: AppColors.textSecondary),
      labelLarge: badge(fontSize: 13),
      labelMedium: badge(fontSize: 11),
      labelSmall: badge(fontSize: 10, color: AppColors.textMuted),
    );
  }

  static TextStyle heading({
    required double fontSize,
    double height = 1.2,
    FontWeight weight = FontWeight.w800,
    Color color = AppColors.textPrimary,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      height: height,
      fontWeight: weight,
      letterSpacing: -0.5,
      color: color,
    );
  }

  static TextStyle body({
    required double fontSize,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double height = 1.45,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  /// Badges / pills / labels — Plus Jakarta Sans, slightly condensed.
  static TextStyle badge({
    required double fontSize,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.textPrimary,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: weight,
      letterSpacing: 0.2,
      color: color,
    );
  }

  /// Code blocks, query snippets, technical identifiers.
  static TextStyle code({
    double fontSize = 13.5,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textPrimary,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
      height: 1.5,
    );
  }
}
