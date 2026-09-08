import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Primary call-to-action button rendered with the Indigo -> Cyan AI
/// gradient. Used for high-intent actions like "Generate Calibrated
/// Roadmap" or "Fast-Track / Test Out".
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    final button = Container(
      decoration: BoxDecoration(
        gradient: disabled
            ? LinearGradient(colors: [
                AppColors.primaryIndigo.withValues(alpha: 0.35),
                AppColors.primaryCyan.withValues(alpha: 0.35),
              ])
            : AppColors.aiGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: disabled ? null : AppColors.glow(AppColors.primaryIndigo, alpha: 0.28),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: disabled ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                ] else if (icon != null) ...[
                  Icon(icon, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(label, style: AppTypography.badge(fontSize: 15, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// A thin pulsing ring used to draw the eye to the active roadmap node.
class PulsingRing extends StatelessWidget {
  const PulsingRing({super.key, required this.child, this.color = AppColors.primaryCyan});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.35, 1.35),
              duration: 1400.ms,
              curve: Curves.easeOut,
            )
            .fadeOut(duration: 1400.ms),
        child,
      ],
    );
  }
}
