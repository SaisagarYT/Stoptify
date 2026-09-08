import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/roadmap.dart';
import '../../providers/roadmap_provider.dart';
import '../../widgets/roadmap/topic_card.dart';
import '../../widgets/roadmap/velocity_banner.dart';

class RoadmapDashboardScreen extends ConsumerWidget {
  const RoadmapDashboardScreen({super.key, required this.roadmapId});
  final String roadmapId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roadmapAsync = ref.watch(roadmapProgressProvider(roadmapId));

    return Scaffold(
      appBar: AppBar(title: const Text('Your Roadmap')),
      body: roadmapAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Could not load roadmap.\n$e',
              textAlign: TextAlign.center, style: AppTypography.body(fontSize: 13, color: AppColors.errorCoral)),
        ),
        data: (roadmap) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(roadmapProgressProvider(roadmapId)),
          color: AppColors.primaryCyan,
          backgroundColor: AppColors.surface,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(roadmap.title, style: AppTypography.heading(fontSize: 22)),
              const SizedBox(height: 12),
              if (roadmap.velocity != null) VelocityBanner(velocity: roadmap.velocity!),
              const SizedBox(height: 20),
              for (int i = 0; i < roadmap.topics.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ConnectedNode(
                    isFirst: i == 0,
                    isLast: i == roadmap.topics.length - 1,
                    topic: roadmap.topics[i],
                    onFastTrack: () => context.push(
                      RoutePaths.assessmentHudFor(roadmapId, roadmap.topics[i].id),
                    ),
                    onStudy: () => context.push(
                      RoutePaths.textbookReaderFor(roadmapId, roadmap.topics[i].id),
                    ),
                  ).animate().fadeIn(delay: (i * 90).ms, duration: 400.ms).slideY(begin: 0.05, end: 0),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws the vertical connector line between topic nodes plus the card.
class _ConnectedNode extends StatelessWidget {
  const _ConnectedNode({
    required this.topic,
    required this.isFirst,
    required this.isLast,
    required this.onFastTrack,
    required this.onStudy,
  });

  final RoadmapTopic topic;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onFastTrack;
  final VoidCallback onStudy;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Expanded(
                  child: Container(width: 2, color: isFirst ? Colors.transparent : AppColors.surfaceBorderStrong),
                ),
                Expanded(
                  child: Container(width: 2, color: isLast ? Colors.transparent : AppColors.surfaceBorderStrong),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TopicCard(topic: topic, onFastTrack: onFastTrack, onStudy: onStudy),
          ),
        ],
      ),
    );
  }
}
