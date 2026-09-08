/// All Stoptify backend routes, matching the master spec's endpoint table.
/// Base URL is configured on the Dio instance in [ApiClient].
class ApiEndpoints {
  ApiEndpoints._();

  // --- Auth ---------------------------------------------------------------
  static const register = '/api/auth/register';
  static const login = '/api/auth/login';
  static const me = '/api/auth/me';

  // --- Skills ---------------------------------------------------------------
  static const skills = '/api/skills';

  // --- Consultation ---------------------------------------------------------
  static const analyzeResume = '/api/consultation/analyze-resume';
  static const consultationStart = '/api/consultation/start';
  static const consultationMessage = '/api/consultation/message';
  static const consultationFinalize = '/api/consultation/finalize';

  // --- Roadmaps ---------------------------------------------------------
  static const roadmaps = '/api/roadmaps';
  static String roadmapDetail(String id) => '/api/roadmaps/$id';
  static String roadmapEnroll(String id) => '/api/roadmaps/$id/enroll';
  static String roadmapProgress(String id) => '/api/roadmaps/$id/progress';

  // --- RAG / Textbook -------------------------------------------------------
  static String ragGenerate(String topicId) => '/api/rag/generate/$topicId';

  // --- Assessments ---------------------------------------------------------
  static String assessmentsForTopic(String topicId) => '/api/assessments/topic/$topicId';
  static const oralStart = '/api/assessments/oral/start';
  static const oralEvaluate = '/api/assessments/oral/evaluate';
  static String submitMcq(String assessmentId) => '/api/assessments/$assessmentId/submit-mcq';
  static String submitOrdering(String assessmentId) =>
      '/api/assessments/$assessmentId/submit-ordering';
}
