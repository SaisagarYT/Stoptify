import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_endpoints.dart';
import '../models/roadmap.dart';
import 'core_providers.dart';

/// List of all roadmaps available to the current user.
final roadmapListProvider = FutureProvider<List<Roadmap>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final envelope = await api.get(ApiEndpoints.roadmaps);
  return (envelope.data as List).map((e) => Roadmap.fromJson(e as Map<String, dynamic>)).toList();
});

/// A single roadmap's full detail (topics, DoD, anti-scope, examples).
final roadmapDetailProvider = FutureProvider.family<Roadmap, String>((ref, roadmapId) async {
  final api = ref.watch(apiClientProvider);
  final envelope = await api.get(ApiEndpoints.roadmapDetail(roadmapId));
  return Roadmap.fromJson(envelope.data as Map<String, dynamic>);
});

/// Progress + velocity metrics, polled/refreshed after each assessment.
final roadmapProgressProvider = FutureProvider.family<Roadmap, String>((ref, roadmapId) async {
  final api = ref.watch(apiClientProvider);
  final envelope = await api.get(ApiEndpoints.roadmapProgress(roadmapId));
  return Roadmap.fromJson(envelope.data as Map<String, dynamic>);
});

final roadmapActionsProvider = Provider((ref) => RoadmapActions(ref));

class RoadmapActions {
  RoadmapActions(this.ref);
  final Ref ref;

  Future<void> enroll(String roadmapId) async {
    final api = ref.read(apiClientProvider);
    await api.post(ApiEndpoints.roadmapEnroll(roadmapId));
    ref.invalidate(roadmapProgressProvider(roadmapId));
  }
}
