import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analytics_model.dart';
import '../services/analytics_service.dart';

final analyticsServiceProvider = Provider((_) => AnalyticsService());

final dashboardProvider = FutureProvider.autoDispose<AnalyticsModel>((ref) async {
  return ref.read(analyticsServiceProvider).getDashboard();
});

final subjectBreakdownProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  return ref.read(analyticsServiceProvider).getSubjectBreakdown();
});

final streakProvider = FutureProvider.autoDispose<StreakSummary>((ref) async {
  return ref.read(analyticsServiceProvider).getStreak();
});

final heatmapProvider = FutureProvider.autoDispose<List<HeatmapEntry>>((ref) async {
  return ref.read(analyticsServiceProvider).getHeatmap();
});

final weeklyReportProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(analyticsServiceProvider).getWeeklyReport();
});

final suggestionsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  return ref.read(analyticsServiceProvider).getSuggestions();
});
