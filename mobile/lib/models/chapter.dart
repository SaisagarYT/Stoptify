/// An interactive lab exercise embedded in a chapter — a dark IDE query
/// block with copy-code affordance and a verification checklist.
class InteractiveLab {
  final String title;
  final String language; // e.g. "sql", "javascript"
  final String code;
  final List<String> verificationChecklist;

  const InteractiveLab({
    required this.title,
    required this.language,
    required this.code,
    this.verificationChecklist = const [],
  });

  factory InteractiveLab.fromJson(Map<String, dynamic> json) {
    return InteractiveLab(
      title: json['title'] ?? '',
      language: json['language'] ?? 'text',
      code: json['code'] ?? '',
      verificationChecklist:
          (json['verificationChecklist'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }
}

class ChapterContent {
  final String topicId;
  final String conceptualGuideMarkdown;
  final List<InteractiveLab> labs;
  final String? mermaidDiagram; // raw mermaid definition string

  const ChapterContent({
    required this.topicId,
    required this.conceptualGuideMarkdown,
    this.labs = const [],
    this.mermaidDiagram,
  });

  factory ChapterContent.fromJson(Map<String, dynamic> json) {
    return ChapterContent(
      topicId: json['topicId']?.toString() ?? '',
      conceptualGuideMarkdown: json['conceptualGuideMarkdown'] ?? json['markdown'] ?? '',
      labs: (json['labs'] as List? ?? [])
          .map((e) => InteractiveLab.fromJson(e as Map<String, dynamic>))
          .toList(),
      mermaidDiagram: json['mermaidDiagram'],
    );
  }
}
