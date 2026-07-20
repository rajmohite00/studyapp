import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/test_provider.dart';
import '../models/test_model.dart';
import '../app_theme.dart';
import '../widgets/shimmer_box.dart';

class TestsScreen extends ConsumerWidget {
  const TestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync   = ref.watch(testStatsProvider);
    final historyAsync = ref.watch(testHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text('Tests', style: GoogleFonts.outfit(
            fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.textSecondary),
            onPressed: () => context.push('/tests/history'),
          ),
        ],
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFFF0F0F5))),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(testStatsProvider);
          ref.invalidate(testHistoryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Start New Test CTA ────────────────────────
            _StartTestBanner(),
            const SizedBox(height: 24),

            // ── Performance Overview ──────────────────────
            _SectionHeader('Performance Overview'),
            const SizedBox(height: 12),
            statsAsync.when(
              loading: () => const ShimmerStatRow(),
              error: (_, __) => const SizedBox(),
              data: (stats) => _PerfGrid(stats: stats),
            ),
            const SizedBox(height: 24),

            // ── Weak Topics ───────────────────────────────
            statsAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (stats) => stats.weakTopics.isNotEmpty
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _SectionHeader('Needs Focus'),
                      const SizedBox(height: 12),
                      _NeedsFocusCard(topics: stats.weakTopics),
                      const SizedBox(height: 24),
                    ])
                  : const SizedBox(),
            ),

            // ── Recent History ────────────────────────────
            historyAsync.when(
              loading: () => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _SectionHeader('Recent History'),
                const SizedBox(height: 10),
                const ShimmerCard(height: 70),
                const ShimmerCard(height: 70),
                const ShimmerCard(height: 70),
              ]),
              error: (_, __) => const SizedBox(),
              data: (tests) {
                if (tests.isEmpty) return const SizedBox();
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    _SectionHeader('Recent History'),
                    GestureDetector(
                      onTap: () => context.push('/tests/history'),
                      child: Text('View All', style: GoogleFonts.outfit(fontSize: 13,
                          color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    child: Column(
                      children: tests.take(4).toList().asMap().entries.map((e) {
                        final isLast = e.key == tests.take(4).length - 1;
                        return Column(children: [
                          _HistoryRow(test: e.value,
                              onTap: () => context.push('/tests/report/${e.value.id}')),
                          if (!isLast)
                            const Divider(height: 1, indent: 16, color: Color(0xFFF3F3F7)),
                        ]);
                      }).toList(),
                    ),
                  ),
                ]);
              },
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Start Test Banner ─────────────────────────────────────────────────────────
class _StartTestBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/tests/setup'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.30),
              blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Start New Test', style: GoogleFonts.outfit(fontSize: 20,
                fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 4),
            Text('AI-generated questions for any subject',
                style: GoogleFonts.outfit(fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.80))),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
                Text('Begin Test', style: GoogleFonts.outfit(fontSize: 13,
                    fontWeight: FontWeight.w700, color: AppColors.primary)),
              ]),
            ),
          ])),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.quiz_rounded, color: Colors.white, size: 32),
          ),
        ]),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary));
}

// ── Performance Grid ──────────────────────────────────────────────────────────
class _PerfGrid extends StatelessWidget {
  final TestStats stats;
  const _PerfGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cards = [
      (Icons.bar_chart_rounded,    '${stats.avgScore}%',          'Avg Score',   const Color(0xFF6C4CF1)),
      (Icons.gps_fixed_rounded,    '${stats.overallAccuracy}%',   'Accuracy',    const Color(0xFF10B981)),
      (Icons.quiz_outlined,        '${stats.totalTests}',         'Tests Taken', const Color(0xFF0EA5E9)),
      (Icons.emoji_events_rounded, '${stats.highestScore}%',      'Best Score',  const Color(0xFFF59E0B)),
    ];
    return GridView.count(
      crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
      childAspectRatio: 1.5, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cards.map((c) => _PerfCard(
        icon: c.$1, value: c.$2, label: c.$3, color: c.$4,
      )).toList(),
    );
  }
}

class _PerfCard extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _PerfCard({required this.icon, required this.value,
      required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/tests/analytics'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(value, style: GoogleFonts.outfit(fontSize: 24,
              fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          Text(label, style: GoogleFonts.outfit(fontSize: 11,
              color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}

// ── Needs Focus Card ──────────────────────────────────────────────────────────
class _NeedsFocusCard extends StatelessWidget {
  final List<String> topics;
  const _NeedsFocusCard({required this.topics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE4E4)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 18),
          const SizedBox(width: 8),
          Text('These topics need attention', style: GoogleFonts.outfit(
              fontSize: 13, color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: topics.take(5).map((t) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.25)),
            ),
            child: Text(t, style: GoogleFonts.outfit(fontSize: 12,
                fontWeight: FontWeight.w600, color: const Color(0xFFEF4444))),
          )).toList(),
        ),
      ]),
    );
  }
}

// ── History Row ───────────────────────────────────────────────────────────────
class _HistoryRow extends StatelessWidget {
  final TestModel test;
  final VoidCallback onTap;
  const _HistoryRow({required this.test, required this.onTap});

  Color get _scoreColor => test.percentage >= 70
      ? const Color(0xFF10B981)
      : test.percentage >= 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: _scoreColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(test.grade, style: GoogleFonts.outfit(
                fontSize: 16, fontWeight: FontWeight.w800, color: _scoreColor))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(test.subject, style: GoogleFonts.outfit(fontSize: 13,
                fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${test.totalQuestions} Qs  ·  ${_fmtDate(test.submittedAt)}',
                style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${test.percentage}%', style: GoogleFonts.outfit(
                fontSize: 15, fontWeight: FontWeight.w800, color: _scoreColor)),
            Text('Score', style: GoogleFonts.outfit(fontSize: 10,
                color: AppColors.textSecondary)),
          ]),
        ]),
      ),
    );
  }

  static String _fmtDate(DateTime? d) {
    if (d == null) return '';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month-1]} ${d.day}';
  }
}
