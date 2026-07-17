import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/test_provider.dart';
import '../models/test_model.dart';
import '../app_theme.dart';

class TestResultsScreen extends ConsumerStatefulWidget {
  final String testId;
  const TestResultsScreen({super.key, required this.testId});

  @override
  ConsumerState<TestResultsScreen> createState() =>
      _TestResultsScreenState();
}

class _TestResultsScreenState extends ConsumerState<TestResultsScreen> {
  late Future<TestModel> _testFuture;

  @override
  void initState() {
    super.initState();
    _testFuture =
        ref.read(testServiceProvider).getTest(widget.testId);
    // Kick off AI analysis in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analysisProvider.notifier).analyse(widget.testId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<TestModel>(
        future: _testFuture,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary));
          }
          if (snap.hasError || snap.data == null) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Failed to load results'),
                const SizedBox(height: 12),
                ElevatedButton(
                    onPressed: () => context.go('/tests'),
                    child: const Text('Go Back')),
              ]),
            );
          }
          return _ResultsBody(test: snap.data!);
        },
      ),
    );
  }
}

class _ResultsBody extends ConsumerWidget {
  final TestModel test;
  const _ResultsBody({required this.test});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisState = ref.watch(analysisProvider);
    final gradeColor = _gradeColor(test.percentage);

    return CustomScrollView(
      slivers: [
        // ── Header ─────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: gradeColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: Colors.white),
            onPressed: () => context.canPop() ? context.pop() : context.go('/tests'),
          ),
          actions: [
            TextButton.icon(
              onPressed: () =>
                  context.push('/tests/report/${test.id}'),
              icon: const Icon(Icons.description_outlined,
                  color: Colors.white, size: 18),
              label: const Text('Full Report',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: gradeColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  Text(test.grade,
                      style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                  Text('${test.percentage}%',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      test.passed ? '✓ PASSED' : '✗ FAILED',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Score breakdown ───────────────────────────────
              Text(test.subject,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(
                  '${test.difficulty[0].toUpperCase()}${test.difficulty.substring(1)} · ${test.questionCount} questions',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 20),

              _ScoreGrid(test: test),
              const SizedBox(height: 20),

              // ── Time stats ────────────────────────────────────
              _InfoCard(
                title: 'Time Statistics',
                icon: Icons.timer_outlined,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _TimeStat(
                        label: 'Total Time',
                        value: _fmtTime(test.timeSpentSecs)),
                    _TimeStat(
                        label: 'Avg / Q',
                        value: '${test.avgTimePerQuestion}s'),
                    _TimeStat(
                        label: 'Accuracy',
                        value: '${test.accuracy}%'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── AI Analysis ───────────────────────────────────
              _AnalysisSection(analysisState: analysisState),
              const SizedBox(height: 16),

              // ── Revision Plan ─────────────────────────────────
              if (analysisState.test?.revisionPlan != null)
                _RevisionPlanCard(
                    plan: analysisState.test!.revisionPlan!),
              const SizedBox(height: 20),

              // ── Action buttons ────────────────────────────────
              _ActionButtons(test: test),
              const SizedBox(height: 40),
            ]),
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

  String _fmtTime(int secs) {
    if (secs < 60) return '${secs}s';
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m}m ${s}s';
  }
}

// ── Score Grid ────────────────────────────────────────────────────────────────
class _ScoreGrid extends StatelessWidget {
  final TestModel test;
  const _ScoreGrid({required this.test});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Total', '${test.totalQuestions}', AppColors.primary),
      ('Attempted', '${test.attempted}', AppColors.accentBlue),
      ('Correct', '${test.correct}', AppColors.accentGreen),
      ('Wrong', '${test.wrong}', AppColors.accent),
      ('Skipped', '${test.skipped}', AppColors.accentOrange),
      ('Marks', '${test.marks}', AppColors.accentPurple),
    ];
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: items
          .map((item) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6)
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.$2,
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: item.$3)),
                    Text(item.$1,
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _TimeStat extends StatelessWidget {
  final String label, value;
  const _TimeStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ]);
}

// ── AI Analysis Section ───────────────────────────────────────────────────────
class _AnalysisSection extends StatelessWidget {
  final AnalysisState analysisState;
  const _AnalysisSection({required this.analysisState});

  @override
  Widget build(BuildContext context) {
    if (analysisState.isLoading) {
      return _InfoCard(
        title: 'AI Performance Analysis',
        icon: Icons.auto_awesome_outlined,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary)),
              SizedBox(width: 12),
              Text('Generating your personalised analysis...',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    final analysis = analysisState.test?.aiAnalysis;
    if (analysis == null) return const SizedBox();

    return Column(
      children: [
        _InfoCard(
          title: 'AI Performance Analysis',
          icon: Icons.auto_awesome_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (analysis.motivationMessage.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(analysis.motivationMessage,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic)),
                ),
                const SizedBox(height: 12),
              ],
              if (analysis.overallPerformance.isNotEmpty)
                _AnalysisRow(
                    label: 'Overall',
                    value: analysis.overallPerformance),
              if (analysis.estimatedLevel.isNotEmpty)
                _AnalysisRow(
                    label: 'Level',
                    value: analysis.estimatedLevel),
              if (analysis.strongTopics.isNotEmpty) ...[
                const SizedBox(height: 10),
                _TopicChips(
                    title: '💪 Strong Topics',
                    topics: analysis.strongTopics,
                    color: AppColors.accentGreen),
              ],
              if (analysis.weakTopics.isNotEmpty) ...[
                const SizedBox(height: 10),
                _TopicChips(
                    title: '⚠️ Weak Topics',
                    topics: analysis.weakTopics,
                    color: AppColors.accent),
              ],
              if (analysis.personalizedFeedback.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Feedback',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(analysis.personalizedFeedback,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.5)),
              ],
              if (analysis.studySuggestions.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Study Suggestions',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                ...analysis.studySuggestions.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold)),
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
            ],
          ),
        ),
      ],
    );
  }
}

class _AnalysisRow extends StatelessWidget {
  final String label, value;
  const _AnalysisRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 70,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary)),
            ),
            Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textPrimary, height: 1.4))),
          ],
        ),
      );
}

class _TopicChips extends StatelessWidget {
  final String title;
  final List<String> topics;
  final Color color;
  const _TopicChips(
      {required this.title, required this.topics, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: topics
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: color.withValues(alpha: 0.3)),
                      ),
                      child: Text(t,
                          style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ],
      );
}

// ── Revision Plan ─────────────────────────────────────────────────────────────
class _RevisionPlanCard extends StatelessWidget {
  final RevisionPlan plan;
  const _RevisionPlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'AI Revision Plan',
      icon: Icons.menu_book_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plan.highPriority.isNotEmpty)
            _PriorityRow(
                label: '🔴 High Priority',
                items: plan.highPriority,
                color: AppColors.accent),
          if (plan.mediumPriority.isNotEmpty)
            _PriorityRow(
                label: '🟡 Medium Priority',
                items: plan.mediumPriority,
                color: AppColors.accentOrange),
          if (plan.lowPriority.isNotEmpty)
            _PriorityRow(
                label: '🟢 Low Priority',
                items: plan.lowPriority,
                color: AppColors.accentGreen),
          if (plan.estimatedHours > 0) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.access_time_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('Estimated revision: ~${plan.estimatedHours}h',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ],
          if (plan.suggestedNextTest.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Next: ${plan.suggestedNextTest}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

class _PriorityRow extends StatelessWidget {
  final String label;
  final List<String> items;
  final Color color;
  const _PriorityRow(
      {required this.label, required this.items, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            ...items.map((t) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 2),
                  child: Row(children: [
                    Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(t,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary))),
                  ]),
                )),
          ],
        ),
      );
}

// ── Action buttons ────────────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  final TestModel test;
  const _ActionButtons({required this.test});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => context.push('/tests/report/${test.id}'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined,
                    color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('View Detailed Report',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => context.push('/tests/setup'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.replay_rounded,
                    color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Text('Take Another Test',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared Info Card ──────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _InfoCard(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
