import 'package:flutter/material.dart';

/// Stoptify's "Deep Obsidian & Cyber-Academic" palette.
///
/// This is a premium dark-mode-first system inspired by Linear, Raycast,
/// Claude Artifacts, and Brilliant — never a default Material CRUD look.
class AppColors {
  AppColors._();

  // --- Base surfaces ---------------------------------------------------
  static const Color background = Color(0xFF0A0E17); // Deep Obsidian Void
  static const Color surface = Color(0xFF121826); // Frosted Slate
  static const Color surfaceBorder = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color surfaceBorderStrong = Color(0x29FFFFFF); // ~16% white

  /// Slightly elevated card surface (nested cards, modals over glass).
  static const Color surfaceElevated = Color(0xFF171F30);

  // --- Brand / AI intelligence ------------------------------------------
  static const Color primaryIndigo = Color(0xFF6366F1); // Electric Indigo
  static const Color primaryCyan = Color(0xFF06B6D4); // Cyan Glow

  static const LinearGradient aiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryIndigo, primaryCyan],
  );

  // --- Semantic states ---------------------------------------------------
  static const Color masteryVerified = Color(0xFF10B981); // Emerald Mint
  static const Color anchorAmber = Color(0xFFF59E0B); // "When to Stop" Anti-Scope
  static const Color errorCoral = Color(0xFFF43F5E); // Error / Remediation

  // --- Text -------------------------------------------------------------
  static const Color textPrimary = Color(0xFFF5F7FA);
  static const Color textSecondary = Color(0xFFA0AAC0);
  static const Color textMuted = Color(0xFF5C6478);
  static const Color textOnEmerald = Color(0xFF03130D);
  static const Color textOnAmber = Color(0xFF211502);

  // --- Locked / disabled state -------------------------------------------
  static const Color lockedOverlay = Color(0x66121826);
  static const Color lockedIcon = Color(0xFF3C4459);

  // --- Glow shadows (for pulsing rings, ambient highlights) --------------
  static List<BoxShadow> glow(Color color, {double blur = 24, double alpha = 0.35}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: alpha),
        blurRadius: blur,
        spreadRadius: 1,
      ),
    ];
  }

  static const Color mcqSuccess = masteryVerified;
  static const Color mcqError = errorCoral;
}
