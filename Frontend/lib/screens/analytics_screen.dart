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
      body: SafeArea(
        child: Column(
          children: [
            // ── APP BAR ──────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Analytics', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5)),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.textPrimary, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary, size: 18),
                    ),
                    onPressed: () => context.push('/analytics/weekly-report'),
                    tooltip: 'Weekly Report',
                  ),
                ],
              ),
            ),
            Container(height: 1.5, color: AppColors.divider),

            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(dashboardProvider);
                  ref.invalidate(heatmapProvider);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── STAT CARDS GRID ───────────────────────
                      dashAsync.when(
                        loading: () => const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))),
                        error: (e, _) => Center(child: Text('Error: $e')),
                        data: (data) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stats 2x2 grid (Sponsors-style)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                              child: GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.35,
                                children: [
                                  _StatCard(icon: Icons.schedule_rounded, title: 'This Week', value: '${data.week.totalMinutes ~/ 60}h ${data.week.totalMinutes % 60}m', subtitle: 'Total studied', color: AppColors.primary),
                                  _StatCard(icon: Icons.bolt_rounded, title: 'Avg Focus', value: '${data.week.avgFocusScore}', subtitle: 'Score out of 100', color: AppColors.accentGreen),
                                  _StatCard(icon: Icons.local_fire_department_rounded, title: 'Streak', value: '${data.streak.current}d', subtitle: 'Current streak', color: AppColors.accentOrange),
                                  _StatCard(icon: Icons.check_circle_rounded, title: 'Sessions', value: '${data.week.sessionCount}', subtitle: 'This week', color: AppColors.accent),
                                ],
                              ),
                            ),

                            // Subject Donut
                            _BoldSection(title: 'Subject Breakdown', icon: Icons.donut_large_rounded),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.textPrimary, width: 2),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 0, offset: const Offset(4, 4))],
                                ),
                                child: DonutChart(data: data.today.subjectBreakdown),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── HEATMAP ───────────────────────────────
                      _BoldSection(title: 'Study Heatmap', icon: Icons.grid_on_rounded),
                      heatmapAsync.when(
                        loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))),
                        error: (e, _) => Center(child: Text('Error: $e')),
                        data: (data) => Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.textPrimary, width: 2),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 0, offset: const Offset(4, 4))],
                            ),
                            child: HeatmapWidget(data: data),
                          ),
                        ),
                      ),

                      // ── INTELLIGENCE ──────────────────────────
                      _BoldSection(title: 'Intelligence', icon: Icons.psychology_rounded),
                      _PerformanceWidget(),

                      // ── RECENT SESSIONS ───────────────────────
                      _BoldSection(title: 'Recent Sessions', icon: Icons.history_rounded),
                      _SessionHistoryWidget(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoldSection extends StatelessWidget {
  final String title;
  final IconData icon;
  const _BoldSection({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.3)),
          ],
        ),
      );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title, value, subtitle;
  final Color color;
  const _StatCard({required this.icon, required this.title, required this.value, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textPrimary, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 0, offset: const Offset(3, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
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
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider, width: 1.5),
              ),
              child: const Center(child: Text('No sessions yet.\nStart studying to see your history!', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5))),
            ),
          );
        }
        return Column(
          children: sessions.take(5).map((s) {
            final h = s.actualDurationMinutes ~/ 60;
            final m = s.actualDurationMinutes % 60;
            final timeStr = h > 0 ? '${h}h ${m}m' : '${m}m';
            final isCompleted = s.status == 'completed';
            final statusColor = isCompleted ? AppColors.accentGreen : AppColors.accentOrange;
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.textPrimary, width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 0, offset: const Offset(3, 3))],
              ),
              child: Row(
                children: [
                  // Circular avatar (Mentorship-card style)
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.subject, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
                        const SizedBox(height: 3),
                        Text(
                          s.status.toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: 0.8),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(timeStr, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 15)),
                      const SizedBox(height: 3),
                      Text('Focus ${s.focusScore}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
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

class _PerformanceWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfAsync = ref.watch(performanceProvider);
    final insightsAsync = ref.watch(insightsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          perfAsync.when(
            loading: () => const LinearProgressIndicator(color: AppColors.primary, backgroundColor: AppColors.divider),
            error: (_, __) => const SizedBox(),
            data: (data) {
              final d = data as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
                      ),
                      child: const Icon(Icons.star_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Overall: ${d['rating']} (${d['score']}%)', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 14)),
                          const SizedBox(height: 3),
                          Text(d['suggestion'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          insightsAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (data) {
              final d = data as Map<String, dynamic>;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentOrange.withOpacity(0.4), width: 1.5),
                  boxShadow: [BoxShadow(color: AppColors.accentOrange.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accentOrange.withOpacity(0.3), width: 2),
                      ),
                      child: const Icon(Icons.psychology_rounded, color: AppColors.accentOrange, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Study Pattern', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.accentOrange, fontSize: 14)),
                          const SizedBox(height: 3),
                          Text(d['insight'], style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
