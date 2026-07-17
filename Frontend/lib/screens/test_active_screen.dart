import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/test_provider.dart';
import '../models/test_model.dart';
import '../app_theme.dart';

class TestActiveScreen extends ConsumerStatefulWidget {
  final String testId;
  const TestActiveScreen({super.key, required this.testId});

  @override
  ConsumerState<TestActiveScreen> createState() => _TestActiveScreenState();
}

class _TestActiveScreenState extends ConsumerState<TestActiveScreen> {
  Timer? _timer;
  int _elapsedSecs = 0;
  int? _remainingSecs; // null = no timer
  bool _timerStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await ref.read(activeTestProvider.notifier).loadTest(widget.testId);
    final state = ref.read(activeTestProvider);
    if (state.test != null && state.test!.timerMinutes > 0) {
      _remainingSecs = state.test!.timerMinutes * 60;
    }
    _startTimer();
  }

  void _startTimer() {
    if (_timerStarted) return;
    _timerStarted = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedSecs++;
        if (_remainingSecs != null) {
          _remainingSecs = (_remainingSecs! - 1).clamp(0, 99999);
          if (_remainingSecs == 0) _confirmSubmit(autoSubmit: true);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _confirmSubmit({bool autoSubmit = false}) {
    _timer?.cancel();
    if (autoSubmit) {
      _doSubmit();
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Submit Test?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Builder(builder: (ctx) {
          final state = ref.read(activeTestProvider);
          final unanswered =
              state.totalQuestions - state.answeredCount;
          return Text(
              unanswered > 0
                  ? 'You have $unanswered unanswered questions. Submit anyway?'
                  : 'Are you sure you want to submit?',
              style: const TextStyle(color: AppColors.textSecondary));
        }),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                _startTimer(); // resume
              },
              child: const Text('Keep Going')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _doSubmit();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: Size.zero,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _doSubmit() async {
    final result = await ref
        .read(activeTestProvider.notifier)
        .submitTest(_elapsedSecs);
    if (!mounted) return;
    if (result != null) {
      ref.invalidate(testHistoryProvider);
      ref.invalidate(activeDraftProvider);
      ref.invalidate(testStatsProvider);
      context.go('/tests/results/${result.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeTestProvider);

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
            SizedBox(height: 16),
            Text('Loading test...',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        )),
      );
    }

    if (state.test == null) {
      return Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Test not found',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: () => context.go('/tests'),
                child: const Text('Go Back')),
          ]),
        ),
      );
    }

    final test = state.test!;
    final q = test.questions[state.currentIndex];
    final answered = state.answers[state.currentIndex];

    return WillPopScope(
      onWillPop: () async {
        _timer?.cancel();
        // auto-save progress before leaving
        final answers = state.answers.entries
            .map((e) => {'questionIndex': e.key, 'userAnswer': e.value})
            .toList();
        ref
            .read(testServiceProvider)
            .saveBulkAnswers(test.id, answers)
            .catchError((_) {});
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(state, test),
        body: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: (state.currentIndex + 1) / state.totalQuestions,
              backgroundColor: AppColors.divider,
              color: AppColors.primary,
              minHeight: 3,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question number badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Q ${state.currentIndex + 1} of ${state.totalQuestions}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary),
                          ),
                        ),
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.divider)),
                            child: Text(
                              _diffLabel(q.difficulty),
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _diffColor(q.difficulty)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.divider)),
                            child: Text(
                              _typeLabel(q.type),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Question card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Text(
                        q.question,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Options / Input
                    if (q.type == 'mcq' || q.type == 'true_false')
                      ..._buildOptions(q, answered, state)
                    else
                      _buildTextInput(q, answered, state),

                    const SizedBox(height: 24),

                    // Question grid navigator
                    _QuestionGrid(
                      total: state.totalQuestions,
                      current: state.currentIndex,
                      answers: state.answers,
                      onTap: (i) =>
                          ref.read(activeTestProvider.notifier).goToQuestion(i),
                    ),
                  ],
                ),
              ),
            ),

            // Nav buttons
            _NavBar(
              state: state,
              isSubmitting: state.isSubmitting,
              onPrev: () =>
                  ref.read(activeTestProvider.notifier).prevQuestion(),
              onNext: () =>
                  ref.read(activeTestProvider.notifier).nextQuestion(),
              onSubmit: () => _confirmSubmit(),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(ActiveTestState state, TestModel test) {
    final timerStr = _remainingSecs != null
        ? _fmtTime(_remainingSecs!)
        : _fmtTime(_elapsedSecs);
    final isLow = _remainingSecs != null && _remainingSecs! < 60;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded,
            color: AppColors.textPrimary),
        onPressed: () {
          _timer?.cancel();
          context.go('/tests');
        },
      ),
      title: Text(test.subject,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
      actions: [
        // Timer chip
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isLow
                ? AppColors.accent.withValues(alpha: 0.12)
                : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.timer_outlined,
                size: 14,
                color: isLow ? AppColors.accent : AppColors.primary),
            const SizedBox(width: 4),
            Text(timerStr,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isLow ? AppColors.accent : AppColors.primary)),
          ]),
        ),
        // Score chip
        Container(
          margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: AppColors.accentGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20)),
          child: Text(
            '${state.answeredCount}/${state.totalQuestions}',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accentGreen),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildOptions(
      TestQuestion q, String? answered, ActiveTestState state) {
    return q.options.map((opt) {
      final isSel = answered == opt;
      return GestureDetector(
        onTap: () => ref
            .read(activeTestProvider.notifier)
            .selectAnswer(state.currentIndex, opt),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSel ? AppColors.primaryLight : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isSel ? AppColors.primary : AppColors.divider,
                width: isSel ? 2 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSel ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color:
                          isSel ? AppColors.primary : AppColors.textLight,
                      width: 1.5),
                ),
                child: isSel
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 13)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  opt,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                      color: isSel
                          ? AppColors.primary
                          : AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildTextInput(
      TestQuestion q, String? answered, ActiveTestState state) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: answered != null && answered.isNotEmpty
                  ? AppColors.primary
                  : AppColors.divider)),
      child: TextField(
        controller: TextEditingController(text: answered ?? ''),
        onChanged: (v) => ref
            .read(activeTestProvider.notifier)
            .selectAnswer(state.currentIndex, v),
        decoration: InputDecoration(
          hintText: q.type == 'fill_blank'
              ? 'Type the missing word/phrase...'
              : 'Type your answer...',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
        maxLines: q.type == 'short_answer' ? 3 : 1,
        style: const TextStyle(
            fontSize: 15, color: AppColors.textPrimary),
      ),
    );
  }

  String _fmtTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _diffLabel(String d) {
    switch (d) {
      case 'easy': return 'Easy';
      case 'hard': return 'Hard';
      default: return 'Medium';
    }
  }

  Color _diffColor(String d) {
    switch (d) {
      case 'easy': return AppColors.accentGreen;
      case 'hard': return AppColors.accent;
      default: return AppColors.accentOrange;
    }
  }

  String _typeLabel(String t) {
    switch (t) {
      case 'true_false': return 'True/False';
      case 'fill_blank': return 'Fill Blank';
      case 'short_answer': return 'Short Answer';
      default: return 'MCQ';
    }
  }
}

// ── Question Grid ─────────────────────────────────────────────────────────────
class _QuestionGrid extends StatelessWidget {
  final int total, current;
  final Map<int, String> answers;
  final ValueChanged<int> onTap;
  const _QuestionGrid(
      {required this.total,
      required this.current,
      required this.answers,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Questions',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(total, (i) {
              final isAnswered =
                  answers[i] != null && answers[i]!.isNotEmpty;
              final isCurrent = i == current;
              return GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.primary
                        : isAnswered
                            ? AppColors.accentGreen
                            : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: (isCurrent || isAnswered)
                              ? Colors.white
                              : AppColors.textSecondary),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(children: [
            _Legend(color: AppColors.primary, label: 'Current'),
            const SizedBox(width: 16),
            _Legend(color: AppColors.accentGreen, label: 'Answered'),
            const SizedBox(width: 16),
            _Legend(color: const Color(0xFFF5F5F5), label: 'Unanswered', dark: true),
          ]),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final bool dark;
  const _Legend({required this.color, required this.label, this.dark = false});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(
        width: 12, height: 12,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 4),
    Text(label,
        style: TextStyle(
            fontSize: 10,
            color: dark ? AppColors.textSecondary : AppColors.textSecondary)),
  ]);
}

// ── Nav Bar ───────────────────────────────────────────────────────────────────
class _NavBar extends StatelessWidget {
  final ActiveTestState state;
  final bool isSubmitting;
  final VoidCallback onPrev, onNext, onSubmit;
  const _NavBar(
      {required this.state,
      required this.isSubmitting,
      required this.onPrev,
      required this.onNext,
      required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final isLast = state.currentIndex == state.totalQuestions - 1;
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      color: Colors.white,
      child: Row(
        children: [
          if (state.currentIndex > 0) ...[
            GestureDetector(
              onTap: onPrev,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_rounded,
                        color: AppColors.textPrimary, size: 18),
                    SizedBox(width: 6),
                    Text('Prev',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: GestureDetector(
              onTap: isSubmitting
                  ? null
                  : isLast
                      ? onSubmit
                      : onNext,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isLast ? AppColors.accentGreen : AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isLast ? 'Submit Test' : 'Next',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              isLast
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
