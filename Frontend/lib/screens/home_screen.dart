import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../providers/auth_provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/intelligence_provider.dart';
import '../widgets/streak_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/animations.dart';
import '../app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'session_setup_screen.dart';
import 'analytics_screen.dart';
import 'ai_chat_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _navIndex = 0;
  final List<Widget> _pages = const [
    _HomePage(),
    SessionSetupScreen(),
    AnalyticsScreen(),
    AiChatScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: _navIndex, onTap: (i) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── TOP APP BAR ─────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STUDY COACH',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            'Good ${_greeting()}, ${user?.name.split(' ').first ?? 'Student'} 👋',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accentGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: Center(
                          child: Text(
                            user?.name.substring(0, 1).toUpperCase() ?? 'S',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1.5, color: AppColors.divider),

              // ── HERO SECTION
              FadeSlideIn(
                beginOffset: const Offset(0, 0.05),
                child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  border: Border(
                    bottom: BorderSide(color: AppColors.textPrimary, width: 3),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 36, 20, 36),
                child: Column(
                  children: [
                    // Badge pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.textPrimary, width: 2),
                        boxShadow: const [BoxShadow(color: AppColors.textPrimary, offset: Offset(3, 3))],
                      ),
                      child: Text(
                        '✦  YOUR DAILY STUDY COMPANION',
                        style: GoogleFonts.syne(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: 1.2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Study Coach',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.syne(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimary, height: 1.0, letterSpacing: -1.0),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.textPrimary, width: 2),
                        boxShadow: const [BoxShadow(color: AppColors.textPrimary, offset: Offset(4, 4))],
                      ),
                      child: const Text(
                        'Focus. Plan. Execute.\nCrush your next exam with AI.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Primary CTA
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push('/session/setup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: AppColors.textPrimary, width: 3),
                          ),
                          elevation: 0,
                        ).copyWith(
                          shadowColor: MaterialStateProperty.all(AppColors.textPrimary),
                          elevation: MaterialStateProperty.all(6),
                        ),
                        child: Text('Start Study Session  →', style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Secondary CTA
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/exam-planner'),
                        icon: const Icon(Icons.menu_book_rounded, size: 18),
                        label: const Text('Plan Your Exam'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          side: const BorderSide(color: AppColors.textPrimary, width: 3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ).copyWith(
                          shadowColor: MaterialStateProperty.all(AppColors.textPrimary),
                          elevation: MaterialStateProperty.all(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ), // closes Container
              ), // closes FadeSlideIn hero

              // ── PROGRESS SECTION ─────────────────────────────
              dashAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5)),
                ),
                error: (e, _) => Padding(padding: const EdgeInsets.all(20), child: Text('$e', style: const TextStyle(color: AppColors.textSecondary))),
                data: (data) => Column(
                  children: [
                    // Progress section header
                    _BoldSectionHeader(title: 'Your Progress', icon: Icons.trending_up_rounded, bg: AppColors.surface),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: _GoalCard(studied: data.today.totalMinutes, goal: data.dailyGoalMinutes, sessions: data.today.sessionCount),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: FadeSlideIn(
                        delay: const Duration(milliseconds: 160),
                        child: StreakCard(
                          currentStreak: data.streak.current,
                          longestStreak: data.streak.longest,
                          freezesAvailable: data.streak.freezesAvailable,
                          nextMilestone: data.streak.nextMilestone,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Features section (Guidelines-style floating icon cards)
                    _BoldSectionHeader(title: 'What You Can Do', icon: Icons.apps_rounded, bg: AppColors.surface),
                    _FloatingIconCards(),

                    // AI Suggestions (mentor-card style)
                    _AiSuggestionsWidget(),

                    // Smart Insights
                    _SmartInsightsWidget(burnoutAsync: ref.watch(burnoutProvider), predictionAsync: ref.watch(predictionProvider)),

                    // Today's subjects
                    if (data.today.subjectBreakdown.isNotEmpty) ...[
                      _BoldSectionHeader(title: "Today's Subjects", icon: Icons.auto_stories_rounded, bg: AppColors.surface),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: _TodaySubjects(breakdown: data.today.subjectBreakdown),
                      ),
                    ],
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

// ── Bold Section Header (Guidelines-style) ─────────────────────────────────────
class _BoldSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color bg;
  const _BoldSectionHeader({required this.title, required this.icon, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: bg,
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.textPrimary, width: 2),
                boxShadow: const [BoxShadow(color: AppColors.textPrimary, offset: Offset(2, 2))],
              ),
              child: Icon(icon, size: 22, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5),
              ),
            ),
          ],
        ),
      );
}

// ── Floating Icon Cards (like Guidelines section in reference) ─────────────────
class _FloatingIconCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final features = [
      _FeatureData(icon: Icons.timer_rounded, label: 'Study Timer', desc: 'Pomodoro & custom focus sessions', color: AppColors.primary, route: '/session/setup'),
      _FeatureData(icon: Icons.smart_toy_rounded, label: 'AI Coach', desc: 'Ask anything, get personalized help', color: AppColors.accentGreen, route: '/ai/chat'),
      _FeatureData(icon: Icons.calendar_today_rounded, label: 'Exam Planner', desc: 'AI-generated study plan with PYQs', color: AppColors.accent, route: '/exam-planner'),
      _FeatureData(icon: Icons.bar_chart_rounded, label: 'Analytics', desc: 'Heatmaps, focus scores & insights', color: AppColors.accentOrange, route: '/analytics'),
    ];

    return Column(
      children: features.map((f) => _FloatingIconCard(feature: f)).toList(),
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String label, desc, route;
  final Color color;
  const _FeatureData({required this.icon, required this.label, required this.desc, required this.color, required this.route});
}

class _FloatingIconCard extends StatelessWidget {
  final _FeatureData feature;
  const _FloatingIconCard({required this.feature});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Card body
            GestureDetector(
              onTap: () => context.push(feature.route),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 28),
                padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.textPrimary, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 0, offset: const Offset(4, 4))],
                ),
                child: Column(
                  children: [
                    Text(feature.label, style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Text(feature.desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: feature.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.textPrimary, width: 2),
                        boxShadow: const [BoxShadow(color: AppColors.textPrimary, offset: Offset(2, 2))],
                      ),
                      child: Text('Open  →', style: GoogleFonts.syne(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
            // Floating circular icon
            Positioned(
              top: 0,
              child: Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: feature.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.textPrimary, width: 3),
                  boxShadow: const [BoxShadow(color: AppColors.textPrimary, offset: Offset(3, 3))],
                ),
                child: Icon(feature.icon, color: AppColors.textPrimary, size: 30),
              ),
            ),
          ],
        ),
      );
}

// ── Goal Card ──────────────────────────────────────────────────────────────────
class _GoalCard extends StatelessWidget {
  final int studied, goal, sessions;
  const _GoalCard({required this.studied, required this.goal, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final pct = (studied / goal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textPrimary, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 0, offset: const Offset(4, 4))],
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 48,
            lineWidth: 8,
            percent: pct,
            center: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${(pct * 100).toInt()}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
            ]),
            progressColor: AppColors.primary,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Goal', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text('${studied}m / ${goal}m', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
                  ),
                  child: Text('$sessions session${sessions != 1 ? 's' : ''} done', style: const TextStyle(color: AppColors.accentGreen, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── AI Suggestions (Mentor-card style) ────────────────────────────────────────
class _AiSuggestionsWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSugg = ref.watch(suggestionsProvider);
    return asyncSugg.when(
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
      data: (suggestions) {
        if (suggestions.isEmpty) return const SizedBox();
        return Column(
          children: [
            _BoldSectionHeader(title: 'AI Suggestions', icon: Icons.tips_and_updates_rounded, bg: AppColors.surface),
            ...suggestions.take(3).map((s) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.textPrimary, width: 3),
                  boxShadow: const [BoxShadow(color: AppColors.textPrimary, offset: Offset(4, 4))],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.textPrimary, width: 2),
                        boxShadow: const [BoxShadow(color: AppColors.textPrimary, offset: Offset(2, 2))],
                      ),
                      child: const Icon(Icons.lightbulb_rounded, color: AppColors.textPrimary, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Text(s, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5, fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            )),
          ],
        );
      },
    );
  }
}

// ── Smart Insights ─────────────────────────────────────────────────────────────
class _SmartInsightsWidget extends StatelessWidget {
  final AsyncValue burnoutAsync;
  final AsyncValue predictionAsync;
  const _SmartInsightsWidget({required this.burnoutAsync, required this.predictionAsync});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BoldSectionHeader(title: 'Smart Insights', icon: Icons.psychology_rounded, bg: AppColors.surface),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              burnoutAsync.when(
                loading: () => const LinearProgressIndicator(color: AppColors.primary),
                error: (_, __) => const SizedBox(),
                data: (data) {
                  final d = data as Map<String, dynamic>;
                  final status = d['status'];
                  final isHigh = status == 'High Risk';
                  final isWarn = status == 'Warning';
                  final color = isHigh ? const Color(0xFFE07A5F) : (isWarn ? AppColors.accentOrange : AppColors.accentGreen);
                  return _InsightCard(icon: isHigh ? Icons.local_fire_department_rounded : Icons.health_and_safety_rounded, color: color, title: 'Burnout: $status', subtitle: d['suggestion']);
                },
              ),
              const SizedBox(height: 12),
              predictionAsync.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (data) {
                  final d = data as Map<String, dynamic>;
                  return _InsightCard(icon: Icons.analytics_rounded, color: AppColors.primary, title: 'Predicted Score: ${d['predictedScore']}%', subtitle: d['suggestion']);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  const _InsightCard({required this.icon, required this.color, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 13)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── Today's Subjects ───────────────────────────────────────────────────────────
class _TodaySubjects extends StatelessWidget {
  final Map<String, int> breakdown;
  const _TodaySubjects({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.subjectColors;
    int i = 0;
    return Column(
      children: breakdown.entries.map((e) {
        final h = e.value ~/ 60;
        final m = e.value % 60;
        final color = colors[i++ % colors.length];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider, width: 1.5),
          ),
          child: Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(h > 0 ? '${h}h ${m}m' : '${m}m', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

