class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isVerified;
  final UserProfile profile;
  final StreakInfo streak;
  final SubscriptionInfo subscription;
  final GamificationInfo gamification;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isVerified,
    required this.profile,
    required this.streak,
    required this.subscription,
    required this.gamification,
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
        gamification: GamificationInfo.fromJson(json['gamification'] ?? {}),
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
        'gamification': gamification.toJson(),
      };
}

// ── Gamification Info ─────────────────────────────────────────────────────────
class GamificationInfo {
  final int xp;
  final int level;
  final String rank;
  final int coins;
  final int totalStudyMinutes;
  final List<String> achievements;
  final List<String> rewardsUnlocked;

  const GamificationInfo({
    this.xp = 0,
    this.level = 1,
    this.rank = 'Novice',
    this.coins = 0,
    this.totalStudyMinutes = 0,
    this.achievements = const [],
    this.rewardsUnlocked = const [],
  });

  factory GamificationInfo.fromJson(Map<String, dynamic> json) => GamificationInfo(
        xp: json['xp'] ?? 0,
        level: json['level'] ?? 1,
        rank: json['rank'] ?? 'Novice',
        coins: json['coins'] ?? 0,
        totalStudyMinutes: json['totalStudyMinutes'] ?? 0,
        achievements: List<String>.from(json['achievements'] ?? []),
        rewardsUnlocked: List<String>.from(json['rewardsUnlocked'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'xp': xp,
        'level': level,
        'rank': rank,
        'coins': coins,
        'totalStudyMinutes': totalStudyMinutes,
        'achievements': achievements,
        'rewardsUnlocked': rewardsUnlocked,
      };
}

// ── User Profile ──────────────────────────────────────────────────────────────
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

// ── Streak Info ───────────────────────────────────────────────────────────────
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

// ── Subscription Info ─────────────────────────────────────────────────────────
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

// ── Gamification State (full detail from /gamification/state) ─────────────────
class GamificationState {
  final int xp;
  final int level;
  final String rank;
  final int coins;
  final int totalStudyMinutes;
  final int xpProgress;
  final int xpNeeded;
  final int xpForNext;
  final List<AchievementItem> achievements;
  final List<RewardItem> rewardStore;
  final List<String> rewardsUnlocked;
  final List<DailyMission> dailyMissions;
  final String missionDate;
  final String? activeBadgeId;
  final String? activeBadgeEmoji;

  const GamificationState({
    this.xp = 0,
    this.level = 1,
    this.rank = 'Novice',
    this.coins = 0,
    this.totalStudyMinutes = 0,
    this.xpProgress = 0,
    this.xpNeeded = 100,
    this.xpForNext = 100,
    this.achievements = const [],
    this.rewardStore = const [],
    this.rewardsUnlocked = const [],
    this.dailyMissions = const [],
    this.missionDate = '',
    this.activeBadgeId,
    this.activeBadgeEmoji,
  });

  factory GamificationState.fromJson(Map<String, dynamic> json) => GamificationState(
        xp: json['xp'] ?? 0,
        level: json['level'] ?? 1,
        rank: json['rank'] ?? 'Novice',
        coins: json['coins'] ?? 0,
        totalStudyMinutes: json['totalStudyMinutes'] ?? 0,
        xpProgress: json['xpProgress'] ?? 0,
        xpNeeded: json['xpNeeded'] ?? 100,
        xpForNext: json['xpForNext'] ?? 100,
        achievements: (json['achievements'] as List? ?? [])
            .map((a) => AchievementItem.fromJson(a))
            .toList(),
        rewardStore: (json['rewardStore'] as List? ?? [])
            .map((r) => RewardItem.fromJson(r))
            .toList(),
        rewardsUnlocked: List<String>.from(json['rewardsUnlocked'] ?? []),
        dailyMissions: (json['dailyMissions'] as List<dynamic>?)
                ?.map((e) => DailyMission.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        missionDate: json['missionDate'] ?? '',
        activeBadgeId: json['activeBadgeId'],
        activeBadgeEmoji: json['activeBadgeEmoji'],
      );
}

class AchievementItem {
  final String id;
  final String label;
  final String description;
  final String emoji;
  final int xpReward;
  final bool earned;

  const AchievementItem({
    required this.id,
    required this.label,
    required this.description,
    required this.emoji,
    required this.xpReward,
    this.earned = false,
  });

  factory AchievementItem.fromJson(Map<String, dynamic> json) => AchievementItem(
        id: json['id'] ?? '',
        label: json['label'] ?? '',
        description: json['description'] ?? '',
        emoji: json['emoji'] ?? '🏅',
        xpReward: json['xpReward'] ?? 0,
        earned: json['earned'] ?? false,
      );
}

class RewardItem {
  final String id;
  final String label;
  final String category; // 'badge' | 'theme' | 'pack'
  final int cost;
  final String emoji;
  final String description;
  final bool unlocked;
  final bool canAfford;

  const RewardItem({
    required this.id,
    required this.label,
    required this.category,
    required this.cost,
    required this.emoji,
    required this.description,
    this.unlocked = false,
    this.canAfford = false,
  });

  factory RewardItem.fromJson(Map<String, dynamic> json) => RewardItem(
        id: json['id'] ?? '',
        label: json['label'] ?? '',
        category: json['category'] ?? 'badge',
        cost: json['cost'] ?? 0,
        emoji: json['emoji'] ?? '🎁',
        description: json['description'] ?? '',
        unlocked: json['unlocked'] ?? false,
        canAfford: json['canAfford'] ?? false,
      );
}

class DailyMission {
  final String id;
  final String label;
  final int target;
  final int progress;
  final bool completed;
  final int xpReward;

  const DailyMission({
    required this.id,
    required this.label,
    required this.target,
    this.progress = 0,
    this.completed = false,
    required this.xpReward,
  });

  double get progressPct => target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;

  factory DailyMission.fromJson(Map<String, dynamic> json) => DailyMission(
        id: json['id'] ?? '',
        label: json['label'] ?? '',
        target: json['target'] ?? 0,
        progress: json['progress'] ?? 0,
        completed: json['completed'] ?? false,
        xpReward: json['xpReward'] ?? 0,
      );
}
