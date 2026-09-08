import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_endpoints.dart';
import '../models/user.dart';
import 'core_providers.dart';

class SkillsNotifier extends StateNotifier<List<UserSkill>> {
  SkillsNotifier(this.ref)
      : super(const [
          UserSkill(skillName: 'SQL', level: 1),
          UserSkill(skillName: 'Node.js', level: 1),
          UserSkill(skillName: 'Architecture', level: 1),
        ]);

  final Ref ref;

  void setLevel(String skillName, int level) {
    state = [
      for (final s in state)
        if (s.skillName == skillName) s.copyWith(level: level) else s,
    ];
  }

  Future<bool> submit() async {
    final api = ref.read(apiClientProvider);
    try {
      await api.post(ApiEndpoints.skills, body: {
        'skills': state.map((s) => s.toJson()).toList(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}

final skillsProvider = StateNotifierProvider<SkillsNotifier, List<UserSkill>>((ref) {
  return SkillsNotifier(ref);
});
