import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/consultation.dart';
import '../../providers/consultation_provider.dart';
import '../../widgets/common/gradient_button.dart';

class ConsultationScreen extends ConsumerStatefulWidget {
  const ConsultationScreen({super.key, required this.domainId});
  final String domainId;

  @override
  ConsumerState<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends ConsumerState<ConsultationScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _finalizing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(consultationProvider.notifier).start(widget.domainId);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send([String? quickReply]) async {
    final text = quickReply ?? _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    await ref.read(consultationProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _finalize() async {
    setState(() => _finalizing = true);
    final roadmapId = await ref.read(consultationProvider.notifier).finalize();
    if (mounted) context.go(RoutePaths.roadmapDashboardFor(roadmapId));
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(consultationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic Consultation'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: session?.progress ?? 0,
            minHeight: 3,
            backgroundColor: AppColors.surfaceElevated,
            valueColor: const AlwaysStoppedAnimation(AppColors.primaryCyan),
          ),
        ),
      ),
      body: session == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: session.messages.length,
                    itemBuilder: (context, i) => _MessageBubble(message: session.messages[i]),
                  ),
                ),
                if (session.messages.isNotEmpty && session.messages.last.quickReplies.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final reply in session.messages.last.quickReplies)
                          ActionChip(
                            label: Text(reply),
                            backgroundColor: AppColors.primaryIndigo.withValues(alpha: 0.14),
                            side: BorderSide(color: AppColors.primaryIndigo.withValues(alpha: 0.4)),
                            labelStyle: AppTypography.badge(fontSize: 12.5, color: AppColors.primaryCyan),
                            onPressed: () => _send(reply),
                          ),
                      ],
                    ),
                  ),
                if (session.readyToFinalize)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: GradientButton(
                      label: 'Generate Calibrated Roadmap',
                      icon: Icons.auto_awesome_rounded,
                      isLoading: _finalizing,
                      onPressed: _finalize,
                    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
                  ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _inputController,
                            style: AppTypography.body(fontSize: 14),
                            decoration: const InputDecoration(hintText: 'Type your answer…'),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: () => _send(),
                          icon: const Icon(Icons.send_rounded),
                          style: IconButton.styleFrom(backgroundColor: AppColors.primaryIndigo),
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ConsultationMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          gradient: isUser ? AppColors.aiGradient : null,
          color: isUser ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
          border: isUser ? null : Border.all(color: AppColors.surfaceBorder),
        ),
        child: Text(
          message.content,
          style: AppTypography.body(fontSize: 14, color: isUser ? Colors.white : AppColors.textPrimary),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.08, end: 0);
  }
}
