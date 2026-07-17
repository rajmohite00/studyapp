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
