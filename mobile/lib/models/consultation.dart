enum ChatRole { user, ai }

class ConsultationMessage {
  final String id;
  final ChatRole role;
  final String content;
  final List<String> quickReplies;
  final DateTime timestamp;

  const ConsultationMessage({
    required this.id,
    required this.role,
    required this.content,
    this.quickReplies = const [],
    required this.timestamp,
  });

  factory ConsultationMessage.fromJson(Map<String, dynamic> json) {
    return ConsultationMessage(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      role: (json['role'] == 'user') ? ChatRole.user : ChatRole.ai,
      content: json['content'] ?? '',
      quickReplies: (json['quickReplies'] as List? ?? []).map((e) => e.toString()).toList(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Session state for the diagnostic consultation, including the progress
/// meter that reveals the "Generate Calibrated Roadmap" CTA.
class ConsultationSession {
  final String sessionId;
  final String domainCategoryId;
  final List<ConsultationMessage> messages;
  final double progress; // 0.0 - 1.0
  final bool readyToFinalize;

  const ConsultationSession({
    required this.sessionId,
    required this.domainCategoryId,
    this.messages = const [],
    this.progress = 0.0,
    this.readyToFinalize = false,
  });

  factory ConsultationSession.fromJson(Map<String, dynamic> json) {
    return ConsultationSession(
      sessionId: json['sessionId']?.toString() ?? '',
      domainCategoryId: json['domainCategoryId']?.toString() ?? '',
      messages: (json['messages'] as List? ?? [])
          .map((e) => ConsultationMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      readyToFinalize: json['readyToFinalize'] ?? false,
    );
  }

  ConsultationSession copyWith({
    List<ConsultationMessage>? messages,
    double? progress,
    bool? readyToFinalize,
  }) {
    return ConsultationSession(
      sessionId: sessionId,
      domainCategoryId: domainCategoryId,
      messages: messages ?? this.messages,
      progress: progress ?? this.progress,
      readyToFinalize: readyToFinalize ?? this.readyToFinalize,
    );
  }
}
