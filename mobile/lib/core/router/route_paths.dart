class RoutePaths {
  RoutePaths._();

  // Screen 1
  static const login = '/login';
  static const register = '/register';
  static const skillBaseline = '/skill-baseline';

  // Screen 2
  static const resumeIntake = '/resume-intake';

  // Screen 3
  static const consultation = '/consultation/:domainId';
  static String consultationFor(String domainId) => '/consultation/$domainId';

  // Screen 4
  static const roadmapDashboard = '/roadmap/:roadmapId';
  static String roadmapDashboardFor(String roadmapId) => '/roadmap/$roadmapId';

  // Screen 5
  static const textbookReader = '/roadmap/:roadmapId/topic/:topicId';
  static String textbookReaderFor(String roadmapId, String topicId) =>
      '/roadmap/$roadmapId/topic/$topicId';

  // Screen 6
  static const assessmentHud = '/roadmap/:roadmapId/topic/:topicId/assessment';
  static String assessmentHudFor(String roadmapId, String topicId) =>
      '/roadmap/$roadmapId/topic/$topicId/assessment';
}
