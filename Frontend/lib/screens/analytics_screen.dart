import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/analytics_provider.dart';
import '../providers/session_provider.dart';
import '../providers/intelligence_provider.dart';
import '../widgets/donut_chart.dart';
import '../widgets/heatmap_widget.dart';
import '../widgets/animations.dart';
import '../app_theme.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardProvider);
    final heatmapAsync = ref.watch(heatmapProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── APP BAR ──────────────────────────────────
            Container(
              color: AppColors.background,
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analytics',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -1.0,
                        ),
                      ),
                      Text(
                        'Track your learning progress',
                        style: GoogleFonts.outfit(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  PressButton(
                    scaleDown: 0.92,
                    onTap: () => context.push('/analytics/weekly-report'),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(dashboardProvider);
                  ref.invalidate(heatmapProvider);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // ── STAT CARDS GRID ───────────────────────
                      dashAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5)),
                        ),
                        error: (e, _) => Center(child: Text('Error: $e')),
                        data: (data) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stats 2x2 grid with gradient cards
                            StaggeredList(
                              itemDelay: const Duration(milliseconds: 70),
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _GradientStatCard(
                                        icon: Icons.schedule_rounded,
                                        value: '${data.week.totalMinutes ~/ 60}h ${data.week.totalMinutes % 60}m',
                                        subtitle: 'Total studied',
                                        gradient: AppColors.heroGradient,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _GradientStatCard(
                                        icon: Icons.bolt_rounded,
                                        value: '${data.week.avgFocusScore}',
                                        subtitle: 'Focus score',
                                        gradient: AppColors.cardGradientGreen,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _GradientStatCard(
                                        icon: Icons.local_fire_department_rounded,
                                        value: '${data.streak.current}d',
                                        subtitle: 'Current streak',
                                        gradient: AppColors.cardGradientOrange,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _GradientStatCard(
                                        icon: Icons.check_circle_rounded,
                                        value: '${data.week.sessionCount}',
                                        subtitle: 'Sessions this week',
                                        gradient: AppColors.cardGradientPink,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),

                            // Subject Donut
                            _SectionHeader(title: 'Subject Breakdown', icon: Icons.donut_large_rounded),
                            const SizedBox(height: 14),
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 100),
                              child: _WhiteCard(
                                child: DonutChart(data: data.today.subjectBreakdown),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── HEATMAP ───────────────────────────────
                      _SectionHeader(title: 'Study Heatmap', icon: Icons.grid_on_rounded),
                      const SizedBox(height: 14),
                      heatmapAsync.when(
                        loading: () => const SizedBox(
                          height: 120,
                          child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5)),
                        ),
                        error: (e, _) => Center(child: Text('Error: $e')),
                        data: (data) => FadeSlideIn(
                          delay: const Duration(milliseconds: 150),
                          child: _WhiteCard(child: HeatmapWidget(data: data)),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── INTELLIGENCE ──────────────────────────
                      _SectionHeader(title: 'AI Intelligence', icon: Icons.psychology_rounded),
                      const SizedBox(height: 14),
                      _PerformanceWidget(),

                      const SizedBox(height: 28),

                      // ── RECENT SESSIONS ───────────────────────
                      _SectionHeader(title: 'Recent Sessions', icon: Icons.history_rounded),
                      const SizedBox(height: 14),
                      _SessionHistoryWidget(),

                      const SizedBox(height: 32),
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

// ── Gradient Stat Card ─────────────────────────────────────────────────────────
class _GradientStatCard extends StatelessWidget {
  final IconData icon;
  final String value, subtitle;
  final Gradient gradient;
  const _GradientStatCard({
    required this.icon,
    required this.value,
    required this.subtitle,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (gradient as LinearGradient).colors.first.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
}

// ── Section Header ──────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      );
}

// ── White Card ─────────────────────────────────────────────────────────────────
class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      );
}

// ── Session History ─────────────────────────────────────────────────────────────
class _SessionHistoryWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(sessionHistoryProvider);
    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (sessions) {
        if (sessions.isEmpty) {
          return _WhiteCard(
            child: Center(
              child: Column(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.history_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sessions yet',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Start studying to see your history!',
                    style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          children: sessions.take(5).toList().asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final h = s.actualDurationMinutes ~/ 60;
            final m = s.actualDurationMinutes % 60;
            final timeStr = h > 0 ? '${h}h ${m}m' : '${m}m';
            final isCompleted = s.status == 'completed';
            final statusGradient = isCompleted ? AppColors.cardGradientGreen : AppColors.cardGradientOrange;
            return FadeSlideIn(
              delay: Duration(milliseconds: 50 * i),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.subject, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: statusGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              s.status.toUpperCase(),
                              style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => AppColors.heroGradient.createShader(bounds),
                          child: Text(timeStr, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)),
                        ),
                        const SizedBox(height: 3),
                        Text('Focus ${s.focusScore}', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ── Performance Widget ─────────────────────────────────────────────────────────
class _PerformanceWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfAsync = ref.watch(performanceProvider);
    final insightsAsync = ref.watch(insightsProvider);
    return Column(
      children: [
        perfAsync.when(
          loading: () => const LinearProgressIndicator(color: AppColors.primary, backgroundColor: AppColors.divider),
          error: (_, __) => const SizedBox(),
          data: (data) {
            final d = data as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.star_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall: ${d['rating']} (${d['score']}%)',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          d['suggestion'],
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.white.withOpacity(0.85), height: 1.4),
                        ),
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
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradientOrange,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentOrange.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Study Pattern', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(d['insight'], style: GoogleFonts.outfit(fontSize: 12, color: Colors.white.withOpacity(0.85), height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
