import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/test_provider.dart';
import '../models/test_model.dart';
import '../app_theme.dart';
import '../widgets/shimmer_box.dart';

class TestReportScreen extends ConsumerWidget {
  final String testId;
  const TestReportScreen({super.key, required this.testId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Detailed Report',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
      ),
      body: FutureBuilder<TestModel>(
        future: ref.read(testServiceProvider).getTest(testId),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: AppColors.textPrimary),
                  onPressed: () => context.pop(),
                ),
                title: const Text('Detailed Report',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  ShimmerBox(height: 48, borderRadius: BorderRadius.circular(12)),
                  const SizedBox(height: 12),
                  ShimmerBox(height: 72, borderRadius: BorderRadius.circular(14)),
                  const SizedBox(height: 12),
                  ShimmerBox(height: 72, borderRadius: BorderRadius.circular(14)),
                  const SizedBox(height: 12),
                  ShimmerBox(height: 72, borderRadius: BorderRadius.circular(14)),
                  const SizedBox(height: 12),
                  ShimmerBox(height: 140, borderRadius: BorderRadius.circular(14)),
                ]),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: Text('Failed to load report'));
          }
          return _ReportBody(test: snap.data!);
        },
      ),
    );
  }
}

class _ReportBody extends StatefulWidget {
  final TestModel test;
  const _ReportBody({required this.test});

  @override
  State<_ReportBody> createState() => _ReportBodyState();
}

class _ReportBodyState extends State<_ReportBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final test = widget.test;
    return Column(
      children: [
        // ── Overview header ──────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(test.subject,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary)),
                          Text(
                              '${test.correct}/${test.totalQuestions} Correct · ${test.percentage}% · Grade ${test.grade}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _gradeColor(test.percentage)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(test.grade,
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: _gradeColor(test.percentage))),
                      ),
                    ),
                  ]),
              const SizedBox(height: 12),
              TabBar(
                controller: _tabs,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                tabs: const [
                  Tab(text: 'Questions'),
                  Tab(text: 'Analysis'),
                  Tab(text: 'Revision'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _QuestionsTab(test: test),
              _AnalysisTab(test: test),
              _RevisionTab(test: test),
            ],
          ),
        ),
      ],
    );
  }

  Color _gradeColor(int pct) {
    if (pct >= 80) return AppColors.accentGreen;
    if (pct >= 60) return AppColors.primary;
    if (pct >= 50) return AppColors.accentOrange;
    return Colors.red.shade400;
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
  const _AnalysisTab({required this.test});

  @override
  Widget build(BuildContext context) {
    final analysis = test.aiAnalysis;
    if (analysis == null) {
      return const Center(
          child: Text('Analysis not available',
              style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Section(
            title: 'Overall Performance',
            content: analysis.overallPerformance),
        _Section(
            title: 'Difficulty Analysis',
            content: analysis.difficultyAnalysis),
        _Section(
            title: 'Learning Pattern',
            content: analysis.learningPattern),
        _Section(
            title: 'Mistakes',
            content: analysis.mistakes),
        _Section(
            title: 'Knowledge Gaps',
            content: analysis.knowledgeGaps),
        if (analysis.conceptsToRevise.isNotEmpty)
          _ListSection(
              title: 'Concepts to Revise',
              items: analysis.conceptsToRevise,
              icon: Icons.refresh_rounded,
              color: AppColors.accent),
        _Section(
            title: 'Estimated Level',
            content: analysis.estimatedLevel),
        if (analysis.studySuggestions.isNotEmpty)
          _ListSection(
              title: 'Study Suggestions',
              items: analysis.studySuggestions,
              icon: Icons.lightbulb_outline_rounded,
              color: AppColors.primary),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title, content;
  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) return const SizedBox();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
          const SizedBox(height: 6),
          Text(content,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.5)),
        ],
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;
  const _ListSection(
      {required this.title,
      required this.items,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
          const SizedBox(height: 8),
          ...items.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(s,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                height: 1.4))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── Revision Tab ──────────────────────────────────────────────────────────────
class _RevisionTab extends StatelessWidget {
  final TestModel test;
  const _RevisionTab({required this.test});

  @override
  Widget build(BuildContext context) {
    final plan = test.revisionPlan;
    if (plan == null) {
      return const Center(
          child: Text('Revision plan not available',
              style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (plan.highPriority.isNotEmpty)
          _PlanGroup(
              title: '🔴 High Priority',
              items: plan.highPriority,
              color: AppColors.accent),
        if (plan.mediumPriority.isNotEmpty)
          _PlanGroup(
              title: '🟡 Medium Priority',
              items: plan.mediumPriority,
              color: AppColors.accentOrange),
        if (plan.lowPriority.isNotEmpty)
          _PlanGroup(
              title: '🟢 Low Priority',
              items: plan.lowPriority,
              color: AppColors.accentGreen),
        if (plan.studyOrder.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6)
                ]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📋 Recommended Study Order',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                ...plan.studyOrder.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6)),
                          child: Center(
                            child: Text('${e.key + 1}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(e.value,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary)),
                        ),
                      ]),
                    )),
              ],
            ),
          ),
        ],
        if (plan.estimatedHours > 0 || plan.suggestedNextTest.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              if (plan.estimatedHours > 0)
                Row(children: [
                  const Icon(Icons.access_time_outlined,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                      'Estimated revision time: ~${plan.estimatedHours} hours',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ]),
              if (plan.estimatedHours > 0 &&
                  plan.suggestedNextTest.isNotEmpty)
                const SizedBox(height: 8),
              if (plan.suggestedNextTest.isNotEmpty)
                Row(children: [
                  const Icon(Icons.quiz_outlined,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        'Suggested next test: ${plan.suggestedNextTest}',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                ]),
            ]),
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }
}

class _PlanGroup extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;
  const _PlanGroup(
      {required this.title, required this.items, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6)
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: items
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(t,
                            style: TextStyle(
                                fontSize: 12,
                                color: color,
                                fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
            ),
          ],
        ),
      );
}
