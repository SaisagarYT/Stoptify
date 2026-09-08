import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/chapter.dart';
import '../../providers/chapter_provider.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_button.dart';

class TextbookReaderScreen extends ConsumerWidget {
  const TextbookReaderScreen(
      {super.key, required this.roadmapId, required this.topicId});
  final String roadmapId;
  final String topicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapterAsync = ref.watch(chapterProvider(topicId));

    return Scaffold(
      appBar: AppBar(title: const Text('Chapter')),
      body: chapterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Could not load chapter.\n$e',
              textAlign: TextAlign.center,
              style: AppTypography.body(
                  fontSize: 13, color: AppColors.errorCoral)),
        ),
        data: (chapter) => ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
          children: [
            GlassCard(
              child: MarkdownBody(
                data: chapter.conceptualGuideMarkdown,
                styleSheet: MarkdownStyleSheet(
                  p: AppTypography.body(fontSize: 14.5),
                  h1: AppTypography.heading(fontSize: 22),
                  h2: AppTypography.heading(fontSize: 18),
                  h3: AppTypography.heading(fontSize: 16),
                  code: AppTypography.code(
                      fontSize: 13, color: AppColors.primaryCyan),
                  codeblockDecoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  blockquoteDecoration: BoxDecoration(
                    color: AppColors.primaryIndigo.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: const Border(
                        left: BorderSide(
                            color: AppColors.primaryIndigo, width: 3)),
                  ),
                ),
              ),
            ),
            if (chapter.mermaidDiagram != null) ...[
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.account_tree_outlined,
                            size: 16, color: AppColors.primaryCyan),
                        SizedBox(width: 6),
                        Text('Diagram',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Render via a webview/mermaid.js bridge in production;
                    // shown here as the raw definition inside a code block.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(chapter.mermaidDiagram!,
                          style: AppTypography.code(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
            for (final lab in chapter.labs) ...[
              const SizedBox(height: 16),
              _InteractiveLabCard(lab: lab),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GradientButton(
            label: 'Take Assessment',
            icon: Icons.quiz_rounded,
            onPressed: () =>
                context.push(RoutePaths.assessmentHudFor(roadmapId, topicId)),
          ),
        ),
      ),
    );
  }
}

class _InteractiveLabCard extends StatelessWidget {
  const _InteractiveLabCard({required this.lab});
  final InteractiveLab lab;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      backgroundColor: AppColors.surfaceElevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.terminal_rounded,
                  size: 16, color: AppColors.masteryVerified),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(lab.title,
                      style: AppTypography.heading(fontSize: 15))),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lab.code, style: AppTypography.code(fontSize: 13)),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: lab.code)),
                    icon: const Icon(Icons.copy_rounded, size: 15),
                    label: const Text('Copy Code'),
                  ),
                ),
              ],
            ),
          ),
          if (lab.verificationChecklist.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Verify:',
                style: AppTypography.badge(
                    fontSize: 12.5, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            for (final item in lab.verificationChecklist)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_box_outline_blank_rounded,
                        size: 15, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(item,
                            style: AppTypography.body(fontSize: 13))),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
