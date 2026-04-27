import 'package:flutter/material.dart';

enum TaskPriority { high, medium, low }

extension TaskPriorityX on TaskPriority {
  Color get color {
    switch (this) {
      case TaskPriority.high: return const Color(0xFFFF4757);
      case TaskPriority.medium: return const Color(0xFFFF9F43);
      case TaskPriority.low: return const Color(0xFF43D67B);
    }
  }

  String get label {
    switch (this) {
      case TaskPriority.high: return 'HIGH';
      case TaskPriority.medium: return 'MED';
      case TaskPriority.low: return 'LOW';
    }
  }
}

class PYQModel {
  final String question;
  final int? year;
  final int frequency;
  final bool isHighlighted;

  PYQModel({
    required this.question,
    this.year,
    required this.frequency,
    required this.isHighlighted,
  });

  factory PYQModel.fromJson(Map<String, dynamic> json) => PYQModel(
        question: json['question'] ?? '',
        year: json['year'],
        frequency: json['frequency'] ?? 1,
        isHighlighted: json['isHighlighted'] ?? false,
      );
}

class ImportantTopicModel {
  final String name;
  final TaskPriority priority;
  final int frequencyScore;
  final List<PYQModel> pyqs;

  ImportantTopicModel({
    required this.name,
    required this.priority,
    required this.frequencyScore,
    required this.pyqs,
  });

  factory ImportantTopicModel.fromJson(Map<String, dynamic> json) {
    final priorityStr = json['priority'] ?? 'medium';
    final priority = priorityStr == 'high'
        ? TaskPriority.high
        : priorityStr == 'low'
            ? TaskPriority.low
            : TaskPriority.medium;
    return ImportantTopicModel(
      name: json['name'] ?? '',
      priority: priority,
      frequencyScore: json['frequencyScore'] ?? 0,
      pyqs: (json['pyqs'] as List<dynamic>? ?? [])
          .map((p) => PYQModel.fromJson(p))
          .toList(),
    );
  }
}

class DailyTaskModel {
  final int day;
  final String date;
  final String subject;
  final String topic;
  final int durationMinutes;
  final bool isRevision;
  final bool isCompleted;
  final String? completedAt;

  DailyTaskModel({
    required this.day,
    required this.date,
    required this.subject,
    required this.topic,
    required this.durationMinutes,
    required this.isRevision,
    required this.isCompleted,
    this.completedAt,
  });

  DailyTaskModel copyWith({
    int? day,
    String? date,
    String? subject,
    String? topic,
    int? durationMinutes,
    bool? isRevision,
    bool? isCompleted,
    String? completedAt,
  }) =>
      DailyTaskModel(
        day: day ?? this.day,
        date: date ?? this.date,
        subject: subject ?? this.subject,
        topic: topic ?? this.topic,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        isRevision: isRevision ?? this.isRevision,
        isCompleted: isCompleted ?? this.isCompleted,
        completedAt: completedAt ?? this.completedAt,
      );

  factory DailyTaskModel.fromJson(Map<String, dynamic> json) => DailyTaskModel(
        day: json['day'] ?? 1,
        date: json['date'] ?? '',
        subject: json['subject'] ?? '',
        topic: json['topic'] ?? '',
        durationMinutes: json['durationMinutes'] ?? 30,
        isRevision: json['isRevision'] ?? false,
        isCompleted: json['isCompleted'] ?? false,
        completedAt: json['completedAt'],
      );
}

class ExamPlanModel {
  final String id;
  final List<String> subjects;
  final DateTime examDate;
  final int totalDays;
  final double dailyStudyHours;
  final List<DailyTaskModel> generatedPlan;
  final List<ImportantTopicModel> importantTopics;

  ExamPlanModel({
    required this.id,
    required this.subjects,
    required this.examDate,
    required this.totalDays,
    required this.dailyStudyHours,
    required this.generatedPlan,
    required this.importantTopics,
  });

  factory ExamPlanModel.fromJson(Map<String, dynamic> json) => ExamPlanModel(
        id: json['_id'] ?? '',
        subjects: List<String>.from(json['subjects'] ?? []),
        examDate: DateTime.parse(json['examDate']),
        totalDays: json['totalDays'] ?? 0,
        dailyStudyHours: (json['dailyStudyHours'] ?? 4).toDouble(),
        generatedPlan: (json['generatedPlan'] as List<dynamic>? ?? [])
            .map((t) => DailyTaskModel.fromJson(t))
            .toList(),
        importantTopics: (json['importantTopics'] as List<dynamic>? ?? [])
            .map((t) => ImportantTopicModel.fromJson(t))
            .toList(),
      );
}

class ExamPlanProgress {
  final int totalTasks;
  final int completedTasks;
  final int progressPercent;
  final int todayTasks;
  final int todayCompleted;
  final int daysLeft;
  final double dailyStudyHours;
  final List<String> subjects;
  final DateTime examDate;

  ExamPlanProgress({
    required this.totalTasks,
    required this.completedTasks,
    required this.progressPercent,
    required this.todayTasks,
    required this.todayCompleted,
    required this.daysLeft,
    required this.dailyStudyHours,
    required this.subjects,
    required this.examDate,
  });

  factory ExamPlanProgress.fromJson(Map<String, dynamic> json) => ExamPlanProgress(
        totalTasks: json['totalTasks'] ?? 0,
        completedTasks: json['completedTasks'] ?? 0,
        progressPercent: json['progressPercent'] ?? 0,
        todayTasks: json['todayTasks'] ?? 0,
        todayCompleted: json['todayCompleted'] ?? 0,
        daysLeft: json['daysLeft'] ?? 0,
        dailyStudyHours: (json['dailyStudyHours'] ?? 4).toDouble(),
        subjects: List<String>.from(json['subjects'] ?? []),
        examDate: DateTime.parse(json['examDate']),
      );
}
