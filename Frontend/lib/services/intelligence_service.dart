import 'dio_client.dart';

class IntelligenceService {
  final _dio = DioClient.instance;

  Future<Map<String, dynamic>> getBurnout() async {
    final res = await _dio.get('/intelligence/burnout');
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getPrediction() async {
    final res = await _dio.get('/intelligence/prediction');
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getInsights() async {
    final res = await _dio.get('/intelligence/insights');
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getPerformance() async {
    final res = await _dio.get('/intelligence/performance');
    return res.data['data'];
  }
}
