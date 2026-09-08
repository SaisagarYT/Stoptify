import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/roadmap.dart';
import '../common/glass_card.dart';

class VelocityBanner extends StatelessWidget {
  const VelocityBanner({super.key, required this.velocity});
  final VelocityMetrics velocity;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d').format(velocity.projectedCompletion);
    return GlassCard(
      backgroundColor: AppColors.surfaceElevated,
      glowColor: AppColors.primaryIndigo,
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: AppColors.anchorAmber, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTypography.body(fontSize: 13.5),
                children: [
                  TextSpan(
                    text: 'Learning Pace: ',
                    style: AppTypography.body(fontSize: 13.5, color: AppColors.textSecondary),
                  ),
                  TextSpan(
                    text: '${velocity.paceMultiplier.toStringAsFixed(1)}x Fast-Track',
                    style: AppTypography.badge(fontSize: 13.5, color: AppColors.primaryCyan),
                  ),
                  TextSpan(
                    text: '  |  Projected: $dateStr',
                    style: AppTypography.body(fontSize: 13.5, color: AppColors.textSecondary),
                  ),
                  if (velocity.daysAheadOfSchedule > 0)
                    TextSpan(
                      text: ' (${velocity.daysAheadOfSchedule}d ahead)',
                      style: AppTypography.badge(fontSize: 13.5, color: AppColors.masteryVerified),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
