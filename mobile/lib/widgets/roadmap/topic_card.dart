import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/roadmap.dart';
import '../common/glass_card.dart';
import '../common/gradient_button.dart';
import '../common/status_pill.dart';

/// The full generative UI card for a single roadmap topic: header,
/// subtopics, production example, anti-scope boundary, and dual actions.
class TopicCard extends StatelessWidget {
  const TopicCard({
    super.key,
    required this.topic,
    required this.onFastTrack,
    required this.onStudy,
  });

  final RoadmapTopic topic;
  final VoidCallback onFastTrack;
  final VoidCallback onStudy;

  bool get _locked => topic.status == TopicStatus.locked;
  bool get _completed => topic.status == TopicStatus.completed;

  @override
  Widget build(BuildContext context) {
    final card = GlassCard(
      borderColor: _completed
          ? AppColors.masteryVerified.withValues(alpha: 0.5)
          : (topic.status == TopicStatus.inProgress
              ? AppColors.primaryCyan.withValues(alpha: 0.5)
              : AppColors.surfaceBorder),
      glowColor: topic.status == TopicStatus.inProgress ? AppColors.primaryCyan : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header ---------------------------------------------------
          Row(
            children: [
              _StatusBadge(status: topic.status),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${topic.orderIndex}. ${topic.title}',
                  style: AppTypography.heading(fontSize: 17),
                ),
              ),
              StatusPill(
                label: '⏱️ ${topic.estimatedMinutes} min',
                dense: true,
              ),
            ],
          ),

          if (!_locked) ...[
            const SizedBox(height: 14),
            // --- Subtopics ------------------------------------------------
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in topic.coreSubtopics) StatusPill(label: s, tone: PillTone.indigo, dense: true),
              ],
            ),

            if (topic.productionExample != null) ...[
              const SizedBox(height: 14),
              _ProductionExampleCard(example: topic.productionExample!),
            ],

            if (topic.antiScope != null) ...[
              const SizedBox(height: 12),
              _AntiScopeCard(antiScope: topic.antiScope!),
            ],

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onFastTrack,
                    icon: const Icon(Icons.bolt_rounded, size: 18, color: AppColors.anchorAmber),
                    label: const Text('Fast-Track'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GradientButton(
                    label: 'Study Chapter',
                    icon: Icons.menu_book_rounded,
                    onPressed: onStudy,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              'Complete the previous topic to unlock.',
              style: AppTypography.body(fontSize: 12.5, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );

    if (!_locked) return card;

    // Locked topics render translucent/frosted, non-interactive.
    return Opacity(opacity: 0.55, child: IgnorePointer(child: card));
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final TopicStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case TopicStatus.completed:
        return const CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.masteryVerified,
          child: Icon(Icons.check_rounded, size: 16, color: Colors.black),
        );
      case TopicStatus.inProgress:
        return const CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.primaryCyan,
          child: Icon(Icons.play_arrow_rounded, size: 16, color: Colors.black),
        );
      case TopicStatus.locked:
        return const CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.lockedOverlay,
          child: Icon(Icons.lock_rounded, size: 14, color: AppColors.lockedIcon),
        );
    }
  }
}

class _ProductionExampleCard extends StatelessWidget {
  const _ProductionExampleCard({required this.example});
  final ProductionExample example;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryCyan.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.public_rounded, size: 15, color: AppColors.primaryCyan),
              const SizedBox(width: 6),
              StatusPill(label: example.companyBadge, tone: PillTone.indigo, dense: true),
            ],
          ),
          const SizedBox(height: 8),
          Text(example.challenge, style: AppTypography.body(fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            example.takeaway,
            style: AppTypography.body(fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AntiScopeCard extends StatelessWidget {
  const _AntiScopeCard({required this.antiScope});
  final AntiScopeBoundary antiScope;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.anchorAmber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.anchorAmber.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🛑', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text('When to Stop', style: AppTypography.badge(fontSize: 12.5, color: AppColors.anchorAmber)),
            ],
          ),
          const SizedBox(height: 8),
          Text(antiScope.stopCondition, style: AppTypography.body(fontSize: 13)),
          if (antiScope.doNotStudyYet.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Not yet: ${antiScope.doNotStudyYet.join(", ")}',
              style: AppTypography.body(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
