class VerifiedStrength {
  final String skill;
  final String reason;

  const VerifiedStrength({
    required this.skill,
    required this.reason,
  });

  factory VerifiedStrength.fromJson(Map<String, dynamic> json) {
    return VerifiedStrength(
      skill: json['skill']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
    );
  }
}

class FragileGap {
  final String skill;
  final String risk;

  const FragileGap({
    required this.skill,
    required this.risk,
  });

  factory FragileGap.fromJson(Map<String, dynamic> json) {
    return FragileGap(
      skill: json['skill']?.toString() ?? '',
      risk: json['risk']?.toString() ?? '',
    );
  }
}

class AntiScopeBypass {
  final int hoursSaved;
  final String bypassPercentage;
  final List<String> topicsSkipped;

  const AntiScopeBypass({
    required this.hoursSaved,
    required this.bypassPercentage,
    required this.topicsSkipped,
  });

  factory AntiScopeBypass.fromJson(Map<String, dynamic> json) {
    return AntiScopeBypass(
      hoursSaved: (json['hoursSaved'] is num)
          ? (json['hoursSaved'] as num).toInt()
          : 12,
      bypassPercentage: json['bypassPercentage']?.toString() ?? '35%',
      topicsSkipped:
          (json['topicsSkipped'] as List?)?.map((e) => e.toString()).toList() ??
              [],
    );
  }
}

class RecommendedTrack {
  final String trackId;
  final String title;
  final int matchScore;
  final String tagline;
  final int estimatedWeeks;

  const RecommendedTrack({
    required this.trackId,
    required this.title,
    required this.matchScore,
    required this.tagline,
    required this.estimatedWeeks,
  });

  factory RecommendedTrack.fromJson(Map<String, dynamic> json) {
    return RecommendedTrack(
      trackId: json['trackId']?.toString() ?? 'track-1',
      title: json['title']?.toString() ?? 'Production Engineering',
      matchScore: (json['matchScore'] is num)
          ? (json['matchScore'] as num).toInt()
          : 80,
      tagline: json['tagline']?.toString() ??
          'Master core production resilience and scale.',
      estimatedWeeks: (json['estimatedWeeks'] is num)
          ? (json['estimatedWeeks'] as num).toInt()
          : 4,
    );
  }
}

class DiagnosticAuditResult {
  final String verdictTitle;
  final int readinessScore;
  final String confidenceSummary;
  final List<VerifiedStrength> verifiedStrengths;
  final List<FragileGap> fragileGaps;
  final AntiScopeBypass antiScopeBypass;
  final List<RecommendedTrack> recommendedTracks;

  const DiagnosticAuditResult({
    required this.verdictTitle,
    required this.readinessScore,
    required this.confidenceSummary,
    required this.verifiedStrengths,
    required this.fragileGaps,
    required this.antiScopeBypass,
    required this.recommendedTracks,
  });

  factory DiagnosticAuditResult.fromJson(Map<String, dynamic> json) {
    return DiagnosticAuditResult(
      verdictTitle:
          json['verdictTitle']?.toString() ?? 'Diagnostic Assessment Complete',
      readinessScore: (json['readinessScore'] is num)
          ? (json['readinessScore'] as num).toInt()
          : 70,
      confidenceSummary: json['confidenceSummary']?.toString() ?? '',
      verifiedStrengths: (json['verifiedStrengths'] as List?)
              ?.map((e) => VerifiedStrength.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      fragileGaps: (json['fragileGaps'] as List?)
              ?.map((e) => FragileGap.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      antiScopeBypass: json['antiScopeBypass'] != null
          ? AntiScopeBypass.fromJson(
              json['antiScopeBypass'] as Map<String, dynamic>)
          : const AntiScopeBypass(
              hoursSaved: 10, bypassPercentage: '30%', topicsSkipped: []),
      recommendedTracks: (json['recommendedTracks'] as List?)
              ?.map((e) => RecommendedTrack.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
