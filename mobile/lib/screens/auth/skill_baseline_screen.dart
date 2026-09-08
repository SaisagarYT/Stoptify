import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/skills_provider.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_button.dart';

const _levelLabels = ['Novice', 'Beginner', 'Intermediate', 'Advanced', 'Expert'];

class SkillBaselineScreen extends ConsumerStatefulWidget {
  const SkillBaselineScreen({super.key});

  @override
  ConsumerState<SkillBaselineScreen> createState() => _SkillBaselineScreenState();
}

class _SkillBaselineScreenState extends ConsumerState<SkillBaselineScreen> {
  bool _submitting = false;

  Future<void> _continue() async {
    setState(() => _submitting = true);
    await ref.read(skillsProvider.notifier).submit();
    if (mounted) context.go(RoutePaths.resumeIntake);
  }

  @override
  Widget build(BuildContext context) {
    final skills = ref.watch(skillsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Skill Baseline')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rate your current comfort level so we skip what you already know.',
                style: AppTypography.body(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              for (final skill in skills)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(skill.skillName, style: AppTypography.heading(fontSize: 16)),
                            Text(
                              _levelLabels[skill.level - 1],
                              style: AppTypography.badge(fontSize: 12.5, color: AppColors.primaryCyan),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primaryIndigo,
                            inactiveTrackColor: AppColors.surfaceElevated,
                            thumbColor: AppColors.primaryCyan,
                            overlayColor: AppColors.primaryCyan.withValues(alpha: 0.15),
                          ),
                          child: Slider(
                            value: skill.level.toDouble(),
                            min: 1,
                            max: 5,
                            divisions: 4,
                            onChanged: (v) =>
                                ref.read(skillsProvider.notifier).setLevel(skill.skillName, v.round()),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 350.ms).slideX(begin: 0.04, end: 0),
                ),
              const SizedBox(height: 8),
              GradientButton(
                label: 'Continue',
                icon: Icons.arrow_forward_rounded,
                isLoading: _submitting,
                onPressed: _continue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
