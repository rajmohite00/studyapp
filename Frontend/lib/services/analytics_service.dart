import 'dio_client.dart';
import '../models/analytics_model.dart';

class AnalyticsService {
  final _dio = DioClient.instance;

  Future<AnalyticsModel> getDashboard() async {
    final res = await _dio.get('/analytics/summary');
    return AnalyticsModel.fromJson(res.data['data']);
  }

  Future<List<Map<String, dynamic>>> getDailyAnalytics({String? from, String? to}) async {
    final res = await _dio.get('/analytics/daily', queryParameters: {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    });
    return List<Map<String, dynamic>>.from(res.data['data']);
  }

  Future<Map<String, int>> getSubjectBreakdown({int days = 30}) async {
    final res = await _dio.get('/analytics/subjects', queryParameters: {'days': days});
    return Map<String, int>.from(
      (res.data['data'] as Map).map((k, v) => MapEntry(k, (v as num).toInt())),
    );
  }

  Future<StreakSummary> getStreak() async {
    final res = await _dio.get('/analytics/streak');
    return StreakSummary.fromJson(res.data['data']);
  }

  Future<List<HeatmapEntry>> getHeatmap() async {
    final res = await _dio.get('/analytics/heatmap');
    return (res.data['data'] as List).map((e) => HeatmapEntry.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getDailyReport({String? date}) async {
    final res = await _dio.get('/analytics/reports/daily',
        queryParameters: {if (date != null) 'date': date});
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getWeeklyReport({String? weekStart}) async {
    final res = await _dio.get('/analytics/reports/weekly',
        queryParameters: {if (weekStart != null) 'weekStart': weekStart});
    return res.data['data'];
  }

  Future<List<String>> getSuggestions() async {
    final res = await _dio.get('/analytics/suggestions');
    final List list = res.data['data']['suggestions'];
    return list.map((e) => e.toString()).toList();
  }
}
