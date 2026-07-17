import 'dio_client.dart';
import '../models/test_model.dart';

class TestService {
  final _dio = DioClient.instance;

  // Create a new test (generates questions via Groq)
  Future<TestModel> createTest({
    required String subject,
    required List<String> topics,
    required String testType,
    required String difficulty,
    required int questionCount,
    required int timerMinutes,
  }) async {
    final res = await _dio.post('/tests/create', data: {
      'subject': subject,
      'topics': topics,
      'testType': testType,
      'difficulty': difficulty,
      'questionCount': questionCount,
      'timerMinutes': timerMinutes,
    });
    return TestModel.fromJson(res.data['data']);
  }

  // Start / resume a test
  Future<TestModel> startTest(String testId) async {
    final res = await _dio.post('/tests/$testId/start');
    return TestModel.fromJson(res.data['data']);
  }

  // Auto-save a single answer
  Future<void> saveAnswer(String testId, int questionIndex, String? userAnswer) async {
    await _dio.patch('/tests/$testId/answer', data: {
      'questionIndex': questionIndex,
      'userAnswer': userAnswer,
    });
  }

  // Bulk-save answers (sync before close)
  Future<void> saveBulkAnswers(
      String testId, List<Map<String, dynamic>> answers) async {
    await _dio.patch('/tests/$testId/answers/bulk', data: {'answers': answers});
  }

  // Submit test
  Future<TestModel> submitTest(
      String testId, List<Map<String, dynamic>> answers, int timeSpentSecs) async {
    final res = await _dio.post('/tests/$testId/submit', data: {
      'answers': answers,
      'timeSpentSecs': timeSpentSecs,
    });
    return TestModel.fromJson(res.data['data']);
  }

  // Request AI analysis (may take ~5-10s)
  Future<TestModel> analyseTest(String testId) async {
    final res = await _dio.post('/tests/$testId/analyse');
    return TestModel.fromJson(res.data['data']);
  }

  // Get history list
  Future<List<TestModel>> getHistory({
    String? subject,
    String? difficulty,
  }) async {
    final res = await _dio.get('/tests/history', queryParameters: {
      if (subject != null) 'subject': subject,
      if (difficulty != null) 'difficulty': difficulty,
    });
    return (res.data['data'] as List)
        .map((t) => TestModel.fromJson(t))
        .toList();
  }

  // Get single test (full detail with questions+answers)
  Future<TestModel> getTest(String testId) async {
    final res = await _dio.get('/tests/$testId');
    return TestModel.fromJson(res.data['data']);
  }

  // Analytics
  Future<TestStats> getStats() async {
    final res = await _dio.get('/tests/stats');
    return TestStats.fromJson(res.data['data']);
  }

  // Delete
  Future<void> deleteTest(String testId) async {
    await _dio.delete('/tests/$testId');
  }

  // Active draft
  Future<TestModel?> getActiveDraft() async {
    final res = await _dio.get('/tests/draft/active');
    if (res.data['data'] == null) return null;
    return TestModel.fromJson(res.data['data']);
  }
}
