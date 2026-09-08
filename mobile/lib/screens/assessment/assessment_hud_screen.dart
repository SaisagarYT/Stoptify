import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/assessment.dart';
import '../../providers/assessment_provider.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/status_pill.dart';

class AssessmentHudScreen extends ConsumerStatefulWidget {
  const AssessmentHudScreen(
      {super.key, required this.roadmapId, required this.topicId});
  final String roadmapId;
  final String topicId;

  @override
  ConsumerState<AssessmentHudScreen> createState() =>
      _AssessmentHudScreenState();
}

class _AssessmentHudScreenState extends ConsumerState<AssessmentHudScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mastery Check'),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: AppTypography.badge(fontSize: 12.5),
          indicatorColor: AppColors.primaryCyan,
          tabs: const [
            Tab(text: 'Oral Defense'),
            Tab(text: 'Scenario MCQs'),
            Tab(text: 'Sequence Order'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OralDefenseTab(topicId: widget.topicId),
          _McqTab(topicId: widget.topicId),
          _SequenceOrderingTab(topicId: widget.topicId),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB 1 — FEYNMAN ORAL EXAM HUD
// ============================================================================

class _OralDefenseTab extends ConsumerStatefulWidget {
  const _OralDefenseTab({required this.topicId});
  final String topicId;

  @override
  ConsumerState<_OralDefenseTab> createState() => _OralDefenseTabState();
}

class _OralDefenseTabState extends ConsumerState<_OralDefenseTab> {
  OralSession? _session;
  int _probeIndex = 0;
  int _secondsLeft = 0;
  Timer? _timer;
  bool _recording = false;
  final Map<int, String> _transcripts = {};
  OralScoreBreakdown? _score;
  bool _loading = false;

  Future<void> _start() async {
    setState(() => _loading = true);
    final session =
        await ref.read(assessmentActionsProvider).startOral(widget.topicId);
    setState(() {
      _session = session;
      _probeIndex = 0;
      _loading = false;
      _secondsLeft = session.probes.first.timeLimitSeconds;
    });
  }

  void _toggleRecording() {
    setState(() => _recording = !_recording);
    if (_recording) {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_secondsLeft <= 1) {
          t.cancel();
          _nextProbe();
        } else {
          setState(() => _secondsLeft--);
        }
      });
    } else {
      _timer?.cancel();
    }
  }

  void _nextProbe() {
    _timer?.cancel();
    // Placeholder transcript — wire up real speech-to-text in production.
    _transcripts[_session!.probes[_probeIndex].index] = '[captured response]';
    if (_probeIndex < _session!.probes.length - 1) {
      setState(() {
        _probeIndex++;
        _secondsLeft = _session!.probes[_probeIndex].timeLimitSeconds;
        _recording = false;
      });
    } else {
      _evaluate();
    }
  }

  Future<void> _evaluate() async {
    setState(() => _loading = true);
    final result = await ref.read(assessmentActionsProvider).evaluateOral(
          sessionId: _session!.sessionId,
          transcriptsByProbe: _transcripts,
        );
    setState(() {
      _loading = false;
      _score = OralScoreBreakdown(
        eli5Score: result.scorePercent,
        tradeoffScore: result.scorePercent,
        applicationScore: result.scorePercent,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_score != null) return _ScoreGauge(score: _score!);

    if (_session == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Explain what you learned out loud — three timed probes.',
                textAlign: TextAlign.center,
                style: AppTypography.body(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              GradientButton(
                label: 'Begin Oral Defense',
                icon: Icons.mic_rounded,
                isLoading: _loading,
                expand: false,
                onPressed: _start,
              ),
            ],
          ),
        ),
      );
    }

    final probe = _session!.probes[_probeIndex];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StatusPill(
              label: 'Probe ${probe.index}/3 · ${probe.label}',
              tone: PillTone.indigo),
          const SizedBox(height: 20),
          Text(probe.prompt,
              textAlign: TextAlign.center,
              style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _toggleRecording,
            child: CircularPercentIndicator(
              radius: 90,
              lineWidth: 6,
              percent: _secondsLeft / probe.timeLimitSeconds,
              backgroundColor: AppColors.surfaceElevated,
              progressColor:
                  _recording ? AppColors.errorCoral : AppColors.primaryCyan,
              circularStrokeCap: CircularStrokeCap.round,
              animateFromLastPercent: true,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _recording ? Icons.stop_circle_rounded : Icons.mic_rounded,
                    size: 36,
                    color: _recording
                        ? AppColors.errorCoral
                        : AppColors.primaryCyan,
                  ),
                  const SizedBox(height: 6),
                  Text('${_secondsLeft}s',
                      style: AppTypography.heading(fontSize: 20)),
                ],
              ),
            ).animate(target: _recording ? 1 : 0).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.04, 1.04),
                  duration: 600.ms,
                ),
          ),
          const SizedBox(height: 20),
          Text(
            _recording ? 'Listening… tap to stop' : 'Tap the mic to answer',
            style: AppTypography.body(
                fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ScoreGauge extends StatelessWidget {
  const _ScoreGauge({required this.score});
  final OralScoreBreakdown score;

  @override
  Widget build(BuildContext context) {
    final passed = score.overall >= 80;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularPercentIndicator(
              radius: 90,
              lineWidth: 12,
              percent: (score.overall / 100).clamp(0, 1),
              backgroundColor: AppColors.surfaceElevated,
              progressColor:
                  passed ? AppColors.masteryVerified : AppColors.errorCoral,
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
              animationDuration: 900,
              center: Text('${score.overall.toStringAsFixed(0)}%',
                  style: AppTypography.heading(fontSize: 28)),
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            _ScoreRow(label: 'ELI5', value: score.eli5Score),
            _ScoreRow(label: 'Trade-offs', value: score.tradeoffScore),
            _ScoreRow(label: 'Application', value: score.applicationScore),
            const SizedBox(height: 16),
            Text(
              passed
                  ? '🎉 Mastery verified! Next topic unlocked.'
                  : 'Not quite — review and retry.',
              style: AppTypography.heading(
                  fontSize: 16,
                  color: passed
                      ? AppColors.masteryVerified
                      : AppColors.errorCoral),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 90,
              child: Text(label, style: AppTypography.body(fontSize: 13))),
          Expanded(
            child: LinearPercentIndicator(
              lineHeight: 6,
              percent: (value / 100).clamp(0, 1),
              backgroundColor: AppColors.surfaceElevated,
              progressColor: AppColors.primaryCyan,
              barRadius: const Radius.circular(4),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 8),
          Text('${value.toStringAsFixed(0)}%',
              style: AppTypography.body(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB 2 — DIAGNOSTIC MCQs
// ============================================================================

class _McqTab extends ConsumerStatefulWidget {
  const _McqTab({required this.topicId});
  final String topicId;

  @override
  ConsumerState<_McqTab> createState() => _McqTabState();
}

class _McqTabState extends ConsumerState<_McqTab> {
  // In production these come from GET /api/assessments/topic/:topicId.
  final List<McqQuestion> _questions = const [];
  final Map<String, String> _selected = {};
  final Map<String, bool> _revealed = {};

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Center(
        child: Text(
          'No scenario questions loaded for this topic yet.',
          style:
              AppTypography.body(fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _questions.length,
      itemBuilder: (context, i) {
        final q = _questions[i];
        final revealed = _revealed[q.id] ?? false;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.scenario, style: AppTypography.heading(fontSize: 15)),
                const SizedBox(height: 10),
                for (final opt in q.options)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: InkWell(
                      onTap: revealed
                          ? null
                          : () => setState(() {
                                _selected[q.id] = opt.id;
                                _revealed[q.id] = true;
                              }),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: !revealed
                              ? AppColors.surfaceElevated
                              : (opt.isCorrect
                                  ? AppColors.masteryVerified
                                      .withValues(alpha: 0.14)
                                  : (_selected[q.id] == opt.id
                                      ? AppColors.errorCoral
                                          .withValues(alpha: 0.14)
                                      : AppColors.surfaceElevated)),
                          border: Border.all(
                            color: !revealed
                                ? AppColors.surfaceBorder
                                : (opt.isCorrect
                                    ? AppColors.masteryVerified
                                    : AppColors.surfaceBorder),
                          ),
                        ),
                        child: Text(opt.text,
                            style: AppTypography.body(fontSize: 13.5)),
                      ),
                    ),
                  ),
                if (revealed)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      q.options
                              .firstWhere((o) => o.id == _selected[q.id])
                              .rationale ??
                          '',
                      style: AppTypography.body(
                          fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// TAB 3 — SEQUENCE ORDERING CHALLENGE
// ============================================================================

class _SequenceOrderingTab extends ConsumerStatefulWidget {
  const _SequenceOrderingTab({required this.topicId});
  final String topicId;

  @override
  ConsumerState<_SequenceOrderingTab> createState() =>
      _SequenceOrderingTabState();
}

class _SequenceOrderingTabState extends ConsumerState<_SequenceOrderingTab> {
  // In production, seeded from GET /api/assessments/topic/:topicId.
  late final List<String> _items = [
    'SELECT',
    'FROM',
    'WHERE',
    'GROUP BY',
    'HAVING',
    'ORDER BY'
  ];

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Drag to arrange the correct SQL query execution order.',
            style: AppTypography.body(
                fontSize: 13.5, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: ReorderableListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            // ignore: deprecated_member_use
            onReorder: _reorder,
            children: [
              for (int i = 0; i < _items.length; i++)
                GlassCard(
                  key: ValueKey(_items[i]),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      StatusPill(
                          label: '${i + 1}',
                          tone: PillTone.indigo,
                          dense: true),
                      const SizedBox(width: 12),
                      Text(_items[i], style: AppTypography.code(fontSize: 14)),
                      const Spacer(),
                      const Icon(Icons.drag_handle_rounded,
                          color: AppColors.textMuted),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: GradientButton(
              label: 'Submit Order',
              icon: Icons.check_rounded,
              onPressed: () {}),
        ),
      ],
    );
  }
}
