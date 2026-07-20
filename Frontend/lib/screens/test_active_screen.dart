import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/test_provider.dart';
import '../models/test_model.dart';
import '../app_theme.dart';
import '../widgets/shimmer_box.dart';

class TestActiveScreen extends ConsumerStatefulWidget {
  final String testId;
  const TestActiveScreen({super.key, required this.testId});
  @override
  ConsumerState<TestActiveScreen> createState() => _TestActiveScreenState();
}

class _TestActiveScreenState extends ConsumerState<TestActiveScreen> {
  Timer? _timer;
  int _elapsed = 0;
  int? _remaining;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await ref.read(activeTestProvider.notifier).loadTest(widget.testId);
    final s = ref.read(activeTestProvider);
    if (s.test != null && s.test!.timerMinutes > 0) {
      _remaining = s.test!.timerMinutes * 60;
    }
    _startTimer();
  }

  void _startTimer() {
    if (_started) return;
    _started = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed++;
        if (_remaining != null) {
          _remaining = (_remaining! - 1).clamp(0, 999999);
          if (_remaining == 0) _doSubmit();
        }
      });
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  void _askSubmit() {
    _timer?.cancel();
    final state = ref.read(activeTestProvider);
    final unanswered = state.totalQuestions - state.answeredCount;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Submit Test?', style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800, fontSize: 18)),
        content: Text(
          unanswered > 0
              ? '$unanswered question${unanswered > 1 ? 's' : ''} unanswered. Submit anyway?'
              : 'Are you sure you want to submit?',
          style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () { Navigator.pop(context); _startTimer(); },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.divider),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text('Keep Going', style: GoogleFonts.outfit(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _doSubmit(); },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text('Submit', style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _doSubmit() async {
    final result = await ref.read(activeTestProvider.notifier).submitTest(_elapsed);
    if (!mounted) return;
    if (result != null) {
      ref.invalidate(testHistoryProvider);
      ref.invalidate(testStatsProvider);
      ref.invalidate(activeDraftProvider);
      context.go('/tests/results/${result.id}');
    }
  }

  String _fmt(int secs) {
    final m = secs ~/ 60, s = secs % 60;
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeTestProvider);

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0,
          leading: IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
              onPressed: () => context.go('/home/tests'))),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            ShimmerBox(height: 6, borderRadius: BorderRadius.circular(3)),
            const SizedBox(height: 16),
            ShimmerBox(height: 120, borderRadius: BorderRadius.circular(18)),
            const SizedBox(height: 16),
            ...List.generate(4, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ShimmerBox(height: 62, borderRadius: BorderRadius.circular(14)),
            )),
          ]),
        ),
      );
    }

    if (state.test == null) {
      return Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Test not found', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: () => context.go('/home/tests'),
            child: Text('Go Back', style: GoogleFonts.outfit())),
      ])));
    }

    final test = state.test!;
    final q = test.questions[state.currentIndex];
    final answered = state.answers[state.currentIndex];
    final timerStr = _remaining != null ? _fmt(_remaining!) : _fmt(_elapsed);
    final isLow = _remaining != null && _remaining! < 60;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        _timer?.cancel();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leadingWidth: 48,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary, size: 22),
            onPressed: () { _timer?.cancel(); context.go('/home/tests'); },
          ),
          title: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text('Question ${state.currentIndex + 1} of ${state.totalQuestions}',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            Text(test.subject, style: GoogleFonts.outfit(fontSize: 11,
                color: AppColors.textSecondary)),
          ]),
          centerTitle: true,
          actions: [
            // Timer
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isLow
                    ? const Color(0xFFEF4444).withValues(alpha: 0.10)
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.timer_outlined, size: 14,
                    color: isLow ? const Color(0xFFEF4444) : AppColors.primary),
                const SizedBox(width: 4),
                Text(timerStr, style: GoogleFonts.outfit(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: isLow ? const Color(0xFFEF4444) : AppColors.primary)),
              ]),
            ),
            TextButton(
              onPressed: _askSubmit,
              child: Text('Submit', style: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          ],
          bottom: const PreferredSize(preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: Color(0xFFF0F0F5))),
        ),
        body: Column(children: [
          // Progress bar
          LinearProgressIndicator(
            value: (state.currentIndex + 1) / state.totalQuestions,
            backgroundColor: AppColors.primaryLight,
            color: AppColors.primary,
            minHeight: 4,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Question card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Text(q.question, style: GoogleFonts.outfit(
                      fontSize: 16, fontWeight: FontWeight.w600,
                      height: 1.6, color: AppColors.textPrimary)),
                ),
                const SizedBox(height: 16),

                // Options
                if (q.type == 'mcq' || q.type == 'true_false')
                  ..._buildOptions(q, answered, state)
                else
                  _TextInput(
                    key: ValueKey('txt_${state.currentIndex}'),
                    initial: answered ?? '',
                    type: q.type,
                    onChanged: (v) => ref.read(activeTestProvider.notifier)
                        .selectAnswer(state.currentIndex, v),
                  ),

                const SizedBox(height: 20),
                // Question number grid
                _QGrid(
                  total: state.totalQuestions,
                  current: state.currentIndex,
                  answers: state.answers,
                  onTap: (i) => ref.read(activeTestProvider.notifier).goToQuestion(i),
                ),
              ]),
            ),
          ),
          // Nav buttons
          _NavBar(
            state: state,
            isSubmitting: state.isSubmitting,
            onPrev: () => ref.read(activeTestProvider.notifier).prevQuestion(),
            onNext: () => ref.read(activeTestProvider.notifier).nextQuestion(),
            onSubmit: _askSubmit,
          ),
        ]),
      ),
    );
  }

  List<Widget> _buildOptions(TestQuestion q, String? answered, ActiveTestState state) {
    const labels = ['A','B','C','D','E','F'];
    return q.options.asMap().entries.map((e) {
      final i = e.key;
      final opt = e.value;
      final isSel = answered == opt;
      final label = i < labels.length ? labels[i] : '${i+1}';
      return GestureDetector(
        onTap: () => ref.read(activeTestProvider.notifier)
            .selectAnswer(state.currentIndex, opt),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSel ? AppColors.primaryLight : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isSel ? AppColors.primary : const Color(0xFFE8E6F0),
                width: isSel ? 2 : 1),
            boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: isSel ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                    color: isSel ? AppColors.primary : AppColors.textLight, width: 1.5),
              ),
              child: Center(child: Text(label, style: GoogleFonts.outfit(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: isSel ? Colors.white : AppColors.textSecondary))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(opt, style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                color: AppColors.textPrimary))),
          ]),
        ),
      );
    }).toList();
  }
}

// ── Question Number Grid ──────────────────────────────────────────────────────
class _QGrid extends StatelessWidget {
  final int total, current;
  final Map<int, String> answers;
  final ValueChanged<int> onTap;
  const _QGrid({required this.total, required this.current,
      required this.answers, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Questions', style: GoogleFonts.outfit(fontSize: 12,
              fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const Spacer(),
          _QGridLegend(color: AppColors.primary, label: 'Current'),
          const SizedBox(width: 10),
          _QGridLegend(color: AppColors.accentGreen, label: 'Done'),
        ]),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6, runSpacing: 6,
          children: List.generate(total, (i) {
            final isCurrent = i == current;
            final isDone = answers[i] != null && answers[i]!.isNotEmpty;
            Color bg = const Color(0xFFF3F3F7);
            Color fg = AppColors.textSecondary;
            if (isCurrent) { bg = AppColors.primary; fg = Colors.white; }
            else if (isDone) { bg = AppColors.accentGreen; fg = Colors.white; }
            return GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 34, height: 34,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Center(child: Text('${i+1}', style: GoogleFonts.outfit(
                    fontSize: 12, fontWeight: FontWeight.w700, color: fg))),
              ),
            );
          }),
        ),
      ]),
    );
  }
}

class _QGridLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _QGridLegend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textSecondary)),
  ]);
}

// ── Nav Bar ───────────────────────────────────────────────────────────────────
class _NavBar extends StatelessWidget {
  final ActiveTestState state;
  final bool isSubmitting;
  final VoidCallback onPrev, onNext, onSubmit;
  const _NavBar({required this.state, required this.isSubmitting,
      required this.onPrev, required this.onNext, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final isLast = state.currentIndex == state.totalQuestions - 1;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Row(children: [
        if (state.currentIndex > 0) ...[
          Expanded(
            child: GestureDetector(
              onTap: onPrev,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8E6F0), width: 1.5),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.chevron_left_rounded,
                      color: AppColors.textPrimary, size: 22),
                  Text('Previous', style: GoogleFonts.outfit(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: isSubmitting ? null : (isLast ? onSubmit : onNext),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: isSubmitting ? null : AppColors.heroGradient,
                color: isSubmitting ? AppColors.divider : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSubmitting ? [] : [BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Center(child: isSubmitting
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(isLast ? 'Submit' : 'Next', style: GoogleFonts.outfit(
                          fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(width: 4),
                      Icon(isLast ? Icons.check_circle_outline_rounded
                          : Icons.chevron_right_rounded,
                          color: Colors.white, size: 20),
                    ])),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Text answer input ─────────────────────────────────────────────────────────
class _TextInput extends StatefulWidget {
  final String initial, type;
  final ValueChanged<String> onChanged;
  const _TextInput({super.key, required this.initial,
      required this.type, required this.onChanged});
  @override
  State<_TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<_TextInput> {
  late final TextEditingController _c;
  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initial)
      ..selection = TextSelection.collapsed(offset: widget.initial.length);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: _c,
        onChanged: (v) { widget.onChanged(v); setState(() {}); },
        maxLines: widget.type == 'short_answer' ? 4 : 1,
        decoration: InputDecoration(
          hintText: widget.type == 'fill_blank'
              ? 'Type the missing word…' : 'Type your answer…',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          hintStyle: GoogleFonts.outfit(color: AppColors.textLight, fontSize: 14),
        ),
        style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textPrimary, height: 1.5),
      ),
    );
  }
}
