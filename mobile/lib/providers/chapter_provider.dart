import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_endpoints.dart';
import '../models/chapter.dart';
import 'core_providers.dart';

/// Dynamic AI-generated (or cached) chapter for a given topic.
final chapterProvider = FutureProvider.family<ChapterContent, String>((ref, topicId) async {
  final api = ref.watch(apiClientProvider);
  final envelope = await api.post(ApiEndpoints.ragGenerate(topicId));
  return ChapterContent.fromJson(envelope.data as Map<String, dynamic>);
});
