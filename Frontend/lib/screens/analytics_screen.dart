import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/analytics_provider.dart';
import '../providers/session_provider.dart';
import '../providers/intelligence_provider.dart';
import '../widgets/donut_chart.dart';
import '../widgets/heatmap_widget.dart';
import '../app_theme.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardProvider);
    final heatmapAsync = ref.watch(heatmapProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
            onPressed: () => context.push('/analytics/weekly-report'),
            tooltip: 'Weekly Report',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(dashboardProvider);
          ref.invalidate(heatmapProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Stat cards ───────────────────────────
              dashAsync.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (data) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'This Week',
                            value: '${data.week.totalMinutes ~/ 60}h ${data.week.totalMinutes % 60}m',
                            subtitle: 'Total Studied',
                            icon: Icons.schedule_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _StatCard(
                            title: 'Avg Focus',
                            value: '${data.week.avgFocusScore}',
                            subtitle: 'Score (0–100)',
                            icon: Icons.bolt_rounded,
                            color: AppColors.accentGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Subject Breakdown ──────────────
                    _SectionHeader(title: 'Subject Breakdown', icon: Icons.donut_large_rounded),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: DonutChart(data: data.today.subjectBreakdown),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Heatmap ──────────────────────────────
              _SectionHeader(title: 'Study Heatmap', icon: Icons.grid_on_rounded),
              const SizedBox(height: 14),
              heatmapAsync.when(
                loading: () => const SizedBox(height: 140, child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (data) => Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: HeatmapWidget(data: data),
                ),
              ),
              const SizedBox(height: 28),

              // ── Intelligence insights ─────────────────
              _SectionHeader(title: 'Intelligence Insights', icon: Icons.psychology_rounded),
              const SizedBox(height: 14),
              _PerformanceAndInsightsWidget(),
              const SizedBox(height: 28),

              // ── Recent sessions ───────────────────────
              _SectionHeader(title: 'Recent Sessions', icon: Icons.history_rounded),
              const SizedBox(height: 14),
              _SessionHistoryWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.3)),
        ],
      );
}

class _SessionHistoryWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(sessionHistoryProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (sessions) {
        if (sessions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Center(
              child: Text(
                'No sessions yet.\nStart studying to see your history!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
              ),
            ),
          );
        }
        return Column(
          children: sessions.take(5).map((s) {
            final h = s.actualDurationMinutes ~/ 60;
            final m = s.actualDurationMinutes % 60;
            final timeStr = h > 0 ? '${h}h ${m}m' : '${m}m';
            final isCompleted = s.status == 'completed';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.subject, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isCompleted ? AppColors.accentGreen : AppColors.accentOrange).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            s.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isCompleted ? AppColors.accentGreen : AppColors.accentOrange,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(timeStr, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Focus ${s.focusScore}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _PerformanceAndInsightsWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfAsync = ref.watch(performanceProvider);
    final insightsAsync = ref.watch(insightsProvider);

    return Column(
      children: [
        perfAsync.when(
          loading: () => const LinearProgressIndicator(color: AppColors.primary, backgroundColor: AppColors.divider),
          error: (_, __) => const SizedBox(),
          data: (data) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.star_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Overall: ${data['rating']} (${data['score']}%)', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13)),
                      const SizedBox(height: 3),
                      Text(data['suggestion'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        insightsAsync.when(
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
          data: (data) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: AppColors.accentOrange.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.psychology_rounded, color: AppColors.accentOrange, size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text('Study Pattern', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.accentOrange, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(data['insight'], style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value, subtitle;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 14),
                ),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
          ],
        ),
      );
}
