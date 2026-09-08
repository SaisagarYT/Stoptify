import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_endpoints.dart';
import '../models/assessment.dart';
import 'core_providers.dart';

/// Assessments available for a topic (oral / mcq / sequence_ordering tabs).
final topicAssessmentsProvider = FutureProvider.family<List<String>, String>((ref, topicId) async {
  final api = ref.watch(apiClientProvider);
  final envelope = await api.get(ApiEndpoints.assessmentsForTopic(topicId));
  return (envelope.data as List).map((e) => e.toString()).toList();
});

class AssessmentActions {
  AssessmentActions(this.ref);
  final Ref ref;

  Future<OralSession> startOral(String topicId) async {
    final api = ref.read(apiClientProvider);
    final envelope = await api.post(ApiEndpoints.oralStart, body: {'topicId': topicId});
    return OralSession.fromJson(envelope.data as Map<String, dynamic>);
  }

  Future<AssessmentResult> evaluateOral({
    required String sessionId,
    required Map<int, String> transcriptsByProbe,
  }) async {
    final api = ref.read(apiClientProvider);
    final envelope = await api.post(ApiEndpoints.oralEvaluate, body: {
      'sessionId': sessionId,
      'responses': transcriptsByProbe.entries
          .map((e) => {'probeIndex': e.key, 'transcript': e.value})
          .toList(),
    });
    return AssessmentResult.fromJson(envelope.data as Map<String, dynamic>);
  }

  Future<AssessmentResult> submitMcq({
    required String assessmentId,
    required Map<String, String> answersByQuestionId,
  }) async {
    final api = ref.read(apiClientProvider);
    final envelope = await api.post(
      ApiEndpoints.submitMcq(assessmentId),
      body: {'answers': answersByQuestionId},
    );
    return AssessmentResult.fromJson(envelope.data as Map<String, dynamic>);
  }

  Future<AssessmentResult> submitOrdering({
    required String assessmentId,
    required List<String> orderedItems,
  }) async {
    final api = ref.read(apiClientProvider);
    final envelope = await api.post(
      ApiEndpoints.submitOrdering(assessmentId),
      body: {'order': orderedItems},
    );
    return AssessmentResult.fromJson(envelope.data as Map<String, dynamic>);
  }
}

final assessmentActionsProvider = Provider((ref) => AssessmentActions(ref));
