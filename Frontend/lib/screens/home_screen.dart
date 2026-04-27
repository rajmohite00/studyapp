import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../providers/auth_provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/intelligence_provider.dart';
import '../providers/gamification_provider.dart';
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
        // Refresh analytics data when switching back to Home or Analytics tab
        if (i == 0 || i == 2) {
          ref.invalidate(dashboardProvider);
          ref.invalidate(subjectBreakdownProvider);
          ref.invalidate(streakProvider);
          ref.invalidate(gamificationStateProvider);
        }
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
              FadeSlideIn(
                duration: const Duration(milliseconds: 400),
                child: Container(
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
                            'StudyCoach',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Hi, ${user?.name.split(' ').first ?? 'Student'} 👋',
                            style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    PressButton(
                      scaleDown: 0.92,
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
              )),
              Container(height: 1.5, color: AppColors.divider),

              // ── HERO SECTION ─────────────────────────────────
              FadeSlideIn(
                beginOffset: const Offset(0, 0.04),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: AppColors.heroGradient,
                  ),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // Decorative blobs
                      Positioned(
                        top: -30, right: -30,
                        child: Container(
                          width: 140, height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -20, right: 60,
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 30, right: 30,
                        child: Text('✦', style: TextStyle(fontSize: 22, color: Colors.white.withOpacity(0.4))),
                      ),
                      Positioned(
                        top: 80, right: 100,
                        child: Text('✦', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3))),
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Emoji + greeting
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.22),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    const Text('📚', style: TextStyle(fontSize: 13)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'TIME TO LEVEL UP!',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Headline
                            Text(
                              'Let\'s Crush\nYour Exams 🎯',
                              style: GoogleFonts.outfit(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.15,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'AI-powered study sessions, smart plans\n& streak rewards for every student!',
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                color: Colors.white.withOpacity(0.85),
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Quick-stat chips row
                            Row(
                              children: [
                                _HeroStatChip(emoji: '⚡', label: 'AI Coach'),
                                const SizedBox(width: 8),
                                _HeroStatChip(emoji: '🔥', label: 'Streaks'),
                                const SizedBox(width: 8),
                                _HeroStatChip(emoji: '📊', label: 'Analytics'),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Primary CTA
                            PressButton(
                              scaleDown: 0.97,
                              onTap: () => context.push('/session/setup'),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 17),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 6))],
                                ),
                                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  const Text('⚡', style: TextStyle(fontSize: 18)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Start Studying Now',
                                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                                  ),
                                ]),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Secondary CTA
                            PressButton(
                              scaleDown: 0.97,
                              onTap: () => context.push('/exam-planner'),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Colors.white.withOpacity(0.45), width: 1.5),
                                ),
                                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  const Text('📅', style: TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Plan My Exam',
                                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                ]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── GAMIFICATION BANNER ────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: const _GamificationBanner(),
              ),

              // ── PROGRESS SECTION ─────────────────────────────
              dashAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5)),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider, width: 2),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        const Text('Unable to load dashboard', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => ref.refresh(dashboardProvider.future),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            foregroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3))),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
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

                    // Exam Planner Quick Access
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 220),
                      child: _ExamPlannerCard(),
                    ),

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
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5),
              ),
            ),
          ],
        ),
      );
}

// ── Exam Planner Quick Access Card ───────────────────────────────────────────
class _ExamPlannerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: PressButton(
        scaleDown: 0.97,
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/exam-planner'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.textPrimary, width: 2),
            boxShadow: const [BoxShadow(color: AppColors.textPrimary, offset: Offset(4, 4))],
          ),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.textPrimary, width: 2),
                  boxShadow: const [BoxShadow(color: AppColors.textPrimary, offset: Offset(2, 2))],
                ),
                child: const Icon(Icons.calendar_today_rounded, color: AppColors.textPrimary, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Exam Planner',
                        style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    const Text('AI-generated study plan with PYQs',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.textPrimary, width: 2),
                  boxShadow: const [BoxShadow(color: AppColors.textPrimary, offset: Offset(2, 2))],
                ),
                child: Text('Open →', style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
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

// ── Hero stat chip ─────────────────────────────────────────────────────────────
class _HeroStatChip extends StatelessWidget {
  final String emoji;
  final String label;
  const _HeroStatChip({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
}

// ── Gamification Banner ──────────────────────────────────────────────────────
class _GamificationBanner extends ConsumerWidget {
  const _GamificationBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(gamificationStateProvider);

    return stateAsync.when(
      loading: () => const LinearProgressIndicator(color: AppColors.primary),
      error: (_, __) => const SizedBox(),
      data: (state) {
        return PressButton(
          scaleDown: 0.96,
          onTap: () => context.push('/rewards'),
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 32, 20, 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F35E1), Color(0xFF864AF9)], // Vibrant purple to neon violet
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF864AF9).withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.white.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2)
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${state.level}',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                state.rank.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: Colors.white,
                                ),
                              ),
                              if (state.activeBadgeEmoji != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(state.activeBadgeEmoji!, style: const TextStyle(fontSize: 14)),
                                ),
                              ],
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Text('🪙', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(
                                  '${state.coins}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AnimatedProgressBar(
                        value: state.xpNeeded > 0 ? state.xpProgress / state.xpNeeded : 1.0,
                        color: const Color(0xFF00FFC6), // Neon green
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        height: 8,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${state.xp} XP • ${state.xpNeeded - state.xpProgress} XP to next level',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

