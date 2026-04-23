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
        onRefresh: () => ref.refresh(dashboardProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Good ${_greeting()} 👋', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(user?.name.split(' ').first ?? 'Student',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      if (user != null) ...[
                        const SizedBox(height: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                  const SizedBox(width: 4),
                                  Text('Lvl ${user.gamification.level} ${user.gamification.rank} • ${user.gamification.xp} XP', 
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.amber)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 150,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (user.gamification.xp % 1000) / 1000,
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                                  minHeight: 4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text('${1000 - (user.gamification.xp % 1000)} XP to next level', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(user?.name.substring(0, 1).toUpperCase() ?? 'S',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              dashAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('$e'),
                data: (data) => Column(
                  children: [
                    // Today goal ring
                    _GoalCard(
                      studied: data.today.totalMinutes,
                      goal: data.dailyGoalMinutes,
                      sessions: data.today.sessionCount,
                    ),
                    const SizedBox(height: 20),
                    StreakCard(
                      currentStreak: data.streak.current,
                      longestStreak: data.streak.longest,
                      freezesAvailable: data.streak.freezesAvailable,
                      nextMilestone: data.streak.nextMilestone,
                    ),
                    const SizedBox(height: 20),
                    _QuickActions(),
                    const SizedBox(height: 20),
                    _AiSuggestionsWidget(),
                    const SizedBox(height: 20),
                    _SmartInsightsWidget(),
                    const SizedBox(height: 20),
                    if (data.today.subjectBreakdown.isNotEmpty) _TodaySubjects(breakdown: data.today.subjectBreakdown),
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

class _SmartInsightsWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final burnoutAsync = ref.watch(burnoutProvider);
    final predictionAsync = ref.watch(predictionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Smart Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        burnoutAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox(),
          data: (data) {
            final status = data['status'];
            final isHighRisk = status == 'High Risk';
            final isWarning = status == 'Warning';
            final color = isHighRisk ? Colors.red : (isWarning ? AppColors.accentOrange : AppColors.accentGreen);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(isHighRisk ? Icons.local_fire_department : Icons.health_and_safety, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Burnout: $status', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                        const SizedBox(height: 4),
                        Text(data['suggestion'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        predictionAsync.when(
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
          data: (data) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.analytics_rounded, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Predicted Score: ${data['predictedScore']}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        const SizedBox(height: 4),
                        Text(data['suggestion'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accentBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.tips_and_updates_rounded, color: AppColors.accentBlue, size: 20),
                  SizedBox(width: 8),
                  Text('AI Suggestions', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentBlue)),
                ],
              ),
              const SizedBox(height: 12),
              ...suggestions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.bold)),
                    Expanded(child: Text(s, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 52,
            lineWidth: 10,
            percent: pct,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${(pct * 100).toInt()}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                const Text('Today\'s Goal', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 4),
                Text('${studied}m / ${goal}m', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$sessions session${sessions != 1 ? 's' : ''} completed', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _ActionCard(icon: Icons.play_arrow_rounded, label: 'Start Session', color: AppColors.primary, onTap: () => context.push('/session/setup'))),
            const SizedBox(width: 12),
            Expanded(child: _ActionCard(icon: Icons.smart_toy_rounded, label: 'AI Coach', color: AppColors.accentBlue, onTap: () => context.push('/ai/chat'))),
            const SizedBox(width: 12),
            Expanded(child: _ActionCard(icon: Icons.bar_chart_rounded, label: 'Analytics', color: AppColors.accentGreen, onTap: () => context.push('/analytics'))),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      );
}

class _TodaySubjects extends StatelessWidget {
  final Map<String, int> breakdown;
  const _TodaySubjects({required this.breakdown});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Today\'s Subjects', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...breakdown.entries.map((e) {
            final h = e.value ~/ 60;
            final m = e.value % 60;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(h > 0 ? '${h}h ${m}m' : '${m}m', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
        ],
      );
}

// Placeholder pages for bottom nav
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
