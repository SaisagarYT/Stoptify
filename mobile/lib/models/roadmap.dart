enum TopicStatus { locked, inProgress, completed }

TopicStatus _statusFromString(String? s) {
  switch (s) {
    case 'completed':
      return TopicStatus.completed;
    case 'in_progress':
      return TopicStatus.inProgress;
    default:
      return TopicStatus.locked;
  }
}

/// A real-world production example card (Uber, Netflix, Stripe, etc.).
class ProductionExample {
  final String companyBadge;
  final String challenge;
  final String takeaway;

  const ProductionExample({
    required this.companyBadge,
    required this.challenge,
    required this.takeaway,
  });

  factory ProductionExample.fromJson(Map<String, dynamic> json) {
    return ProductionExample(
      companyBadge: json['companyBadge'] ?? '',
      challenge: json['challenge'] ?? '',
      takeaway: json['takeaway'] ?? '',
    );
  }
}

/// The explicit "When to Stop" anti-scope boundary for a topic —
/// Stoptify's core pedagogical differentiator.
class AntiScopeBoundary {
  final String stopCondition; // "Stop once you understand B-tree write overhead."
  final List<String> doNotStudyYet; // ["GiST/SP-GiST indexes", "custom C extensions"]

  const AntiScopeBoundary({required this.stopCondition, required this.doNotStudyYet});

  factory AntiScopeBoundary.fromJson(Map<String, dynamic> json) {
    return AntiScopeBoundary(
      stopCondition: json['stopCondition'] ?? '',
      doNotStudyYet: (json['doNotStudyYet'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }
}

/// The explicit 3-tier Definition of Done for a topic.
class DefinitionOfDone {
  final String conceptualEli5;
  final String practicalBuildTask;
  final String masteryCriteria;

  const DefinitionOfDone({
    required this.conceptualEli5,
    required this.practicalBuildTask,
    required this.masteryCriteria,
  });

  factory DefinitionOfDone.fromJson(Map<String, dynamic> json) {
    return DefinitionOfDone(
      conceptualEli5: json['conceptualEli5'] ?? '',
      practicalBuildTask: json['practicalBuildTask'] ?? '',
      masteryCriteria: json['masteryCriteria'] ?? '',
    );
  }
}

class RoadmapTopic {
  final String id;
  final String roadmapId;
  final int orderIndex;
  final String title;
  final int estimatedMinutes;
  final List<String> coreSubtopics;
  final ProductionExample? productionExample;
  final AntiScopeBoundary? antiScope;
  final DefinitionOfDone? definitionOfDone;
  final TopicStatus status;

  const RoadmapTopic({
    required this.id,
    required this.roadmapId,
    required this.orderIndex,
    required this.title,
    required this.estimatedMinutes,
    this.coreSubtopics = const [],
    this.productionExample,
    this.antiScope,
    this.definitionOfDone,
    this.status = TopicStatus.locked,
  });

  factory RoadmapTopic.fromJson(Map<String, dynamic> json) {
    return RoadmapTopic(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      roadmapId: json['roadmapId']?.toString() ?? '',
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      title: json['title'] ?? '',
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 0,
      coreSubtopics: (json['coreSubtopics'] as List? ?? []).map((e) => e.toString()).toList(),
      productionExample: json['productionExample'] != null
          ? ProductionExample.fromJson(json['productionExample'])
          : null,
      antiScope: json['antiScope'] != null ? AntiScopeBoundary.fromJson(json['antiScope']) : null,
      definitionOfDone:
          json['definitionOfDone'] != null ? DefinitionOfDone.fromJson(json['definitionOfDone']) : null,
      status: _statusFromString(json['status']),
    );
  }

  RoadmapTopic copyWith({TopicStatus? status}) {
    return RoadmapTopic(
      id: id,
      roadmapId: roadmapId,
      orderIndex: orderIndex,
      title: title,
      estimatedMinutes: estimatedMinutes,
      coreSubtopics: coreSubtopics,
      productionExample: productionExample,
      antiScope: antiScope,
      definitionOfDone: definitionOfDone,
      status: status ?? this.status,
    );
  }
}

/// Real-time learning velocity, driving the Screen 4 top banner widget.
class VelocityMetrics {
  final double paceMultiplier; // e.g. 2.4
  final DateTime projectedCompletion;
  final int daysAheadOfSchedule;

  const VelocityMetrics({
    required this.paceMultiplier,
    required this.projectedCompletion,
    required this.daysAheadOfSchedule,
  });

  factory VelocityMetrics.fromJson(Map<String, dynamic> json) {
    return VelocityMetrics(
      paceMultiplier: (json['paceMultiplier'] as num?)?.toDouble() ?? 1.0,
      projectedCompletion: json['projectedCompletion'] != null
          ? DateTime.tryParse(json['projectedCompletion']) ?? DateTime.now()
          : DateTime.now(),
      daysAheadOfSchedule: (json['daysAheadOfSchedule'] as num?)?.toInt() ?? 0,
    );
  }
}

class Roadmap {
  final String id;
  final String title;
  final String domainCategoryId;
  final List<RoadmapTopic> topics;
  final VelocityMetrics? velocity;

  const Roadmap({
    required this.id,
    required this.title,
    required this.domainCategoryId,
    this.topics = const [],
    this.velocity,
  });

  factory Roadmap.fromJson(Map<String, dynamic> json) {
    return Roadmap(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title'] ?? '',
      domainCategoryId: json['domainCategoryId']?.toString() ?? '',
      topics: (json['topics'] as List? ?? [])
          .map((e) => RoadmapTopic.fromJson(e as Map<String, dynamic>))
          .toList(),
      velocity: json['velocityMetrics'] != null ? VelocityMetrics.fromJson(json['velocityMetrics']) : null,
    );
  }
}
