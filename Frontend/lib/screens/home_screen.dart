import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../providers/auth_provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/intelligence_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/streak_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _navIndex = 0;

  final _pages = const [_HomePage(), _StudyPlaceholder(), _AnalyticsPlaceholder(), _AiPlaceholder(), _ProfilePlaceholder()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_navIndex],
      bottomNavigationBar: BottomNavBar(currentIndex: _navIndex, onTap: (i) {
        if (i == 1) { context.push('/session/setup'); return; }
        if (i == 2) { context.push('/analytics'); return; }
        if (i == 3) { context.push('/ai/chat'); return; }
        if (i == 4) { context.push('/profile'); return; }
        setState(() => _navIndex = i);
      }),
    );
  }
}

class _HomePage extends ConsumerWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final dashAsync = ref.watch(dashboardProvider);

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.refresh(dashboardProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good ${_greeting()} 👋',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.name.split(' ').first ?? 'Student',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withOpacity(0.08),
                        child: Text(
                          user?.name.substring(0, 1).toUpperCase() ?? 'S',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Hero Section ───────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Badge pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        '✦  YOUR STUDY COMPANION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Study Coach',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        height: 1.1,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Focus, plan, and execute.\nCrush your next exam.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Primary CTA
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push('/session/setup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 17),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Start Study Session  →',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Secondary CTA
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/exam-planner'),
                        icon: const Icon(Icons.menu_book_rounded, size: 17),
                        label: const Text('Plan Your Exam'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: const BorderSide(color: AppColors.divider, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Dynamic content ────────────────────────────────
              dashAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                  ),
                ),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Unable to load data: $e', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ),
                data: (data) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section: Progress
                    _SectionHeader(title: 'Your Progress', icon: Icons.trending_up_rounded),
                    const SizedBox(height: 14),
                    _GoalCard(
                      studied: data.today.totalMinutes,
                      goal: data.dailyGoalMinutes,
                      sessions: data.today.sessionCount,
                    ),
                    const SizedBox(height: 14),
                    StreakCard(
                      currentStreak: data.streak.current,
                      longestStreak: data.streak.longest,
                      freezesAvailable: data.streak.freezesAvailable,
                      nextMilestone: data.streak.nextMilestone,
                    ),
                    const SizedBox(height: 32),

                    // Section: Quick Links
                    _SectionHeader(title: 'Quick Links', icon: Icons.grid_view_rounded),
                    const SizedBox(height: 14),
                    _QuickActions(),
                    const SizedBox(height: 32),

                    // Section: AI Insights
                    _AiSuggestionsWidget(),
                    const SizedBox(height: 16),
                    _SmartInsightsWidget(),
                    const SizedBox(height: 32),

                    // Section: Today's Subjects
                    if (data.today.subjectBreakdown.isNotEmpty)
                      _TodaySubjects(breakdown: data.today.subjectBreakdown),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      );
}

// ── Smart Insights ─────────────────────────────────────────────────────────────
class _SmartInsightsWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final burnoutAsync = ref.watch(burnoutProvider);
    final predictionAsync = ref.watch(predictionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Smart Insights', icon: Icons.psychology_rounded),
        const SizedBox(height: 14),
        burnoutAsync.when(
          loading: () => const LinearProgressIndicator(color: AppColors.primary, backgroundColor: AppColors.divider),
          error: (_, __) => const SizedBox(),
          data: (data) {
            final status = data['status'];
            final isHighRisk = status == 'High Risk';
            final isWarning = status == 'Warning';
            final color = isHighRisk
                ? const Color(0xFFE07A5F)
                : (isWarning ? AppColors.accentOrange : AppColors.accentGreen);

            return _InsightCard(
              icon: isHighRisk ? Icons.local_fire_department_rounded : Icons.health_and_safety_rounded,
              color: color,
              title: 'Burnout: $status',
              subtitle: data['suggestion'],
            );
          },
        ),
        const SizedBox(height: 10),
        predictionAsync.when(
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
          data: (data) => _InsightCard(
            icon: Icons.analytics_rounded,
            color: AppColors.primary,
            title: 'Predicted Score: ${data['predictedScore']}%',
            subtitle: data['suggestion'],
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _InsightCard({required this.icon, required this.color, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 13)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── AI Suggestions ─────────────────────────────────────────────────────────────
class _AiSuggestionsWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSugg = ref.watch(suggestionsProvider);

    return asyncSugg.when(
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
      data: (suggestions) {
        if (suggestions.isEmpty) return const SizedBox();
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.accentBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accentBlue.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.tips_and_updates_rounded, color: AppColors.accentBlue, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text('AI Suggestions', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.accentBlue, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              ...suggestions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.bold)),
                    Expanded(child: Text(s, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4))),
                  ],
                ),
              )),
            ],
          ),
        );
      },
    );
  }
}

// ── Goal Card ──────────────────────────────────────────────────────────────────
class _GoalCard extends StatelessWidget {
  final int studied;
  final int goal;
  final int sessions;
  const _GoalCard({required this.studied, required this.goal, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final pct = (studied / goal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 50,
            lineWidth: 9,
            percent: pct,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(pct * 100).toInt()}%',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ],
            ),
            progressColor: AppColors.primary,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Goal', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  '${studied}m / ${goal}m',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$sessions session${sessions != 1 ? 's' : ''} done',
                        style: const TextStyle(color: AppColors.accentGreen, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Actions ──────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.smart_toy_rounded,
            label: 'AI Coach',
            subtitle: 'Ask anything',
            color: AppColors.accentBlue,
            onTap: () => context.push('/ai/chat'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _ActionCard(
            icon: Icons.bar_chart_rounded,
            label: 'Analytics',
            subtitle: 'Your stats',
            color: AppColors.accentGreen,
            onTap: () => context.push('/analytics'),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
}

// ── Today's Subjects ───────────────────────────────────────────────────────────
class _TodaySubjects extends StatelessWidget {
  final Map<String, int> breakdown;
  const _TodaySubjects({required this.breakdown});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: "Today's Subjects", icon: Icons.auto_stories_rounded),
          const SizedBox(height: 14),
          ...breakdown.entries.map((e) {
            final h = e.value ~/ 60;
            final m = e.value % 60;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                  Text(
                    h > 0 ? '${h}h ${m}m' : '${m}m',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ),
            );
          }),
        ],
      );
}

// ── Placeholder pages ──────────────────────────────────────────────────────────
class _StudyPlaceholder extends StatelessWidget {
  const _StudyPlaceholder();
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _AnalyticsPlaceholder extends StatelessWidget {
  const _AnalyticsPlaceholder();
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _AiPlaceholder extends StatelessWidget {
  const _AiPlaceholder();
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();
  @override
  Widget build(BuildContext context) => const SizedBox();
}
