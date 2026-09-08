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
}

final resumeAnalysisProvider =
    StateNotifierProvider<ResumeAnalysisNotifier, ResumeAnalysisState>((ref) {
  return ResumeAnalysisNotifier(ref);
});
