import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/resume_provider.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/status_pill.dart';

class ResumeIntakeScreen extends ConsumerStatefulWidget {
  const ResumeIntakeScreen({super.key});

  @override
  ConsumerState<ResumeIntakeScreen> createState() => _ResumeIntakeScreenState();
}

class _ResumeIntakeScreenState extends ConsumerState<ResumeIntakeScreen> {
  final _textController = TextEditingController();

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'txt']);
    final path = result?.files.single.path;
    if (path != null) {
      await ref.read(resumeAnalysisProvider.notifier).analyze(filePath: path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resumeAnalysisProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tell us about you')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.document_scanner_outlined, color: AppColors.primaryCyan),
                        const SizedBox(width: 8),
                        Text('Upload or paste your resume', style: AppTypography.heading(fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DottedDropZone(onTap: _pickFile),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _textController,
                      maxLines: 6,
                      style: AppTypography.body(fontSize: 13.5),
                      decoration: const InputDecoration(hintText: 'Or paste resume text here…'),
                    ),
                    const SizedBox(height: 16),
                    GradientButton(
                      label: 'Analyze Resume',
                      icon: Icons.auto_awesome_rounded,
                      isLoading: state.isAnalyzing,
                      onPressed: () => ref
                          .read(resumeAnalysisProvider.notifier)
                          .analyze(resumeText: _textController.text),
                    ),
                  ],
                ),
              ),
              if (state.result != null) ...[
                const SizedBox(height: 28),
                Text('Detected skills', style: AppTypography.heading(fontSize: 16)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (int i = 0; i < state.result!.detectedSkills.length; i++)
                      StatusPill(
                        label:
                            '${state.result!.detectedSkills[i].name} · ${state.result!.detectedSkills[i].rating.toStringAsFixed(1)}★',
                        tone: PillTone.indigo,
                      ).animate().fadeIn(delay: (i * 80).ms).slideX(begin: 0.1, end: 0),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Choose your track', style: AppTypography.heading(fontSize: 16)),
                const SizedBox(height: 10),
                for (int i = 0; i < state.result!.domainCategories.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DomainCard(
                      title: state.result!.domainCategories[i].title,
                      match: state.result!.domainCategories[i].matchPercentage,
                      isCustom: state.result!.domainCategories[i].isCustom,
                      selected: state.selectedDomainCategoryId == state.result!.domainCategories[i].id,
                      onTap: () {
                        ref
                            .read(resumeAnalysisProvider.notifier)
                            .selectDomain(state.result!.domainCategories[i].id);
                      },
                    ).animate().fadeIn(delay: (i * 90).ms).slideY(begin: 0.06, end: 0),
                  ),
                const SizedBox(height: 10),
                if (state.selectedDomainCategoryId != null)
                  GradientButton(
                    label: 'Start Diagnostic Consultation',
                    icon: Icons.chat_bubble_outline_rounded,
                    onPressed: () =>
                        context.push(RoutePaths.consultationFor(state.selectedDomainCategoryId!)),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DottedDropZone extends StatelessWidget {
  const DottedDropZone({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primaryIndigo.withValues(alpha: 0.4), width: 1.4),
          color: AppColors.primaryIndigo.withValues(alpha: 0.05),
        ),
        child: Column(
          children: [
            const Icon(Icons.upload_file_rounded, color: AppColors.primaryCyan, size: 28),
            const SizedBox(height: 8),
            Text('Tap to upload PDF or text file',
                style: AppTypography.body(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _DomainCard extends StatelessWidget {
  const _DomainCard({
    required this.title,
    required this.match,
    required this.isCustom,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final double match;
  final bool isCustom;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      borderColor: selected ? AppColors.primaryCyan : AppColors.surfaceBorder,
      glowColor: selected ? AppColors.primaryCyan : null,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.heading(fontSize: 15)),
                if (!isCustom) ...[
                  const SizedBox(height: 4),
                  Text('${match.toStringAsFixed(0)}% match based on your resume',
                      style: AppTypography.body(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          Icon(
            selected ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: selected ? AppColors.masteryVerified : AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
