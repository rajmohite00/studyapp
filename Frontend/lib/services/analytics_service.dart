import 'dart:convert';
import 'dio_client.dart';
import '../models/analytics_model.dart';
import 'storage_service.dart';

class AnalyticsService {
  final _dio = DioClient.instance;

  Future<AnalyticsModel> getDashboard() async {
    try {
      final res = await _dio.get('/analytics/summary');
      final data = res.data['data'];
      await StorageService.put('cached_dashboard', jsonEncode(data));
      return AnalyticsModel.fromJson(data);
    } catch (e) {
      final cachedStr = StorageService.get<String>('cached_dashboard');
      if (cachedStr != null) {
        return AnalyticsModel.fromJson(jsonDecode(cachedStr));
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getDailyAnalytics({String? from, String? to}) async {
    final res = await _dio.get('/analytics/daily', queryParameters: {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    });
    return List<Map<String, dynamic>>.from(res.data['data']);
  }

  Future<Map<String, int>> getSubjectBreakdown({int days = 30}) async {
    try {
      final res = await _dio.get('/analytics/subjects', queryParameters: {'days': days});
      final data = res.data['data'];
      await StorageService.put('cached_subject_breakdown', jsonEncode(data));
      return Map<String, int>.from((data as Map).map((k, v) => MapEntry(k, (v as num).toInt())));
    } catch (e) {
      final cachedStr = StorageService.get<String>('cached_subject_breakdown');
      if (cachedStr != null) {
        final data = jsonDecode(cachedStr);
        return Map<String, int>.from((data as Map).map((k, v) => MapEntry(k, (v as num).toInt())));
      }
      rethrow;
    }
  }

  Future<StreakSummary> getStreak() async {
    try {
      final res = await _dio.get('/analytics/streak');
      final data = res.data['data'];
      await StorageService.put('cached_streak', jsonEncode(data));
      return StreakSummary.fromJson(data);
    } catch (e) {
      final cachedStr = StorageService.get<String>('cached_streak');
      if (cachedStr != null) {
        return StreakSummary.fromJson(jsonDecode(cachedStr));
      }
      rethrow;
    }
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
    try {
      final res = await _dio.get('/analytics/reports/weekly',
          queryParameters: {if (weekStart != null) 'weekStart': weekStart});
      final data = res.data['data'];
      await StorageService.put('cached_weekly_report', jsonEncode(data));
      return data;
    } catch (e) {
      final cachedStr = StorageService.get<String>('cached_weekly_report');
      if (cachedStr != null) {
        return jsonDecode(cachedStr);
      }
      rethrow;
    }
  }

  Future<List<String>> getSuggestions() async {
    final res = await _dio.get('/analytics/suggestions');
    final List list = res.data['data']['suggestions'];
    return list.map((e) => e.toString()).toList();
  }
}
