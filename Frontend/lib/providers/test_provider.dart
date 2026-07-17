import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/test_model.dart';
import '../services/test_service.dart';

// ── Service provider ──────────────────────────────────────────────────────────
final testServiceProvider = Provider((_) => TestService());

// ── History list ──────────────────────────────────────────────────────────────
final testHistoryProvider =
    FutureProvider.autoDispose<List<TestModel>>((ref) async {
  return ref.read(testServiceProvider).getHistory();
});

// ── Analytics stats ───────────────────────────────────────────────────────────
final testStatsProvider = FutureProvider.autoDispose<TestStats>((ref) async {
  return ref.read(testServiceProvider).getStats();
});

// ── Active draft ──────────────────────────────────────────────────────────────
final activeDraftProvider =
    FutureProvider.autoDispose<TestModel?>((ref) async {
  return ref.read(testServiceProvider).getActiveDraft();
});

// ── Active test state (during test-taking) ────────────────────────────────────
class ActiveTestState {
  final TestModel? test;
  final Map<int, String> answers; // questionIndex → answer string
  final int currentIndex;
  final bool isSubmitting;
  final bool isLoading;
  final String? error;

  const ActiveTestState({
    this.test,
    this.answers = const {},
    this.currentIndex = 0,
    this.isSubmitting = false,
    this.isLoading = false,
    this.error,
  });

  ActiveTestState copyWith({
    TestModel? test,
    Map<int, String>? answers,
    int? currentIndex,
    bool? isSubmitting,
    bool? isLoading,
    String? error,
  }) =>
      ActiveTestState(
        test: test ?? this.test,
        answers: answers ?? this.answers,
        currentIndex: currentIndex ?? this.currentIndex,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  int get totalQuestions => test?.questions.length ?? 0;
  int get answeredCount =>
      answers.values.where((v) => v.isNotEmpty).length;

  bool isAnswered(int index) =>
      (answers[index]?.isNotEmpty ?? false);
}

class ActiveTestNotifier extends StateNotifier<ActiveTestState> {
  final TestService _service;

  ActiveTestNotifier(this._service) : super(const ActiveTestState());

  Future<void> loadTest(String testId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final test = await _service.startTest(testId);
      // Pre-fill any already saved answers
      final Map<int, String> existingAnswers = {};
      for (final ans in test.answers) {
        if (ans.userAnswer != null) {
          existingAnswers[ans.questionIndex] = ans.userAnswer!;
        }
      }
      state = state.copyWith(
        test: test,
        answers: existingAnswers,
        currentIndex: 0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  void selectAnswer(int questionIndex, String answer) {
    final updated = Map<int, String>.from(state.answers);
    updated[questionIndex] = answer;
    state = state.copyWith(answers: updated);

    // Fire-and-forget auto-save
    if (state.test != null) {
      _service
          .saveAnswer(state.test!.id, questionIndex, answer)
          .catchError((_) {});
    }
  }

  void goToQuestion(int index) {
    if (index < 0 || index >= state.totalQuestions) return;
    state = state.copyWith(currentIndex: index);
  }

  void nextQuestion() => goToQuestion(state.currentIndex + 1);
  void prevQuestion() => goToQuestion(state.currentIndex - 1);

  Future<TestModel?> submitTest(int timeSpentSecs) async {
    if (state.test == null) return null;
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final answerList = state.answers.entries
          .map((e) => {'questionIndex': e.key, 'userAnswer': e.value})
          .toList();
      final result = await _service.submitTest(
          state.test!.id, answerList, timeSpentSecs);
      state = state.copyWith(isSubmitting: false);
      return result;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: _parseError(e));
      return null;
    }
  }

  void reset() {
    state = const ActiveTestState();
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      final d = e.response?.data;
      if (d is Map && d['error'] != null) {
        return d['error']['message'] ?? 'Something went wrong';
      }
    }
    return e.toString().replaceAll('Exception: ', '');
  }
}

final activeTestProvider =
    StateNotifierProvider<ActiveTestNotifier, ActiveTestState>(
  (ref) => ActiveTestNotifier(ref.read(testServiceProvider)),
);

// ── Analysis state ────────────────────────────────────────────────────────────
class AnalysisState {
  final TestModel? test;
  final bool isLoading;
  final String? error;

  const AnalysisState({this.test, this.isLoading = false, this.error});
}

class AnalysisNotifier extends StateNotifier<AnalysisState> {
  final TestService _service;

  AnalysisNotifier(this._service) : super(const AnalysisState());

  Future<void> analyse(String testId) async {
    state = const AnalysisState(isLoading: true);
    try {
      final test = await _service.analyseTest(testId);
      state = AnalysisState(test: test);
    } catch (e) {
      state = AnalysisState(error: e.toString());
    }
  }

  void setTest(TestModel test) {
    state = AnalysisState(test: test);
  }
}

final analysisProvider =
    StateNotifierProvider<AnalysisNotifier, AnalysisState>(
  (ref) => AnalysisNotifier(ref.read(testServiceProvider)),
);
