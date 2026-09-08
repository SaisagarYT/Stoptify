enum AssessmentType { oral, mcq, sequenceOrdering }

/// One of the three timed Feynman oral defense probes.
class OralProbe {
  final int index; // 1, 2, 3
  final String label; // "ELI5", "Trade-offs", "Troubleshooting"
  final String prompt;
  final int timeLimitSeconds; // 30 or 45

  const OralProbe({
    required this.index,
    required this.label,
    required this.prompt,
    required this.timeLimitSeconds,
  });

  factory OralProbe.fromJson(Map<String, dynamic> json) {
    return OralProbe(
      index: (json['index'] as num?)?.toInt() ?? 1,
      label: json['label'] ?? '',
      prompt: json['prompt'] ?? '',
      timeLimitSeconds: (json['timeLimitSeconds'] as num?)?.toInt() ?? 30,
    );
  }
}

class OralSession {
  final String sessionId;
  final List<OralProbe> probes;

  const OralSession({required this.sessionId, required this.probes});

  factory OralSession.fromJson(Map<String, dynamic> json) {
    return OralSession(
      sessionId: json['sessionId']?.toString() ?? '',
      probes: (json['probes'] as List? ?? []).map((e) => OralProbe.fromJson(e)).toList(),
    );
  }
}

/// Score breakdown shown on the circular gauge after oral evaluation.
class OralScoreBreakdown {
  final double eli5Score; // 0-100
  final double tradeoffScore;
  final double applicationScore;

  const OralScoreBreakdown({
    required this.eli5Score,
    required this.tradeoffScore,
    required this.applicationScore,
  });

  double get overall => (eli5Score + tradeoffScore + applicationScore) / 3;

  factory OralScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return OralScoreBreakdown(
      eli5Score: (json['eli5Score'] as num?)?.toDouble() ?? 0,
      tradeoffScore: (json['tradeoffScore'] as num?)?.toDouble() ?? 0,
      applicationScore: (json['applicationScore'] as num?)?.toDouble() ?? 0,
    );
  }
}

class McqOption {
  final String id;
  final String text;
  final bool isCorrect;
  final String? rationale; // shown after answering, explains why it's right/wrong

  const McqOption({required this.id, required this.text, this.isCorrect = false, this.rationale});

  factory McqOption.fromJson(Map<String, dynamic> json) {
    return McqOption(
      id: json['id']?.toString() ?? '',
      text: json['text'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
      rationale: json['rationale'],
    );
  }
}

class McqQuestion {
  final String id;
  final String scenario;
  final List<McqOption> options;

  const McqQuestion({required this.id, required this.scenario, required this.options});

  factory McqQuestion.fromJson(Map<String, dynamic> json) {
    return McqQuestion(
      id: json['id']?.toString() ?? '',
      scenario: json['scenario'] ?? json['question'] ?? '',
      options: (json['options'] as List? ?? []).map((e) => McqOption.fromJson(e)).toList(),
    );
  }
}

/// A drag-and-drop sequence ordering challenge, e.g. SQL execution order.
class SequenceOrderingChallenge {
  final String id;
  final String instructions;
  final List<String> correctOrder;
  final List<String> shuffledItems;

  const SequenceOrderingChallenge({
    required this.id,
    required this.instructions,
    required this.correctOrder,
    required this.shuffledItems,
  });

  factory SequenceOrderingChallenge.fromJson(Map<String, dynamic> json) {
    return SequenceOrderingChallenge(
      id: json['id']?.toString() ?? '',
      instructions: json['instructions'] ?? '',
      correctOrder: (json['correctOrder'] as List? ?? []).map((e) => e.toString()).toList(),
      shuffledItems: (json['shuffledItems'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }
}

/// Result payload returned by any of the three submit endpoints.
class AssessmentResult {
  final double scorePercent;
  final bool passed; // scorePercent >= 80
  final String? remediationSnippet; // shown when passed == false

  const AssessmentResult({
    required this.scorePercent,
    required this.passed,
    this.remediationSnippet,
  });

  factory AssessmentResult.fromJson(Map<String, dynamic> json) {
    final score = (json['scorePercent'] as num?)?.toDouble() ?? 0;
    return AssessmentResult(
      scorePercent: score,
      passed: json['passed'] ?? score >= 80,
      remediationSnippet: json['remediationSnippet'],
    );
  }
}
