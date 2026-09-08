import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../screens/assessment/assessment_hud_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/skill_baseline_screen.dart';
import '../../screens/consultation/consultation_screen.dart';
import '../../screens/resume_intake/resume_intake_screen.dart';
import '../../screens/roadmap_dashboard/roadmap_dashboard_screen.dart';
import '../../screens/textbook_reader/textbook_reader_screen.dart';
import 'route_paths.dart';

/// Bridges Riverpod's [authProvider] changes into a [Listenable] so
/// GoRouter re-evaluates its `redirect` callback whenever auth status
/// flips (e.g. after login, logout, or session bootstrap).
class AuthRouterRefresh extends ChangeNotifier {
  AuthRouterRefresh(Ref ref) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.status != next.status) notifyListeners();
    });
  }
}

final _authRouterRefreshProvider = Provider<AuthRouterRefresh>((ref) => AuthRouterRefresh(ref));

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_authRouterRefreshProvider);

  return GoRouter(
    initialLocation: RoutePaths.login,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loggingIn =
          state.matchedLocation == RoutePaths.login || state.matchedLocation == RoutePaths.register;

      if (auth.status == AuthStatus.unknown) return null; // still bootstrapping session
      if (auth.status == AuthStatus.unauthenticated && !loggingIn) return RoutePaths.login;
      if (auth.status == AuthStatus.authenticated && loggingIn) return RoutePaths.skillBaseline;
      return null;
    },
    routes: [
      GoRoute(path: RoutePaths.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: RoutePaths.register, builder: (context, state) => const RegisterScreen()),
      GoRoute(
        path: RoutePaths.skillBaseline,
        builder: (context, state) => const SkillBaselineScreen(),
      ),
      GoRoute(
        path: RoutePaths.resumeIntake,
        builder: (context, state) => const ResumeIntakeScreen(),
      ),
      GoRoute(
        path: RoutePaths.consultation,
        builder: (context, state) => ConsultationScreen(domainId: state.pathParameters['domainId']!),
      ),
      GoRoute(
        path: RoutePaths.roadmapDashboard,
        builder: (context, state) =>
            RoadmapDashboardScreen(roadmapId: state.pathParameters['roadmapId']!),
      ),
      GoRoute(
        path: RoutePaths.textbookReader,
        builder: (context, state) => TextbookReaderScreen(
          roadmapId: state.pathParameters['roadmapId']!,
          topicId: state.pathParameters['topicId']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.assessmentHud,
        builder: (context, state) => AssessmentHudScreen(
          roadmapId: state.pathParameters['roadmapId']!,
          topicId: state.pathParameters['topicId']!,
        ),
      ),
    ],
  );
});
