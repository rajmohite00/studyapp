import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/test_provider.dart';
import '../models/test_model.dart';
import '../app_theme.dart';
import '../widgets/shimmer_box.dart';

class TestReportScreen extends ConsumerStatefulWidget {
  final String testId;
  const TestReportScreen({super.key, required this.testId});
  @override
  ConsumerState<TestReportScreen> createState() => _TestReportScreenState();
}

class _TestReportScreenState extends ConsumerState<TestReportScreen>
    with SingleTickerProviderStateMixin {
  late Future<TestModel> _testFuture;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    // Load the test with full data
    _testFuture = ref.read(testServiceProvider).getTest(widget.testId);
    // Kick off AI analysis — when it completes, analysisProvider updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analysisProvider.notifier).analyse(widget.testId);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch analysis so tabs rebuild when AI data arrives
    final analysis = ref.watch(analysisProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              size: 22, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Detailed Report',
            style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFF0F0F5)),
        ),
      ),
      body: FutureBuilder<TestModel>(
        future: _testFuture,
        builder: (ctx, snap) {
          // ── Loading ──────────────────────────────────
          if (snap.connectionState == ConnectionState.waiting) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                ShimmerBox(height: 56, borderRadius: BorderRadius.circular(12)),
                const SizedBox(height: 10),
                ShimmerBox(height: 48, borderRadius: BorderRadius.circular(12)),
                const SizedBox(height: 12),
                const ShimmerCard(height: 80),
                const ShimmerCard(height: 80),
                const ShimmerCard(height: 120),
              ]),
            );
          }
          // ── Error ────────────────────────────────────
          if (!snap.hasData || snap.hasError) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Failed to load report',
                  style: GoogleFonts.outfit(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: Text('Go Back', style: GoogleFonts.outfit()),
              ),
            ]));
          }

          final test = snap.data!;
          // Use AI data from analysisProvider if available (it may be fresher)
          final liveAnalysis = analysis.test?.id == test.id
              ? analysis.test
              : null;
          final effectiveTest = liveAnalysis ?? test;

          return Column(children: [
            // ── Overview header ───────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(test.subject,
                          style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      Text(
                        '${test.correct}/${test.totalQuestions} Correct  ·  ${test.percentage}%  ·  Grade ${test.grade}',
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  )),
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: _gradeColor(test.percentage)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: Text(test.grade,
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: _gradeColor(test.percentage)))),
                  ),
                ]),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tabs,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: GoogleFonts.outfit(
                      fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.outfit(
                      fontSize: 13, fontWeight: FontWeight.w500),
                  tabs: const [
                    Tab(text: 'Questions'),
                    Tab(text: 'Analysis'),
                    Tab(text: 'Revision'),
                  ],
                ),
              ]),
            ),
            // ── Tab content ───────────────────────────
            Expanded(child: TabBarView(
              controller: _tabs,
              children: [
                _QuestionsTab(test: test),
                _AnalysisTab(test: effectiveTest, isLoading: analysis.isLoading),
                _RevisionTab(test: effectiveTest, isLoading: analysis.isLoading),
              ],
            )),
          ]);
        },
      ),
    );
  }

  static Color _gradeColor(int pct) {
    if (pct >= 80) return AppColors.accentGreen;
    if (pct >= 60) return AppColors.primary;
    if (pct >= 50) return AppColors.accentOrange;
    return const Color(0xFFEF4444);
  }
}

// ── Questions Tab ─────────────────────────────────────────────────────────────
class _QuestionsTab extends StatelessWidget {
  final TestModel test;
  const _QuestionsTab({required this.test});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: test.questions.length,
      itemBuilder: (ctx, i) {
        final q = test.questions[i];
        final ans = test.answers.firstWhere(
          (a) => a.questionIndex == i,
          orElse: () =>
              const TestAnswer(questionIndex: -1, isCorrect: false),
        );
        final isCorrect = ans.questionIndex != -1 && ans.isCorrect;
        final isSkipped =
            ans.questionIndex == -1 || ans.userAnswer == null;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSkipped
                  ? AppColors.divider
                  : isCorrect
                      ? AppColors.accentGreen.withValues(alpha: 0.4)
                      : AppColors.accent.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSkipped
                      ? AppColors.surface
                      : isCorrect
                          ? AppColors.accentGreen.withValues(alpha: 0.08)
                          : AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(13)),
                ),
                child: Row(children: [
                  Text('Q${i + 1}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary)),
                  const Spacer(),
                  Icon(
                    isSkipped
                        ? Icons.remove_circle_outline_rounded
                        : isCorrect
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                    size: 16,
                    color: isSkipped
                        ? AppColors.textLight
                        : isCorrect
                            ? AppColors.accentGreen
                            : AppColors.accent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isSkipped
                        ? 'Skipped'
                        : isCorrect
                            ? 'Correct'
                            : 'Wrong',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSkipped
                            ? AppColors.textLight
                            : isCorrect
                                ? AppColors.accentGreen
                                : AppColors.accent),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.question,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.4)),
                    const SizedBox(height: 10),
                    if (!isSkipped && ans.userAnswer != null) ...[
                      _AnswerRow(
                          label: 'Your answer',
                          value: ans.userAnswer!,
                          color: isCorrect
                              ? AppColors.accentGreen
                              : AppColors.accent),
                    ] else if (isSkipped) ...[
                      const Text('Not attempted',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                              fontStyle: FontStyle.italic)),
                    ],
                    _AnswerRow(
                        label: 'Correct answer',
                        value: q.correctAnswer,
                        color: AppColors.accentGreen),
                    if (q.explanation.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(q.explanation,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      height: 1.4)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnswerRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _AnswerRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text('$label:',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
            ),
            Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ),
          ],
        ),
      );
}

// ── Analysis Tab ──────────────────────────────────────────────────────────────
class _AnalysisTab extends StatelessWidget {
  final TestModel test;
  final bool isLoading;
  const _AnalysisTab({required this.test, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(width: 28, height: 28,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: AppColors.primary)),
        const SizedBox(height: 14),
        Text('Generating AI analysis…',
            style: GoogleFonts.outfit(
                color: AppColors.textSecondary, fontSize: 13)),
      ]));
    }

    final analysis = test.aiAnalysis;
    if (analysis == null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.auto_awesome_outlined,
                color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: 16),
          Text('Analysis not yet available',
              style: GoogleFonts.outfit(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('The AI is still processing this test.',
              style: GoogleFonts.outfit(
                  color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center),
        ]),
      ));
    }

    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 40), children: [
      // Motivation message banner
      if (analysis.motivationMessage.isNotEmpty)
        _InfoBanner(text: analysis.motivationMessage),
      _Section('Overall Performance', analysis.overallPerformance),
      _Section('Estimated Level', analysis.estimatedLevel),
      _Section('Difficulty Analysis', analysis.difficultyAnalysis),
      _Section('Learning Pattern', analysis.learningPattern),
      _Section('Mistakes Observed', analysis.mistakes),
      _Section('Knowledge Gaps', analysis.knowledgeGaps),
      _Section('Personalised Feedback', analysis.personalizedFeedback),
      if (analysis.strongTopics.isNotEmpty)
        _ChipSection('💪 Strong Topics',
            analysis.strongTopics, AppColors.accentGreen),
      if (analysis.weakTopics.isNotEmpty)
        _ChipSection('⚠️ Needs Work',
            analysis.weakTopics, const Color(0xFFEF4444)),
      if (analysis.conceptsToRevise.isNotEmpty)
        _ListSection('📖 Concepts to Revise',
            analysis.conceptsToRevise,
            Icons.refresh_rounded, AppColors.accentOrange),
      if (analysis.studySuggestions.isNotEmpty)
        _ListSection('💡 Study Suggestions',
            analysis.studySuggestions,
            Icons.lightbulb_outline_rounded, AppColors.primary),
    ]);
  }
}

// ── Shared card widgets ───────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final String text;
  const _InfoBanner({required this.text});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.primary),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: GoogleFonts.outfit(
          fontSize: 13, color: AppColors.primaryDark,
          fontStyle: FontStyle.italic, height: 1.5))),
    ]),
  );
}

Widget _Section(String title, String content) {
  if (content.isEmpty) return const SizedBox.shrink();
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.outfit(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: AppColors.primary, letterSpacing: 0.3)),
      const SizedBox(height: 6),
      Text(content, style: GoogleFonts.outfit(
          fontSize: 13, color: AppColors.textPrimary, height: 1.5)),
    ]),
  );
}

Widget _ChipSection(String title, List<String> items, Color color) =>
    Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.outfit(
            fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6,
          children: items.map((t) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Text(t, style: GoogleFonts.outfit(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          )).toList(),
        ),
      ]),
    );

Widget _ListSection(String title, List<String> items, IconData icon, Color color) =>
    Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.outfit(
            fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        ...items.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 7),
            Expanded(child: Text(s, style: GoogleFonts.outfit(
                fontSize: 13, color: AppColors.textPrimary, height: 1.4))),
          ]),
        )),
      ]),
    );

// ── Revision Tab ──────────────────────────────────────────────────────────────
class _RevisionTab extends StatelessWidget {
  final TestModel test;
  final bool isLoading;
  const _RevisionTab({required this.test, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(width: 28, height: 28,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: AppColors.primary)),
        const SizedBox(height: 14),
        Text('Building revision plan…',
            style: GoogleFonts.outfit(
                color: AppColors.textSecondary, fontSize: 13)),
      ]));
    }

    final plan = test.revisionPlan;
    if (plan == null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.menu_book_outlined,
                color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: 16),
          Text('Revision plan not yet ready',
              style: GoogleFonts.outfit(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('The AI is still generating your plan.',
              style: GoogleFonts.outfit(
                  color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center),
        ]),
      ));
    }

    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 40), children: [
      if (plan.highPriority.isNotEmpty)
        _PlanGroup('🔴 High Priority', plan.highPriority,
            const Color(0xFFEF4444)),
      if (plan.mediumPriority.isNotEmpty)
        _PlanGroup('🟡 Medium Priority', plan.mediumPriority,
            AppColors.accentOrange),
      if (plan.lowPriority.isNotEmpty)
        _PlanGroup('🟢 Low Priority', plan.lowPriority,
            AppColors.accentGreen),
      if (plan.studyOrder.isNotEmpty) ...[
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('📋 Recommended Study Order',
                style: GoogleFonts.outfit(fontSize: 14,
                    fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            ...plan.studyOrder.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(7)),
                  child: Center(child: Text('${e.key + 1}',
                      style: GoogleFonts.outfit(fontSize: 11,
                          fontWeight: FontWeight.w700, color: AppColors.primary))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(e.value,
                    style: GoogleFonts.outfit(
                        fontSize: 13, color: AppColors.textPrimary))),
              ]),
            )),
          ]),
        ),
      ],
      if (plan.estimatedHours > 0 || plan.suggestedNextTest.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (plan.estimatedHours > 0)
              Row(children: [
                const Icon(Icons.access_time_outlined,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Estimated revision: ~${plan.estimatedHours} hours',
                    style: GoogleFonts.outfit(color: AppColors.primary,
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            if (plan.estimatedHours > 0 && plan.suggestedNextTest.isNotEmpty)
              const SizedBox(height: 8),
            if (plan.suggestedNextTest.isNotEmpty)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.quiz_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text('Next test: ${plan.suggestedNextTest}',
                    style: GoogleFonts.outfit(color: AppColors.primary,
                        fontWeight: FontWeight.w600, fontSize: 13))),
              ]),
          ]),
        ),
      ],
      const SizedBox(height: 20),
    ]);
  }
}

class _PlanGroup extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;
  const _PlanGroup(this.title, this.items, this.color);

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.25)),
      boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.outfit(
          fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6,
        children: items.map((t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(t, style: GoogleFonts.outfit(
              fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        )).toList(),
      ),
    ]),
  );
}
