import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/exam_plan_provider.dart';
import '../providers/test_provider.dart';
import '../models/exam_plan_model.dart';
import '../models/test_model.dart';
import '../widgets/bottom_nav_bar.dart';
import '../app_theme.dart';
import 'planner_screen.dart';
import 'ai_screen.dart';
import 'tests_screen.dart';
import 'profile_screen.dart';

// ── Shell ─────────────────────────────────────────────────────────────────────
class HomeScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const HomeScreen({super.key, this.initialTab = 0});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late int _idx = widget.initialTab;
  late final List<Widget> _pages = [
    const _HomeTab(),
    const PlannerScreen(),
    const AiScreen(),
    const TestsScreen(),
    const ProfileScreen(),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(index: _idx, children: _pages),
        bottomNavigationBar: BottomNavBar(
            currentIndex: _idx, onTap: (i) => setState(() => _idx = i)),
      );
}

// ── Home Tab ──────────────────────────────────────────────────────────────────
class _HomeTab extends ConsumerWidget {
  const _HomeTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final planAsync = ref.watch(examPlanNotifierProvider);
    final statsAsync = ref.watch(testStatsProvider);
    final firstName = user?.name.split(' ').first ?? 'Student';
    final hour = DateTime.now().hour;
    final greeting =
        hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(examPlanNotifierProvider);
          ref.invalidate(testStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroHeader(greeting: greeting, firstName: firstName, user: user),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuickActions(),
                    const SizedBox(height: 28),
                    planAsync.when(
                      loading: () => const _CardShimmer(),
                      error: (_, __) => const SizedBox(),
                      data: (plan) =>
                          plan == null ? _NoPlanBanner() : _TodayTasksSection(plan: plan),
                    ),
                    statsAsync.when(
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                      data: (stats) =>
                          stats.totalTests > 0 ? _StatsRow(stats: stats) : const SizedBox(),
                    ),
                    planAsync.when(
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                      data: (plan) =>
                          plan != null ? _UpcomingExamBanner(plan: plan) : const SizedBox(),
                    ),
                    const SizedBox(height: 24),
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

// ── Hero Header ───────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final String greeting, firstName;
  final dynamic user;
  const _HeroHeader({required this.greeting, required this.firstName, required this.user});
  @override
  Widget build(BuildContext context) {
    final name = user?.name as String? ?? 'S';
    final initials = name.split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase()).take(2).join();
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4C35C8), Color(0xFF7B5CFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('StudyCoach',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Center(
                  child: Text(initials,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        Text('$greeting,',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
        const SizedBox(height: 2),
        Text('$firstName 👋',
            style: const TextStyle(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.2)),
        const SizedBox(height: 6),
        Text("Ready to crush today's goals?",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
      ]),
    );
  }
}

// ── Quick Actions ─────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const actions = [
      (Icons.calendar_today_rounded, 'Planner', "Today's tasks", Color(0xFF6C4CF1), '/exam-planner'),
      (Icons.auto_awesome_rounded, 'AI Tutor', 'Ask anything', Color(0xFF0284C7), '/ai/chat'),
      (Icons.quiz_rounded, 'Take Test', 'Practice & assess', Color(0xFF059669), '/tests/setup'),
      (Icons.style_rounded, 'Flashcards', 'Quick revision', Color(0xFFD97706), '/flashcards'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Quick Actions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: actions
            .map((a) => _ActionTile(icon: a.$1, label: a.$2, sub: a.$3, color: a.$4, route: a.$5))
            .toList(),
      ),
    ]);
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label, sub, route;
  final Color color;
  const _ActionTile(
      {required this.icon,
      required this.label,
      required this.sub,
      required this.color,
      required this.route});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3))
          ],
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(sub,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
