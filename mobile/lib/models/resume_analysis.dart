/// A single detected skill from resume analysis, shown with a star rating
/// in the staggered reveal animation on Screen 2.
class DetectedSkill {
  final String name;
  final double rating; // 0-5, supports half-stars

  const DetectedSkill({required this.name, required this.rating});

  factory DetectedSkill.fromJson(Map<String, dynamic> json) {
    return DetectedSkill(
      name: json['name'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// A selectable domain category card, e.g. "SQL & Database Engineering".
class DomainCategory {
  final String id;
  final String title;
  final double matchPercentage; // e.g. 94.0
  final bool isCustom;

  const DomainCategory({
    required this.id,
    required this.title,
    required this.matchPercentage,
    this.isCustom = false,
  });

  factory DomainCategory.fromJson(Map<String, dynamic> json) {
    return DomainCategory(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      matchPercentage: (json['matchPercentage'] as num?)?.toDouble() ?? 0,
      isCustom: json['isCustom'] ?? false,
    );
  }
}

class ResumeAnalysisResult {
  final List<DetectedSkill> detectedSkills;
  final List<DomainCategory> domainCategories;

  const ResumeAnalysisResult({
    required this.detectedSkills,
    required this.domainCategories,
  });

  factory ResumeAnalysisResult.fromJson(Map<String, dynamic> json) {
    return ResumeAnalysisResult(
      detectedSkills: (json['detectedSkills'] as List? ?? [])
          .map((e) => DetectedSkill.fromJson(e as Map<String, dynamic>))
          .toList(),
      domainCategories: (json['domainCategories'] as List? ?? [])
          .map((e) => DomainCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
