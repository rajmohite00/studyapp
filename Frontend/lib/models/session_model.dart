class SessionModel {
  final String id;
  final String userId;
  final String subject;
  final String? topic;
  final String mode;
  final String status;
  final DateTime startTime;
  final DateTime? endTime;
  final int plannedDurationMinutes;
  final int actualDurationMinutes;
  final int durationSeconds;
  final double focusScore;
  final int interruptions;
  final String? notes;
  final int? rating;
  final String? goal;
  final bool goalCompleted;

  const SessionModel({
    required this.id,
    required this.userId,
    required this.subject,
    this.topic,
    required this.mode,
    required this.status,
    required this.startTime,
    this.endTime,
    this.plannedDurationMinutes = 25,
    this.actualDurationMinutes = 0,
    this.durationSeconds = 0,
    this.focusScore = 0,
    this.interruptions = 0,
    this.notes,
    this.rating,
    this.goal,
    this.goalCompleted = false,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) => SessionModel(
        id: json['_id'] ?? json['id'] ?? '',
        userId: json['userId'] ?? '',
        subject: json['subject'] ?? '',
        topic: json['topic'],
        mode: json['mode'] ?? 'custom',
        status: json['status'] ?? 'active',
        startTime: DateTime.parse(json['startTime']),
        endTime: json['endTime'] != null ? DateTime.tryParse(json['endTime']) : null,
        plannedDurationMinutes: json['plannedDurationMinutes'] ?? 25,
        actualDurationMinutes: json['actualDurationMinutes'] ?? 0,
        durationSeconds: json['durationSeconds'] ?? 0,
        focusScore: (json['focusScore'] ?? 0).toDouble(),
        interruptions: json['interruptions'] ?? 0,
        notes: json['notes'],
        rating: json['rating'],
        goal: json['goal'],
        goalCompleted: json['goalCompleted'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'subject': subject,
        'topic': topic,
        'mode': mode,
        'status': status,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'plannedDurationMinutes': plannedDurationMinutes,
        'actualDurationMinutes': actualDurationMinutes,
        'durationSeconds': durationSeconds,
        'focusScore': focusScore,
        'interruptions': interruptions,
        'notes': notes,
        'rating': rating,
        'goal': goal,
        'goalCompleted': goalCompleted,
      };

  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
  bool get isCompleted => status == 'completed';

  String get formattedDuration {
    final h = actualDurationMinutes ~/ 60;
    final m = actualDurationMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  String get focusLabel {
    if (focusScore >= 80) return 'Excellent';
    if (focusScore >= 60) return 'Good';
    if (focusScore >= 40) return 'Fair';
    return 'Poor';
  }
}
