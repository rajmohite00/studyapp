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
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              )
            : null,
        title: const Text('Tests',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded,
                color: AppColors.textSecondary, size: 22),
            onPressed: () => context.push('/tests/history'),
            tooltip: 'History',
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
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
              // ── Hero: Start new test ───────────────────────
              GestureDetector(
                onTap: () => context.push('/tests/setup'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start New Test',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('AI-generated questions for any subject',
                              style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      Colors.white.withValues(alpha: 0.8))),
                        ],
                      ),
                    ),
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 28),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 16),

              // ── Continue draft ─────────────────────────────
              draftAsync.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (draft) => draft != null
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _DraftBanner(draft: draft),
                      )
                    : const SizedBox(),
              ),

              // ── Stats row ──────────────────────────────────
              statsAsync.when(
                loading: () => const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: ShimmerStatRow()),
                error: (_, __) => const SizedBox(),
                data: (stats) => stats.totalTests > 0
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _StatsRow(stats: stats),
                      )
                    : const SizedBox(),
              ),

              // ── Recent results ─────────────────────────────
              historyAsync.when(
                loading: () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _SectionLabel('Recent Results'),
                    SizedBox(height: 10),
                    ShimmerCard(height: 68),
                    ShimmerCard(height: 68),
                    ShimmerCard(height: 68),
                  ],
                ),
                error: (_, __) => const SizedBox(),
                data: (tests) {
                  if (tests.isEmpty) return _EmptyView();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const _SectionLabel('Recent Results'),
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
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFFE8E8EE)),
                        ),
                        child: Column(
                          children: tests
                              .take(5)
                              .toList()
                              .asMap()
                              .entries
                              .map((entry) {
                            final isLast =
                                entry.key == tests.take(5).length - 1;
                            return Column(children: [
                              _ResultRow(
                                test: entry.value,
                                onTap: () => context.push(
                                    '/tests/report/${entry.value.id}'),
                              ),
                              if (!isLast)
                                const Divider(
                                    height: 1,
                                    indent: 16,
                                    color: Color(0xFFF0F0F0)),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Draft banner ──────────────────────────────────────────────────────────────
class _DraftBanner extends StatelessWidget {
  final TestModel draft;
  const _DraftBanner({required this.draft});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/tests/active/${draft.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.accentOrange.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.play_circle_outline_rounded,
                color: AppColors.accentOrange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Continue Draft',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  Text(draft.subject,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary)),
                ]),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textLight, size: 18),
        ]),
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final TestStats stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/tests/analytics'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E8EE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Performance',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const Text('Details →',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _StatNum(
                    value: '${stats.totalTests}',
                    label: 'Tests',
                    color: AppColors.primary),
                _Divider(),
                _StatNum(
                    value: '${stats.avgScore}%',
                    label: 'Avg Score',
                    color: const Color(0xFF059669)),
                _Divider(),
                _StatNum(
                    value: '${stats.overallAccuracy}%',
                    label: 'Accuracy',
                    color: const Color(0xFF0284C7)),
                _Divider(),
                _StatNum(
                    value: '${stats.highestScore}%',
                    label: 'Best',
                    color: const Color(0xFFD97706)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatNum extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatNum(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
        ]),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1, height: 32, color: const Color(0xFFF0F0F0));
}

// ── Result Row ────────────────────────────────────────────────────────────────
class _ResultRow extends StatelessWidget {
  final TestModel test;
  final VoidCallback onTap;
  const _ResultRow({required this.test, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = test.percentage >= 70
        ? const Color(0xFF059669)
        : test.percentage >= 50
            ? const Color(0xFFD97706)
            : const Color(0xFFE53E3E);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(test.grade,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
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
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(
                      '${test.correct}/${test.totalQuestions} correct  ·  ${_fmtDate(test.submittedAt)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ]),
          ),
          Text('${test.percentage}%',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: color)),
        ]),
      ),
    );
  }

  static String _fmtDate(DateTime? d) {
    if (d == null) return '';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]}';
  }
}

// ── Empty ─────────────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                  color: const Color(0xFFF0EEFF),
                  borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.quiz_outlined,
                  color: AppColors.primary, size: 30),
            ),
            const SizedBox(height: 14),
            const Text('No tests yet',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            const Text('Tap Start New Test to begin',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ]),
        ),
      );
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary));
}
