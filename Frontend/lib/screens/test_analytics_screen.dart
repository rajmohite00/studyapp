import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/test_provider.dart';
import '../models/test_model.dart';
import '../app_theme.dart';

class TestAnalyticsScreen extends ConsumerWidget {
  const TestAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(testStatsProvider);

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
        title: const Text('Analytics',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
      ),
      body: statsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) => stats.totalTests == 0
            ? _EmptyAnalytics()
            : _AnalyticsBody(stats: stats),
      ),
    );
  }
}

class _EmptyAnalytics extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.bar_chart_rounded, size: 56, color: AppColors.textLight),
        SizedBox(height: 16),
        Text('No analytics yet',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary)),
        SizedBox(height: 8),
        Text('Complete some tests to see your performance trends.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textLight)),
      ]),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  final TestStats stats;
  const _AnalyticsBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top stats ─────────────────────────────────────
          _SectionHeader(title: 'Overview'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.8,
            children: [
              _OverviewCard(
                  label: 'Total Tests',
                  value: '${stats.totalTests}',
                  icon: Icons.quiz_outlined,
                  color: AppColors.primary),
              _OverviewCard(
                  label: 'Avg Score',
                  value: '${stats.avgScore}%',
                  icon: Icons.bar_chart_rounded,
                  color: AppColors.accentGreen),
              _OverviewCard(
                  label: 'Best Score',
                  value: '${stats.highestScore}%',
                  icon: Icons.emoji_events_outlined,
                  color: AppColors.accentOrange),
              _OverviewCard(
                  label: 'Accuracy',
                  value: '${stats.overallAccuracy}%',
                  icon: Icons.gps_fixed_rounded,
                  color: AppColors.accentPurple),
            ],
          ),
          const SizedBox(height: 20),

          // ── Weekly progress bar chart ─────────────────────
          if (stats.weeklyProgress.isNotEmpty) ...[
            _SectionHeader(title: 'Weekly Progress'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6)
                  ]),
              child: _WeeklyChart(data: stats.weeklyProgress),
            ),
            const SizedBox(height: 20),
          ],

          // ── Subject performance ───────────────────────────
          if (stats.subjectStats.isNotEmpty) ...[
            _SectionHeader(title: 'Subject Performance'),
            const SizedBox(height: 10),
            ...stats.subjectStats.map((s) => _SubjectRow(stat: s)),
            const SizedBox(height: 20),
          ],

          // ── Strong topics ────────────────────────────────
          if (stats.strongTopics.isNotEmpty) ...[
            _SectionHeader(title: '💪 Strong Topics'),
            const SizedBox(height: 10),
            _TopicCloud(topics: stats.strongTopics, color: AppColors.accentGreen),
            const SizedBox(height: 20),
          ],

          // ── Weak topics ───────────────────────────────────
          if (stats.weakTopics.isNotEmpty) ...[
            _SectionHeader(title: '⚠️ Topics to Improve'),
            const SizedBox(height: 10),
            _TopicCloud(topics: stats.weakTopics, color: AppColors.accent),
            const SizedBox(height: 20),
          ],

          // ── Score range ───────────────────────────────────
          _SectionHeader(title: 'Score Range'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6)
                ]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _RangeStat(
                    label: 'Highest',
                    value: '${stats.highestScore}%',
                    color: AppColors.accentGreen),
                Container(
                    width: 1, height: 40, color: AppColors.divider),
                _RangeStat(
                    label: 'Average',
                    value: '${stats.avgScore}%',
                    color: AppColors.primary),
                Container(
                    width: 1, height: 40, color: AppColors.divider),
                _RangeStat(
                    label: 'Lowest',
                    value: '${stats.lowestScore}%',
                    color: Colors.red.shade400),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary));
}

class _OverviewCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _OverviewCard(
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
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
          ]),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
        ]),
      ]),
    );
  }
}

// ── Weekly bar chart (simple, no external dep) ─────────────────────────────────
class _WeeklyChart extends StatelessWidget {
  final List<WeeklyProgress> data;
  const _WeeklyChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final last8 = data.length > 8 ? data.sublist(data.length - 8) : data;
    final maxScore =
        last8.fold<int>(0, (m, w) => w.avgScore > m ? w.avgScore : m);
    final scale = maxScore > 0 ? maxScore.toDouble() : 100.0;

    return Column(
      children: [
        SizedBox(
          height: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: last8.map((w) {
              final h = w.count > 0 ? (w.avgScore / scale) * 80 : 4.0;
              final clr = w.avgScore >= 70
                  ? AppColors.accentGreen
                  : w.avgScore >= 50
                      ? AppColors.primary
                      : AppColors.accent;
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (w.count > 0)
                      Text('${w.avgScore}',
                          style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Container(
                      height: h.clamp(4.0, 80.0),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: w.count > 0 ? clr : AppColors.divider,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: last8
              .map((w) => Expanded(
                    child: Text(w.week,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _SubjectRow extends StatelessWidget {
  final SubjectStat stat;
  const _SubjectRow({required this.stat});

  @override
  Widget build(BuildContext context) {
    final clr = stat.avgScore >= 70
        ? AppColors.accentGreen
        : stat.avgScore >= 50
            ? AppColors.primary
            : AppColors.accent;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
          ]),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Text(stat.subject,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ),
          Text('${stat.count} test${stat.count != 1 ? 's' : ''}',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(width: 12),
          Text('${stat.avgScore}%',
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 14, color: clr)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: stat.avgScore / 100,
            backgroundColor: clr.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(clr),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 2),
        Align(
          alignment: Alignment.centerRight,
          child: Text('Best: ${stat.bestScore}%',
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
        ),
      ]),
    );
  }
}

class _TopicCloud extends StatelessWidget {
  final List<String> topics;
  final Color color;
  const _TopicCloud({required this.topics, required this.color});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: topics
          .map((t) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(t,
                    style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600)),
              ))
          .toList(),
    );
  }
}

class _RangeStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _RangeStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ]);
}
