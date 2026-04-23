import 'dio_client.dart';
import '../models/exam_plan_model.dart';

class ExamPlanService {
  final _dio = DioClient.instance;

  Future<ExamPlanModel> createPlan({
    required List<String> subjects,
    required DateTime examDate,
    required double dailyStudyHours,
  }) async {
    final res = await _dio.post('/exam-plan/create', data: {
      'subjects': subjects,
      'examDate': examDate.toIso8601String(),
      'dailyStudyHours': dailyStudyHours,
    });
    return ExamPlanModel.fromJson(res.data['data']);
  }

  Future<ExamPlanModel?> getPlan() async {
    final res = await _dio.get('/exam-plan');
    if (res.data['data'] == null) return null;
    return ExamPlanModel.fromJson(res.data['data']);
  }

  Future<ExamPlanProgress?> getProgress() async {
    final res = await _dio.get('/exam-plan/progress');
    if (res.data['data'] == null) return null;
    return ExamPlanProgress.fromJson(res.data['data']);
  }

  Future<List<DailyTaskModel>> markTask({
    required String planId,
    required int taskIndex,
    required bool completed,
  }) async {
    final res = await _dio.patch('/exam-plan/task', data: {
      'planId': planId,
      'taskIndex': taskIndex,
      'completed': completed,
    });
    final rawList = res.data['data']['generatedPlan'] as List<dynamic>;
    return rawList.map((t) => DailyTaskModel.fromJson(t)).toList();
  }
}
