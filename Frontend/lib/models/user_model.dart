class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isVerified;
  final UserProfile profile;
  final SubscriptionInfo subscription;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isVerified,
    required this.profile,
    required this.subscription,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? json['_id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        role: json['role'] ?? 'student',
        isVerified: json['isVerified'] ?? false,
        profile: UserProfile.fromJson(json['profile'] ?? {}),
        subscription: SubscriptionInfo.fromJson(json['subscription'] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'isVerified': isVerified,
        'profile': profile.toJson(),
        'subscription': subscription.toJson(),
      };
}

class UserProfile {
  final String grade;
  final String targetExam;
  final List<String> subjects;
  final int dailyGoalMinutes;

  const UserProfile({
    this.grade = '',
    this.targetExam = '',
    this.subjects = const [],
    this.dailyGoalMinutes = 120,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        grade: json['grade'] ?? '',
        targetExam: json['targetExam'] ?? '',
        subjects: List<String>.from(json['subjects'] ?? []),
        dailyGoalMinutes: json['dailyGoalMinutes'] ?? 120,
      );

  Map<String, dynamic> toJson() => {
        'grade': grade,
        'targetExam': targetExam,
        'subjects': subjects,
        'dailyGoalMinutes': dailyGoalMinutes,
      };
}

class SubscriptionInfo {
  final String plan;
  final DateTime? expiresAt;

  const SubscriptionInfo({this.plan = 'free', this.expiresAt});

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) => SubscriptionInfo(
        plan: json['plan'] ?? 'free',
        expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt']) : null,
      );

  Map<String, dynamic> toJson() => {
        'plan': plan,
        'expiresAt': expiresAt?.toIso8601String(),
      };

  bool get isPremium => plan == 'premium';
}
