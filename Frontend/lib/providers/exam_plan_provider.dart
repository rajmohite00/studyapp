import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exam_plan_model.dart';
import '../services/exam_plan_service.dart';

final examPlanServiceProvider = Provider((_) => ExamPlanService());

// Active exam plan
final examPlanProvider = FutureProvider.autoDispose<ExamPlanModel?>((ref) async {
  return ref.read(examPlanServiceProvider).getPlan();
});

// Progress summary
final examProgressProvider = FutureProvider.autoDispose<ExamPlanProgress?>((ref) async {
  return ref.read(examPlanServiceProvider).getProgress();
});

// ── Notifier for plan creation + task toggling ───────────────────────────────

class ExamPlanNotifier extends StateNotifier<AsyncValue<ExamPlanModel?>> {
  final ExamPlanService _service;
  final Ref _ref;

  ExamPlanNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      state = AsyncValue.loading();
      final plan = await _service.getPlan();
      state = AsyncValue.data(plan);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<String?> createPlan({
    required List<String> subjects,
    required DateTime examDate,
    required double dailyStudyHours,
  }) async {
    try {
      state = const AsyncValue.loading();
      final plan = await _service.createPlan(
        subjects: subjects,
        examDate: examDate,
        dailyStudyHours: dailyStudyHours,
      );
      state = AsyncValue.data(plan);
      // Invalidate progress cache
      _ref.invalidate(examProgressProvider);
      return null; // success, no error
    } catch (e) {
      await _load();
      return e.toString();
    }
  }

  Future<void> toggleTask(String planId, int taskIndex, bool completed) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // Optimistic update - MUST create a new object instance for Riverpod to trigger UI rebuild
    final newTasks = List<DailyTaskModel>.from(current.generatedPlan);
    newTasks[taskIndex] = newTasks[taskIndex].copyWith(isCompleted: completed);
    
    final optimisticPlan = ExamPlanModel(
      id: current.id,
      subjects: current.subjects,
      examDate: current.examDate,
      totalDays: current.totalDays,
      dailyStudyHours: current.dailyStudyHours,
      generatedPlan: newTasks,
      importantTopics: current.importantTopics,
    );
    state = AsyncValue.data(optimisticPlan);

    try {
      final updatedTasks = await _service.markTask(
        planId: planId,
        taskIndex: taskIndex,
        completed: completed,
      );
      // Sync with server response
      final updated = ExamPlanModel(
        id: current.id,
        subjects: current.subjects,
        examDate: current.examDate,
        totalDays: current.totalDays,
        dailyStudyHours: current.dailyStudyHours,
        generatedPlan: updatedTasks,
        importantTopics: current.importantTopics,
      );
      state = AsyncValue.data(updated);
      // Fire-and-forget invalidate so progress updates in background
      Future.microtask(() => _ref.invalidate(examProgressProvider));
    } catch (_) {
      // Revert optimistic update on error
      state = AsyncValue.data(current);
    }
  }


  Future<void> refresh() => _load();
}

final examPlanNotifierProvider =
    StateNotifierProvider<ExamPlanNotifier, AsyncValue<ExamPlanModel?>>((ref) {
  final service = ref.read(examPlanServiceProvider);
  return ExamPlanNotifier(service, ref);
});
