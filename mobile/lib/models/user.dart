class AppUser {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? json['full_name'] ?? '',
      email: json['email'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// A single skill baseline rating (1-5) captured on Screen 1.
class UserSkill {
  final String skillName; // e.g. "SQL", "Node.js", "Architecture"
  final int level; // 1-5

  const UserSkill({required this.skillName, required this.level});

  factory UserSkill.fromJson(Map<String, dynamic> json) {
    return UserSkill(
      skillName: json['skillName'] ?? json['name'] ?? '',
      level: (json['level'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {'skillName': skillName, 'level': level};

  UserSkill copyWith({int? level}) => UserSkill(skillName: skillName, level: level ?? this.level);
}
