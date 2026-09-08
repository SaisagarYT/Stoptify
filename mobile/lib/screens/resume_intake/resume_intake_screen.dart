import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/resume_analysis.dart';
import '../../providers/resume_provider.dart';
import '../../widgets/common/monochrome_button.dart';
import '../../widgets/common/monochrome_text_field.dart';

// Modern SaaS Resume Intake and 5-Question Dynamic Diagnostic Screen
class ResumeIntakeScreen extends ConsumerStatefulWidget {
  const ResumeIntakeScreen({super.key});

  @override
  ConsumerState<ResumeIntakeScreen> createState() => _ResumeIntakeScreenState();
}

class _ResumeIntakeScreenState extends ConsumerState<ResumeIntakeScreen> {
  final _textController = TextEditingController();
  final _answerController = TextEditingController();

  int _currentQuestionIndex = 0;
  final Map<int, String> _userAnswers = {};
  bool _isCalibrating = false;

  @override
  void dispose() {
    _textController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  // Picks resume file of specific extensions from device
  Future<void> _pickFile(List<String> extensions) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    final path = result?.files.single.path;
    if (path != null) {
      await ref.read(resumeAnalysisProvider.notifier).analyze(filePath: path);
    }
  }

  // Starts analysis from pasted text
  Future<void> _analyzeText() async {
    if (_textController.text.trim().length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please enter at least 20 characters of resume content.')),
      );
      return;
    }
    await ref
        .read(resumeAnalysisProvider.notifier)
        .analyze(resumeText: _textController.text.trim());
  }

  // Proceeds to next question or finalizes roadmap
  Future<void> _handleNextQuestion(
      List<DiagnosticQuestion> questions, ResumeAnalysisResult analysis) async {
    final currentAnswer = _answerController.text.trim();
    if (currentAnswer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter your response before proceeding.')),
      );
      return;
    }

    _userAnswers[_currentQuestionIndex] = currentAnswer;

    if (_currentQuestionIndex < questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _answerController.text = _userAnswers[_currentQuestionIndex] ?? '';
      });
    } else {
      // All questions answered — evaluate diagnostic audit
      setState(() => _isCalibrating = true);

      final qaPayload = questions.asMap().entries.map((entry) {
        return {
          'question': entry.value.question,
          'answer': _userAnswers[entry.key] ?? '',
        };
      }).toList();

      final audit =
          await ref.read(resumeAnalysisProvider.notifier).evaluateDiagnostic(
                resumeSummary: analysis.candidateSummary,
                qaAnswers: qaPayload,
              );

      if (mounted) {
        setState(() => _isCalibrating = false);
        if (audit != null) {
          context.push(
            RoutePaths.diagnosticAudit,
            extra: {
              'audit': audit,
              'resumeSummary': analysis.candidateSummary,
              'qaAnswers': qaPayload,
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to evaluate diagnostic. Please retry.'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resumeAnalysisProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: state.result != null && _currentQuestionIndex > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.textPrimary),
                onPressed: () {
                  setState(() {
                    _currentQuestionIndex--;
                    _answerController.text =
                        _userAnswers[_currentQuestionIndex] ?? '';
                  });
                },
              )
            : null,
        title: Text(
          state.result == null ? 'Resume Verification' : 'Skill Diagnostic',
          style: AppTypography.heading(fontSize: 18, weight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: state.result == null
            ? _buildUploadStage(state)
            : _isCalibrating
                ? _buildCalibratingStage()
                : _buildDiagnosticStage(state.result!),
      ),
    );
  }

  // Stage 1: Upload or paste resume
  Widget _buildUploadStage(ResumeAnalysisState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Upload your resume',
              style:
                  AppTypography.heading(fontSize: 24, weight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Our AI will extract your claimed technologies and generate 5 focused questions to verify your true skill level and goals.',
              style: AppTypography.body(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Format Button 1: PDF
            _FormatUploadButton(
              title: 'Upload PDF Document',
              subtitle: 'Standard resume (.pdf)',
              badge: 'PDF',
              icon: Icons.picture_as_pdf_rounded,
              disabled: state.isAnalyzing,
              onTap: () => _pickFile(['pdf']),
            ),

            // Format Button 2: Word / DOCX
            _FormatUploadButton(
              title: 'Upload Word Document',
              subtitle: 'Microsoft Word (.docx, .doc)',
              badge: 'DOCX',
              icon: Icons.article_rounded,
              disabled: state.isAnalyzing,
              onTap: () => _pickFile(['docx', 'doc']),
            ),

            // Format Button 3: Plain Text
            _FormatUploadButton(
              title: 'Upload Plain Text',
              subtitle: 'Plain text file (.txt, .md)',
              badge: 'TXT',
              icon: Icons.description_rounded,
              disabled: state.isAnalyzing,
              onTap: () => _pickFile(['txt', 'md']),
            ),

            if (state.isAnalyzing) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderStrong, width: 1),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.buttonPrimary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Extracting content & generating questions...',
                        style: AppTypography.body(
                            fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.borderSubtle)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text('OR PASTE RESUME TEXT',
                      style: AppTypography.heading(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          weight: FontWeight.w700)),
                ),
                const Expanded(child: Divider(color: AppColors.borderSubtle)),
              ],
            ),

            const SizedBox(height: 16),
            Text(
              'No document file on hand? Paste your resume, summary, or LinkedIn text directly:',
              style: AppTypography.body(
                  fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),

            // Text Paste Area
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle, width: 1.2),
              ),
              child: TextField(
                controller: _textController,
                maxLines: 7,
                style: AppTypography.body(
                    fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText:
                      'Paste resume text, skills, or LinkedIn experience here…',
                  hintStyle: AppTypography.body(
                      fontSize: 13.5, color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            if (state.error != null) ...[
              const SizedBox(height: 14),
              Text(state.error!,
                  style: AppTypography.body(
                      fontSize: 12.5, color: AppColors.errorRed)),
            ],

            const SizedBox(height: 24),

            MonochromeButton(
              label: 'Analyze & Begin Diagnostic',
              icon: Icons.auto_awesome_rounded,
              isLoading: state.isAnalyzing,
              onPressed: _analyzeText,
            ),
          ],
        ),
      ),
    );
  }

  // Stage 2: Dynamic 5-Question Single-Field Diagnostic
  Widget _buildDiagnosticStage(ResumeAnalysisResult analysis) {
    final questions = analysis.diagnosticQuestions;
    if (questions.isEmpty) return const SizedBox.shrink();

    final currentQ = questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / questions.length;
    final isLast = _currentQuestionIndex == questions.length - 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${questions.length}',
                  style: AppTypography.heading(
                      fontSize: 13.5,
                      weight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                Text(
                  '${(progress * 100).toInt()}% completed',
                  style: AppTypography.body(
                      fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Animated Progress Line
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surfaceElevated,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.buttonPrimary),
                minHeight: 5,
              ),
            ),

            const SizedBox(height: 28),

            // Question Container
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: AppColors.borderStrong, width: 1),
                    ),
                    child: Text(
                      currentQ.category.toUpperCase(),
                      style: AppTypography.heading(
                          fontSize: 10.5,
                          weight: FontWeight.w700,
                          color: AppColors.textSecondary),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Question Text
                  Text(
                    currentQ.question,
                    style: AppTypography.heading(
                        fontSize: 17, weight: FontWeight.w700, height: 1.35),
                  ),

                  const SizedBox(height: 10),

                  // Hint Text
                  Text(
                    currentQ.hint,
                    style: AppTypography.body(
                        fontSize: 12.5, color: AppColors.textSecondary),
                  ),

                  const SizedBox(height: 22),

                  // Single Input Field
                  MonochromeTextField(
                    controller: _answerController,
                    label: 'Your Answer',
                    hint: 'Type your honest response…',
                    keyboardType: TextInputType.text,
                    onChanged: (text) =>
                        _userAnswers[_currentQuestionIndex] = text,
                  ),
                ],
              ),
            )
                .animate(key: ValueKey('question_card_$_currentQuestionIndex'))
                .fadeIn(duration: 250.ms)
                .slideY(begin: 0.04, end: 0),

            const SizedBox(height: 24),

            // Next / Finalize Button
            MonochromeButton(
              label: isLast ? 'Calibrate & Build Roadmap' : 'Next Question',
              icon: isLast
                  ? Icons.auto_awesome_rounded
                  : Icons.arrow_forward_rounded,
              isLoading: _isCalibrating,
              onPressed: () => _handleNextQuestion(questions, analysis),
            ),
          ],
        ),
      ),
    );
  }

  // Stage 3: Calibrating Screen
  Widget _buildCalibratingStage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.buttonPrimary),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Evaluating AI Skill Audit',
              style:
                  AppTypography.heading(fontSize: 20, weight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Auditing your diagnostic answers against claimed resume skills to detect fragile gaps and eliminate tutorial fluff…',
              textAlign: TextAlign.center,
              style: AppTypography.body(
                  fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable format-specific upload card button
class _FormatUploadButton extends StatelessWidget {
  const _FormatUploadButton({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.onTap,
    this.disabled = false,
  });

  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderStrong, width: 1),
                  ),
                  child: Icon(icon, color: AppColors.textPrimary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.heading(
                          fontSize: 14.5,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTypography.body(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderSubtle, width: 1),
                  ),
                  child: Text(
                    badge,
                    style: AppTypography.heading(
                      fontSize: 11,
                      weight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
