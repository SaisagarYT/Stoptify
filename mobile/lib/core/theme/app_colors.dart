import 'package:flutter/material.dart';

/// Stoptify's Industry-Standard Monochrome palette.
///
/// Deep layered carbon, graphite surfaces, crisp off-white typography,
/// hairline architectural borders, and high-contrast solid white CTAs.
/// Avoids #000000 pitch black to eliminate eye strain and OLED smearing.
class AppColors {
  AppColors._();

  // --- Base Canvas & Layered Surfaces ---
  static const Color canvas = Color(0xFF121214); // Refined dark canvas
  static const Color surface = Color(0xFF18181C); // Card container
  static const Color surfaceElevated = Color(0xFF202026); // Elevated element
  static const Color inputBackground = Color(0xFF1A1A1F); // Clean input field

  // --- Hairline Borders ---
  static const Color borderSubtle = Color(0xFF2C2C34); // Subtle 1px hairline
  static const Color borderStrong = Color(0xFF3F3F4A); // Stronger outline
  static const Color borderFocus = Color(0xFFFFFFFF); // Focused state

  // --- High-Contrast Monochrome CTAs ---
  static const Color buttonPrimary = Color(0xFFFFFFFF); // Solid White
  static const Color buttonText = Color(0xFF121214); // Dark ink text on white
  static const Color buttonSecondary = Color(0xFF202026); // Muted secondary button

  // --- Typography Scale ---
  static const Color textPrimary = Color(0xFFF5F5F7); // Primary crisp off-white
  static const Color textSecondary = Color(0xFF8E8E93); // Muted secondary grey
  static const Color textMuted = Color(0xFF5A5A62); // Subtle placeholders

  // --- Subtle Functional Accents ---
  static const Color successGreen = Color(0xFF10B981); // Emerald verified
  static const Color warningAmber = Color(0xFFF59E0B); // Anti-scope alert
  static const Color errorRed = Color(0xFFEF4444); // Error / validation

  // --- Backwards Compatibility Aliases ---
  static const Color background = canvas;
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceBorder = borderSubtle;
  static const Color surfaceBorderStrong = borderStrong;
  static const Color borderBlack = borderSubtle;
  static const Color cardCream = surface;
  static const Color yellowHeader = buttonPrimary;
  static const Color orangePrimary = buttonPrimary;
  static const Color inkBlack = textPrimary;
  static const Color inkGrey = textSecondary;
  static const Color inkMuted = textMuted;
  static const Color primaryIndigo = buttonPrimary;
  static const Color primaryCyan = textPrimary;
  static const Color masteryVerified = successGreen;
  static const Color anchorAmber = warningAmber;
  static const Color errorCoral = errorRed;
  static const Color textOnEmerald = buttonText;
  static const Color textOnAmber = buttonText;
  static const Color lockedOverlay = Color(0x99121214);
  static const Color lockedIcon = textMuted;
  static const Color mcqSuccess = successGreen;
  static const Color mcqError = errorRed;

  static const LinearGradient aiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFA0A0A8)],
  );

  static List<BoxShadow> subtleElevation = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.35),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> glow(Color color, {double blur = 24, double alpha = 0.35}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: alpha),
        blurRadius: blur,
        spreadRadius: 1,
      ),
    ];
  }
}
