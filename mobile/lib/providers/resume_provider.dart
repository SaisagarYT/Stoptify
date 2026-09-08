import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_endpoints.dart';
import '../models/resume_analysis.dart';
import 'core_providers.dart';

class ResumeAnalysisState {
  final bool isAnalyzing;
  final ResumeAnalysisResult? result;
  final String? selectedDomainCategoryId;
  final String? error;

  const ResumeAnalysisState({
    this.isAnalyzing = false,
    this.result,
    this.selectedDomainCategoryId,
    this.error,
  });

  ResumeAnalysisState copyWith({
    bool? isAnalyzing,
    ResumeAnalysisResult? result,
    String? selectedDomainCategoryId,
    String? error,
  }) {
    return ResumeAnalysisState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      result: result ?? this.result,
      selectedDomainCategoryId: selectedDomainCategoryId ?? this.selectedDomainCategoryId,
      error: error,
    );
  }
}

class ResumeAnalysisNotifier extends StateNotifier<ResumeAnalysisState> {
  ResumeAnalysisNotifier(this.ref) : super(const ResumeAnalysisState());

  final Ref ref;

  /// Submits either raw resume text or an uploaded file path.
  Future<void> analyze({String? resumeText, String? filePath}) async {
    state = state.copyWith(isAnalyzing: true, error: null);
    final api = ref.read(apiClientProvider);
    try {
      FormData? formData;
      Map<String, dynamic>? body;
      if (filePath != null) {
        formData = FormData.fromMap({'resume': await MultipartFile.fromFile(filePath)});
      } else {
        body = {'resumeText': resumeText};
      }
      final envelope = await api.post(
        ApiEndpoints.analyzeResume,
        body: body,
        formData: formData,
      );
      state = state.copyWith(
        isAnalyzing: false,
        result: ResumeAnalysisResult.fromJson(envelope.data as Map<String, dynamic>),
      );
    } catch (e) {
      state = state.copyWith(isAnalyzing: false, error: e.toString());
    }
  }

  void selectDomain(String domainCategoryId) {
    state = state.copyWith(selectedDomainCategoryId: domainCategoryId);
  }

  // Calibrates custom roadmap from the 5 diagnostic inquiry answers
  Future<String?> calibrateRoadmap({
    required String resumeSummary,
    required String targetDomain,
    required List<Map<String, String>> qaAnswers,
  }) async {
    final api = ref.read(apiClientProvider);
    try {
      final envelope = await api.post(
        ApiEndpoints.calibrateFromInquiry,
        body: {
          'resumeSummary': resumeSummary,
          'targetDomain': targetDomain,
          'qaAnswers': qaAnswers,
        },
      );
      final data = envelope.data as Map<String, dynamic>;
      final roadmap = data['roadmap'] as Map<String, dynamic>?;
      return roadmap?['id']?.toString() ?? data['roadmapId']?.toString();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
}

final resumeAnalysisProvider =
    StateNotifierProvider<ResumeAnalysisNotifier, ResumeAnalysisState>((ref) {
  return ResumeAnalysisNotifier(ref);
});
