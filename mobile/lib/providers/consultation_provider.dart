import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_endpoints.dart';
import '../models/consultation.dart';
import 'core_providers.dart';

class ConsultationNotifier extends StateNotifier<ConsultationSession?> {
  ConsultationNotifier(this.ref) : super(null);

  final Ref ref;
  bool isSending = false;

  Future<void> start(String domainCategoryId) async {
    final api = ref.read(apiClientProvider);
    final envelope = await api.post(
      ApiEndpoints.consultationStart,
      body: {'domainCategoryId': domainCategoryId},
    );
    state = ConsultationSession.fromJson(envelope.data as Map<String, dynamic>);
  }

  Future<void> sendMessage(String content) async {
    if (state == null) return;
    final api = ref.read(apiClientProvider);

    final userMsg = ConsultationMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: ChatRole.user,
      content: content,
      timestamp: DateTime.now(),
    );
    state = state!.copyWith(messages: [...state!.messages, userMsg]);

    final envelope = await api.post(
      ApiEndpoints.consultationMessage,
      body: {'sessionId': state!.sessionId, 'message': content},
    );
    final data = envelope.data as Map<String, dynamic>;
    final aiMsg = ConsultationMessage.fromJson(data['message'] as Map<String, dynamic>);
    state = state!.copyWith(
      messages: [...state!.messages, aiMsg],
      progress: (data['progress'] as num?)?.toDouble() ?? state!.progress,
      readyToFinalize: data['readyToFinalize'] ?? state!.readyToFinalize,
    );
  }

  /// Returns the newly generated roadmap ID.
  Future<String> finalize() async {
    if (state == null) throw StateError('No active consultation session');
    final api = ref.read(apiClientProvider);
    final envelope = await api.post(
      ApiEndpoints.consultationFinalize,
      body: {'sessionId': state!.sessionId},
    );
    final data = envelope.data as Map<String, dynamic>;
    return data['roadmapId'].toString();
  }
}

final consultationProvider =
    StateNotifierProvider<ConsultationNotifier, ConsultationSession?>((ref) {
  return ConsultationNotifier(ref);
});
