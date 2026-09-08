import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum PillTone { neutral, emerald, amber, coral, indigo }

/// Small rounded pill used for duration estimates, company badges,
/// subtopic chips, and mastery/locked status indicators.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.icon,
    this.tone = PillTone.neutral,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final PillTone tone;
  final bool dense;

  ({Color bg, Color fg, Color border}) get _colors {
    switch (tone) {
      case PillTone.emerald:
        return (
          bg: AppColors.masteryVerified.withValues(alpha: 0.14),
          fg: AppColors.masteryVerified,
          border: AppColors.masteryVerified.withValues(alpha: 0.4),
        );
      case PillTone.amber:
        return (
          bg: AppColors.anchorAmber.withValues(alpha: 0.14),
          fg: AppColors.anchorAmber,
          border: AppColors.anchorAmber.withValues(alpha: 0.4),
        );
      case PillTone.coral:
        return (
          bg: AppColors.errorCoral.withValues(alpha: 0.14),
          fg: AppColors.errorCoral,
          border: AppColors.errorCoral.withValues(alpha: 0.4),
        );
      case PillTone.indigo:
        return (
          bg: AppColors.primaryIndigo.withValues(alpha: 0.16),
          fg: AppColors.primaryCyan,
          border: AppColors.primaryIndigo.withValues(alpha: 0.4),
        );
      case PillTone.neutral:
        return (
          bg: AppColors.surfaceElevated,
          fg: AppColors.textSecondary,
          border: AppColors.surfaceBorder,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 10 : 12, vertical: dense ? 4 : 6),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: c.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: c.fg),
            const SizedBox(width: 5),
          ],
          Text(label, style: AppTypography.badge(fontSize: dense ? 11 : 12.5, color: c.fg)),
        ],
      ),
    );
  }
}
