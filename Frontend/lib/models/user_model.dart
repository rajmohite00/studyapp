class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isVerified;
  final UserProfile profile;
  final StreakInfo streak;
  final SubscriptionInfo subscription;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isVerified,
    required this.profile,
    required this.streak,
    required this.subscription,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? json['_id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        role: json['role'] ?? 'student',
        isVerified: json['isVerified'] ?? false,
        profile: UserProfile.fromJson(json['profile'] ?? {}),
        streak: StreakInfo.fromJson(json['streak'] ?? {}),
        subscription: SubscriptionInfo.fromJson(json['subscription'] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'isVerified': isVerified,
        'profile': profile.toJson(),
        'streak': streak.toJson(),
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

class StreakInfo {
  final int current;
  final int longest;
  final DateTime? lastStudiedDate;
  final int freezesAvailable;

  const StreakInfo({
    this.current = 0,
    this.longest = 0,
    this.lastStudiedDate,
    this.freezesAvailable = 1,
  });

  factory StreakInfo.fromJson(Map<String, dynamic> json) => StreakInfo(
        current: json['current'] ?? 0,
        longest: json['longest'] ?? 0,
        lastStudiedDate: json['lastStudiedDate'] != null
            ? DateTime.tryParse(json['lastStudiedDate'])
            : null,
        freezesAvailable: json['freezesAvailable'] ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'current': current,
        'longest': longest,
        'lastStudiedDate': lastStudiedDate?.toIso8601String(),
        'freezesAvailable': freezesAvailable,
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

  Map<String, dynamic> toJson() => {'plan': plan, 'expiresAt': expiresAt?.toIso8601String()};

  bool get isPremium => plan == 'premium';
}
