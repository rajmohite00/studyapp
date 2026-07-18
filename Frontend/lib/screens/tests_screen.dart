import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/test_provider.dart';
import '../models/test_model.dart';
import '../app_theme.dart';
import '../widgets/shimmer_box.dart';

class TestsScreen extends ConsumerWidget {
  const TestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(testStatsProvider);
    final historyAsync = ref.watch(testHistoryProvider);
    final draftAsync = ref.watch(activeDraftProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              )
            : null,
        title: const Text('Tests',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFEEEEEE)),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(testStatsProvider);
          ref.invalidate(testHistoryProvider);
          ref.invalidate(activeDraftProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Start new test button ──────────────────────
              _StartButton(onTap: () => context.push('/tests/setup')),
              const SizedBox(height: 16),

              // ── Continue draft ─────────────────────────────
              draftAsync.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (draft) => draft != null
                    ? _ContinueDraftCard(draft: draft)
                    : const SizedBox(),
              ),

              // ── Stats summary ──────────────────────────────
              statsAsync.when(
                loading: () => const _StatsShimmer(),
                error: (_, __) => const SizedBox(),
                data: (stats) => stats.totalTests > 0
                    ? _StatsSummary(stats: stats)
                    : const SizedBox(),
              ),

              // ── Recent results ─────────────────────────────
              historyAsync.when(
                loading: () => const _HistoryShimmer(),
                error: (_, __) => const SizedBox(),
                data: (tests) {
                  if (tests.isEmpty) return _EmptyState();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recent Results',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                          GestureDetector(
                            onTap: () => context.push('/tests/history'),
                            child: const Text('View All',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...tests.take(5).map((t) => _TestHistoryCard(
                            test: t,
                            onTap: () =>
                                context.push('/tests/report/${t.id}'),
                          )),
                    ],
                  );
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Start Button ──────────────────────────────────────────────────────────────
class _StartButton extends StatelessWidget {
  final VoidCallback onTap;
  const _StartButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start New Test',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text('AI-generated questions for any subject',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
          ],
        ),
      ),
    );
  }
}

// ── Continue Draft ────────────────────────────────────────────────────────────
class _ContinueDraftCard extends StatelessWidget {
  final TestModel draft;
  const _ContinueDraftCard({required this.draft});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/tests/active/${draft.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.play_circle_outline_rounded,
                  color: AppColors.accentOrange, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Continue Draft Test',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  Text(draft.subject,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textLight, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Stats Summary ─────────────────────────────────────────────────────────────
class _StatsSummary extends StatelessWidget {
  final TestStats stats;
  const _StatsSummary({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Performance Summary',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            GestureDetector(
              onTap: () => context.push('/tests/analytics'),
              child: const Text('Details',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    label: 'Tests',
                    value: '${stats.totalTests}',
                    icon: Icons.quiz_outlined,
                    color: AppColors.primary)),
            const SizedBox(width: 10),
            Expanded(
                child: _StatCard(
                    label: 'Avg Score',
                    value: '${stats.avgScore}%',
                    icon: Icons.bar_chart_rounded,
                    color: AppColors.accentGreen)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    label: 'Best Score',
                    value: '${stats.highestScore}%',
                    icon: Icons.emoji_events_outlined,
                    color: AppColors.accentOrange)),
            const SizedBox(width: 10),
            Expanded(
                child: _StatCard(
                    label: 'Accuracy',
                    value: '${stats.overallAccuracy}%',
                    icon: Icons.gps_fixed_rounded,
                    color: AppColors.accentPurple)),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Test History Card ─────────────────────────────────────────────────────────
class _TestHistoryCard extends StatelessWidget {
  final TestModel test;
  final VoidCallback onTap;
  const _TestHistoryCard({required this.test, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = test.percentage >= 70
        ? AppColors.accentGreen
        : test.percentage >= 50
            ? AppColors.accentOrange
            : Colors.red.shade400;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(test.grade,
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: color)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(test.subject,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                      '${test.correct}/${test.totalQuestions} correct  ·  ${_fmt(test.submittedAt)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text('${test.percentage}%',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: color)),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime? d) {
    if (d == null) return '';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]}';
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.quiz_outlined,
                  color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('No tests yet',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('Start a test above to begin practising',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer placeholders ──────────────────────────────────────────────────────
class _StatsShimmer extends StatelessWidget {
  const _StatsShimmer();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: ShimmerStatRow(),
      );
}

class _HistoryShimmer extends StatelessWidget {
  const _HistoryShimmer();
  @override
  Widget build(BuildContext context) => Column(children: const [
        ShimmerCard(height: 72),
        ShimmerCard(height: 72),
        ShimmerCard(height: 72),
      ]);
}
