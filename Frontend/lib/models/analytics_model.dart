class AnalyticsModel {
  final TodaySummary today;
  final WeekSummary week;
  final StreakSummary streak;
  final int dailyGoalMinutes;

  const AnalyticsModel({
    required this.today,
    required this.week,
    required this.streak,
    this.dailyGoalMinutes = 120,
  });

  factory AnalyticsModel.fromJson(Map<String, dynamic> json) => AnalyticsModel(
        today: TodaySummary.fromJson(json['today'] ?? {}),
        week: WeekSummary.fromJson(json['week'] ?? {}),
        streak: StreakSummary.fromJson(json['streak'] ?? {}),
        dailyGoalMinutes: json['dailyGoalMinutes'] ?? 120,
      );
}

class TodaySummary {
  final int totalMinutes;
  final int sessionCount;
  final bool goalAchieved;
  final Map<String, int> subjectBreakdown;

  const TodaySummary({
    this.totalMinutes = 0,
    this.sessionCount = 0,
    this.goalAchieved = false,
    this.subjectBreakdown = const {},
  });

  factory TodaySummary.fromJson(Map<String, dynamic> json) => TodaySummary(
        totalMinutes: json['totalMinutes'] ?? 0,
        sessionCount: json['sessionCount'] ?? 0,
        goalAchieved: json['goalAchieved'] ?? false,
        subjectBreakdown: Map<String, int>.from(
          (json['subjectBreakdown'] ?? {}).map((k, v) => MapEntry(k, (v as num).toInt())),
        ),
      );
}

class WeekSummary {
  final int totalMinutes;
  final int avgFocusScore;
  final int sessionCount;

  const WeekSummary({this.totalMinutes = 0, this.avgFocusScore = 0, this.sessionCount = 0});

  factory WeekSummary.fromJson(Map<String, dynamic> json) => WeekSummary(
        totalMinutes: json['totalMinutes'] ?? 0,
        avgFocusScore: json['avgFocusScore'] ?? 0,
        sessionCount: json['sessionCount'] ?? 0,
      );
}

class StreakSummary {
  final int current;
  final int longest;
  final int freezesAvailable;
  final int? nextMilestone;

  const StreakSummary({
    this.current = 0,
    this.longest = 0,
    this.freezesAvailable = 1,
    this.nextMilestone,
  });

  factory StreakSummary.fromJson(Map<String, dynamic> json) => StreakSummary(
        current: json['current'] ?? 0,
        longest: json['longest'] ?? 0,
        freezesAvailable: json['freezesAvailable'] ?? 1,
        nextMilestone: json['nextMilestone'],
      );
}

class HeatmapEntry {
  final DateTime date;
  final int minutes;

  const HeatmapEntry({required this.date, required this.minutes});

  factory HeatmapEntry.fromJson(Map<String, dynamic> json) => HeatmapEntry(
        date: DateTime.parse(json['date']),
        minutes: json['minutes'] ?? 0,
      );

  int get intensity {
    if (minutes == 0) return 0;
    if (minutes < 30) return 1;
    if (minutes < 60) return 2;
    if (minutes < 120) return 3;
    return 4;
  }
}
