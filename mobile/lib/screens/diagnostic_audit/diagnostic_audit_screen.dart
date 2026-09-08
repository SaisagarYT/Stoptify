import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/diagnostic_audit.dart';
import '../../providers/resume_provider.dart';
import '../../widgets/common/monochrome_button.dart';

/// Screen 4: AI Skill Audit & Target Track Confirmation Screen
///
/// Presents the candidate's reality-check verdict, verified strengths,
/// fragile tutorial gaps, anti-scope hours saved, and lets them confirm
/// their specialized target track before generating the custom roadmap.
class DiagnosticAuditScreen extends ConsumerStatefulWidget {
  const DiagnosticAuditScreen({
    super.key,
    required this.audit,
    required this.resumeSummary,
    required this.qaAnswers,
  });

  final DiagnosticAuditResult audit;
  final String resumeSummary;
  final List<Map<String, String>> qaAnswers;

  @override
  ConsumerState<DiagnosticAuditScreen> createState() =>
      _DiagnosticAuditScreenState();
}

class _DiagnosticAuditScreenState extends ConsumerState<DiagnosticAuditScreen> {
  late String _selectedTrackId;
  late String _selectedTrackTitle;
  bool _isGeneratingRoadmap = false;

  @override
  void initState() {
    super.initState();
    if (widget.audit.recommendedTracks.isNotEmpty) {
      _selectedTrackId = widget.audit.recommendedTracks.first.trackId;
      _selectedTrackTitle = widget.audit.recommendedTracks.first.title;
    } else {
      _selectedTrackId = 'backend-systems';
      _selectedTrackTitle = 'Backend Systems Engineering';
    }
  }

  Future<void> _generateRoadmap() async {
    setState(() => _isGeneratingRoadmap = true);

    final roadmapId =
        await ref.read(resumeAnalysisProvider.notifier).calibrateRoadmap(
              resumeSummary: widget.resumeSummary,
              targetDomain: _selectedTrackTitle,
              qaAnswers: widget.qaAnswers,
            );

    if (roadmapId != null && mounted) {
      context.go(RoutePaths.roadmapDashboardFor(roadmapId));
    } else {
      if (mounted) {
        setState(() => _isGeneratingRoadmap = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to synthesize roadmap. Please retry.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final audit = widget.audit;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Diagnostic Audit',
          style: AppTypography.heading(fontSize: 18, weight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Reality Check Verdict Card
                  _buildVerdictCard(audit),
                  const SizedBox(height: 16),

                  // 2. Anti-Scope Savings Banner
                  _buildAntiScopeBanner(audit.antiScopeBypass),
                  const SizedBox(height: 24),

                  // 3. Verified Strengths Section
                  _buildSectionHeader(
                    title: 'VERIFIED PRODUCTION STRENGTHS',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.successGreen,
                  ),
                  const SizedBox(height: 10),
                  ...audit.verifiedStrengths.map((s) => _buildStrengthCard(s)),
                  const SizedBox(height: 24),

                  // 4. Fragile Gaps & Vulnerabilities Section
                  _buildSectionHeader(
                    title: 'FRAGILE GAPS & RISKS',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.warningAmber,
                  ),
                  const SizedBox(height: 10),
                  ...audit.fragileGaps.map((g) => _buildGapCard(g)),
                  const SizedBox(height: 28),

                  // 5. Target Career Track Selector
                  _buildSectionHeader(
                    title: 'CONFIRM YOUR TARGET TRACK',
                    icon: Icons.route_rounded,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select which specialized path to calibrate your curriculum for:',
                    style: AppTypography.body(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  ...audit.recommendedTracks.map((t) => _buildTrackCard(t)),
                  const SizedBox(height: 28),

                  // 6. Primary Action CTA
                  MonochromeButton(
                    label: 'Generate Calibrated Roadmap',
                    icon: Icons.auto_awesome_rounded,
                    isLoading: _isGeneratingRoadmap,
                    onPressed: _generateRoadmap,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Reality Check Card with Gauge Score and Verdict Headline
  Widget _buildVerdictCard(DiagnosticAuditResult audit) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Readiness Score Ring
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceElevated,
                  border: Border.all(color: AppColors.borderStrong, width: 1.5),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${audit.readinessScore}%',
                        style: AppTypography.heading(
                          fontSize: 17,
                          weight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'READY',
                        style: AppTypography.body(
                          fontSize: 9,
                          weight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'AI AUDIT VERDICT',
                        style: AppTypography.heading(
                          fontSize: 10,
                          weight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      audit.verdictTitle,
                      style: AppTypography.heading(
                        fontSize: 15,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 14),
          Text(
            audit.confidenceSummary,
            style: AppTypography.body(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  // Anti-Scope Savings Banner
  Widget _buildAntiScopeBanner(AntiScopeBypass bypass) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderStrong, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded,
                  color: AppColors.warningAmber, size: 22),
              const SizedBox(width: 8),
              Text(
                '~${bypass.hoursSaved} Hours of Fluff Eliminated',
                style: AppTypography.heading(
                  fontSize: 14.5,
                  weight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderSubtle, width: 1),
                ),
                child: Text(
                  '${bypass.bypassPercentage} Bypass',
                  style: AppTypography.heading(
                    fontSize: 11,
                    weight: FontWeight.w700,
                    color: AppColors.successGreen,
                  ),
                ),
              ),
            ],
          ),
          if (bypass.topicsSkipped.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Skipping verified beginner fundamentals:',
              style: AppTypography.body(
                  fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: bypass.topicsSkipped.map((topic) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderSubtle, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_rounded,
                          size: 13, color: AppColors.successGreen),
                      const SizedBox(width: 5),
                      Text(
                        topic,
                        style: AppTypography.body(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // Section Header with Icon
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.heading(
            fontSize: 12,
            weight: FontWeight.w700,
            color: color == AppColors.textPrimary
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // Verified Strength Card
  Widget _buildStrengthCard(VerifiedStrength strength) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle, width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded,
                  size: 16, color: AppColors.successGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strength.skill,
                  style: AppTypography.heading(
                    fontSize: 14,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            strength.reason,
            style: AppTypography.body(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Fragile Gap Card
  Widget _buildGapCard(FragileGap gap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle, width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 16, color: AppColors.warningAmber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  gap.skill,
                  style: AppTypography.heading(
                    fontSize: 14,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            gap.risk,
            style: AppTypography.body(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Selectable Target Track Card
  Widget _buildTrackCard(RecommendedTrack track) {
    final isSelected = _selectedTrackId == track.trackId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.surfaceElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.borderFocus : AppColors.borderSubtle,
          width: isSelected ? 1.6 : 1.1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            setState(() {
              _selectedTrackId = track.trackId;
              _selectedTrackTitle = track.title;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Radio indicator
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.buttonPrimary
                          : AppColors.borderStrong,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.buttonPrimary,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              track.title,
                              style: AppTypography.heading(
                                fontSize: 14.5,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppColors.borderSubtle, width: 1),
                            ),
                            child: Text(
                              '${track.matchScore}% Match',
                              style: AppTypography.heading(
                                fontSize: 11,
                                weight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        track.tagline,
                        style: AppTypography.body(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '⏱️ ~${track.estimatedWeeks} weeks to mastery',
                        style: AppTypography.body(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
