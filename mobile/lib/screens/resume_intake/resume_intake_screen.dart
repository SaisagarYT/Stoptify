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

  // Picks resume file from device
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
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
        const SnackBar(content: Text('Please enter at least 20 characters of resume content.')),
      );
      return;
    }
    await ref.read(resumeAnalysisProvider.notifier).analyze(resumeText: _textController.text.trim());
  }

  // Proceeds to next question or finalizes roadmap
  Future<void> _handleNextQuestion(List<DiagnosticQuestion> questions, ResumeAnalysisResult analysis) async {
    final currentAnswer = _answerController.text.trim();
    if (currentAnswer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your response before proceeding.')),
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
      // All questions answered — calibrate roadmap
      setState(() => _isCalibrating = true);

      final qaPayload = questions.asMap().entries.map((entry) {
        return {
          'question': entry.value.question,
          'answer': _userAnswers[entry.key] ?? '',
        };
      }).toList();

      final targetDomain = analysis.domainCategories.isNotEmpty
          ? analysis.domainCategories.first.title
          : 'Software Engineering';

      final roadmapId = await ref.read(resumeAnalysisProvider.notifier).calibrateRoadmap(
            resumeSummary: analysis.candidateSummary,
            targetDomain: targetDomain,
            qaAnswers: qaPayload,
          );

      if (roadmapId != null && mounted) {
        context.go(RoutePaths.roadmapDashboardFor(roadmapId));
      } else {
        setState(() => _isCalibrating = false);
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
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                onPressed: () {
                  setState(() {
                    _currentQuestionIndex--;
                    _answerController.text = _userAnswers[_currentQuestionIndex] ?? '';
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
              style: AppTypography.heading(fontSize: 24, weight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Our AI will extract your claimed technologies and generate 5 focused questions to verify your true skill level and goals.',
              style: AppTypography.body(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),

            // Dropzone Container
            InkWell(
              onTap: state.isAnalyzing ? null : _pickFile,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle, width: 1.2),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderStrong, width: 1),
                      ),
                      child: const Icon(Icons.upload_file_rounded, size: 28, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Tap to upload PDF or TXT resume',
                      style: AppTypography.heading(fontSize: 15, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Supports standard PDF and plain text',
                      style: AppTypography.body(fontSize: 12.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.borderSubtle)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text('OR PASTE TEXT', style: AppTypography.heading(fontSize: 11, color: AppColors.textMuted)),
                ),
                const Expanded(child: Divider(color: AppColors.borderSubtle)),
              ],
            ),

            const SizedBox(height: 20),

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
                style: AppTypography.body(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Paste resume text, skills, or LinkedIn experience here…',
                  hintStyle: AppTypography.body(fontSize: 13.5, color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            if (state.error != null) ...[
              const SizedBox(height: 14),
              Text(state.error!, style: AppTypography.body(fontSize: 12.5, color: AppColors.errorRed)),
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
                  style: AppTypography.heading(fontSize: 13.5, weight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Text(
                  '${(progress * 100).toInt()}% completed',
                  style: AppTypography.body(fontSize: 12.5, color: AppColors.textSecondary),
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
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.buttonPrimary),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderStrong, width: 1),
                    ),
                    child: Text(
                      currentQ.category.toUpperCase(),
                      style: AppTypography.heading(fontSize: 10.5, weight: FontWeight.w700, color: AppColors.textSecondary),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Question Text
                  Text(
                    currentQ.question,
                    style: AppTypography.heading(fontSize: 17, weight: FontWeight.w700, height: 1.35),
                  ),

                  const SizedBox(height: 10),

                  // Hint Text
                  Text(
                    currentQ.hint,
                    style: AppTypography.body(fontSize: 12.5, color: AppColors.textSecondary),
                  ),

                  const SizedBox(height: 22),

                  // Single Input Field
                  MonochromeTextField(
                    controller: _answerController,
                    label: 'Your Answer',
                    hint: 'Type your honest response…',
                    keyboardType: TextInputType.text,
                    onChanged: (text) => _userAnswers[_currentQuestionIndex] = text,
                  ),
                ],
              ),
            ).animate(key: ValueKey('question_card_$_currentQuestionIndex')).fadeIn(duration: 250.ms).slideY(begin: 0.04, end: 0),

            const SizedBox(height: 24),

            // Next / Finalize Button
            MonochromeButton(
              label: isLast ? 'Calibrate & Build Roadmap' : 'Next Question',
              icon: isLast ? Icons.auto_awesome_rounded : Icons.arrow_forward_rounded,
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
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.buttonPrimary),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Calibrating Custom Roadmap',
              style: AppTypography.heading(fontSize: 20, weight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Synthesizing 3-Tier Definition of Done and explicit Anti-Scope boundaries based on your diagnostic answers…',
              textAlign: TextAlign.center,
              style: AppTypography.body(fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
