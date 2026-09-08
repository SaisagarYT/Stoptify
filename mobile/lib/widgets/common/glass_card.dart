import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// The signature "Frosted Slate" glassmorphic surface used across Stoptify.
///
/// Wraps [child] in a blurred, semi-transparent card with a subtle 1px
/// hairline border, matching the "Deep Obsidian & Cyber-Academic" system.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
    this.borderColor = AppColors.surfaceBorder,
    this.backgroundColor = AppColors.surface,
    this.blurSigma = 18,
    this.onTap,
    this.glowColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color borderColor;
  final Color backgroundColor;
  final double blurSigma;
  final VoidCallback? onTap;

  /// If set, renders an ambient glow shadow behind the card (e.g. active
  /// milestone pulsing ring, AI-intelligence highlight).
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    final card = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor.withValues(alpha: 0.72),
            borderRadius: radius,
            border: Border.all(color: borderColor, width: 1),
          ),
          child: child,
        ),
      ),
    );

    final wrapped = glowColor == null
        ? card
        : Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: AppColors.glow(glowColor!),
            ),
            child: card,
          );

    if (onTap == null) return wrapped;

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: wrapped,
      ),
    );
  }
}
