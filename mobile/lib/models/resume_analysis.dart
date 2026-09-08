/// A single detected skill from resume analysis
class DetectedSkill {
  final String name;
  final double rating; // 1-5
  final String? evidence;

  const DetectedSkill(
      {required this.name, required this.rating, this.evidence});

  factory DetectedSkill.fromJson(Map<String, dynamic> json) {
    return DetectedSkill(
      name: json['name'] ?? json['skillName'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ??
          (json['proficiencyLevel'] as num?)?.toDouble() ??
          1.0,
      evidence: json['evidence']?.toString(),
    );
  }
}

/// A dynamic diagnostic question generated based on the user's resume
class DiagnosticQuestion {
  final String id;
  final String category;
  final String question;
  final String hint;

  const DiagnosticQuestion({
    required this.id,
    required this.category,
    required this.question,
    required this.hint,
  });

  factory DiagnosticQuestion.fromJson(Map<String, dynamic> json) {
    return DiagnosticQuestion(
      id: json['id']?.toString() ?? 'q1',
      category: json['category']?.toString() ?? 'Skill Verification',
      question: json['question']?.toString() ?? '',
      hint: json['hint']?.toString() ??
          'Answer honestly to skip topics you already know.',
    );
  }
}

/// A selectable domain category card, e.g. "SQL & Database Engineering".
class DomainCategory {
  final String id;
  final String title;
  final double matchPercentage;
  final bool isCustom;

  const DomainCategory({
    required this.id,
    required this.title,
    required this.matchPercentage,
    this.isCustom = false,
  });

  factory DomainCategory.fromJson(Map<String, dynamic> json) {
    return DomainCategory(
      id: json['id']?.toString() ?? json['domainKey']?.toString() ?? '',
      title: json['title'] ?? json['domainTitle'] ?? '',
      matchPercentage: (json['matchPercentage'] as num?)?.toDouble() ?? 95.0,
      isCustom: json['isCustom'] ?? false,
    );
  }
}

class ResumeAnalysisResult {
  final String candidateSummary;
  final List<DetectedSkill> detectedSkills;
  final List<DomainCategory> domainCategories;
  final List<DiagnosticQuestion> diagnosticQuestions;

  const ResumeAnalysisResult({
    this.candidateSummary = '',
    required this.detectedSkills,
    required this.domainCategories,
    this.diagnosticQuestions = const [],
  });

  factory ResumeAnalysisResult.fromJson(Map<String, dynamic> json) {
    final rawSkills = (json['detectedSkills'] as List? ?? []);
    final rawDomains = (json['suggestedDomains'] as List? ??
        json['domainCategories'] as List? ??
        []);
    final rawQuestions = (json['diagnosticQuestions'] as List? ?? []);

    return ResumeAnalysisResult(
      candidateSummary: json['candidateSummary']?.toString() ?? '',
      detectedSkills: rawSkills
          .map((e) => DetectedSkill.fromJson(e as Map<String, dynamic>))
          .toList(),
      domainCategories: rawDomains
          .map((e) => DomainCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      diagnosticQuestions: rawQuestions
          .map((e) => DiagnosticQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
