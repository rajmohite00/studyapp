import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/exam_plan_provider.dart';
import '../providers/test_provider.dart';
import '../models/exam_plan_model.dart';
import '../models/test_model.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/shimmer_box.dart';
import '../widgets/animations.dart';
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
  late final Set<int> _visited = {widget.initialTab};

  static const List<Widget> _tabs = [
    _HomeTab(),
    PlannerScreen(),
    AiScreen(),
    TestsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: List.generate(_tabs.length, (i) {
          if (!_visited.contains(i)) return const SizedBox.shrink();
          return Offstage(
            offstage: _idx != i,
            child: TickerMode(enabled: _idx == i, child: _tabs[i]),
          );
        }),
      ),
      bottomNavigationBar: _PremiumBottomNav(
        currentIndex: _idx,
        onTap: (i) => setState(() {
          _visited.add(i);
          _idx = i;
        }),
      ),
    );
  }
}

// ── Bottom Navigation ─────────────────────────────────────────────────────────
class _PremiumBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _PremiumBottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'Planner'),
    (Icons.auto_awesome_outlined, Icons.auto_awesome_rounded, 'AI'),
    (Icons.quiz_outlined, Icons.quiz_rounded, 'Tests'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20, offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (i) {
              final sel = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.symmetric(
                            horizontal: sel ? 14 : 6, vertical: 5),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          sel ? _items[i].$2 : _items[i].$1,
                          size: 22,
                          color: sel ? AppColors.primary : AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(_items[i].$3,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                              color: sel ? AppColors.primary : AppColors.textLight)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
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
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

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
              _HomeAppBar(firstName: firstName, greeting: greeting, user: user),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuickActionsGrid(),
                    const SizedBox(height: 28),
                    planAsync.when(
                      loading: () => const _Shimmer(height: 180),
                      error: (_, __) => const SizedBox(),
                      data: (plan) => plan == null
                          ? _NoPlanCard()
                          : _TodayPlanCard(plan: plan),
                    ),
                    statsAsync.when(
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                      data: (stats) => stats.totalTests > 0
                          ? _ProgressRow(stats: stats)
                          : const SizedBox(),
                    ),
                    planAsync.when(
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                      data: (plan) => plan != null
                          ? _ExamCountdown(plan: plan)
                          : const SizedBox(),
                    ),
                    const SizedBox(height: 32),
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

// ── App Bar ───────────────────────────────────────────────────────────────────
class _HomeAppBar extends StatelessWidget {
  final String firstName, greeting;
  final dynamic user;
  const _HomeAppBar({required this.firstName, required this.greeting, required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user?.name as String? ?? 'S';
    final initials = name.split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase()).take(2).join();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(greeting,
                style: GoogleFonts.outfit(
                    fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text('$firstName 👋',
                style: GoogleFonts.outfit(
                    fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
                    letterSpacing: -0.3)),
          ]),
        ),
        // Notification bell
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: const Icon(Icons.notifications_outlined, size: 20, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 10),
        // Avatar
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(initials,
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Quick Actions Grid ────────────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  static const _actions = [
    (Icons.calendar_today_rounded, 'Planner', "Today's tasks", Color(0xFF6C4CF1), '/exam-planner'),
    (Icons.auto_awesome_rounded,   'AI Tutor', 'Ask anything',  Color(0xFF0EA5E9), '/ai/chat'),
    (Icons.quiz_rounded,           'Take Test', 'Practice now', Color(0xFF10B981), '/tests/setup'),
    (Icons.menu_book_rounded,      'Exam Plan', 'AI study plan', Color(0xFFF59E0B), '/exam-planner/setup'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Quick Actions',
          style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
      const SizedBox(height: 14),
      GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.65,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: _actions.map((a) => _ActionCard(
          icon: a.$1, label: a.$2, sub: a.$3, color: a.$4, route: a.$5,
        )).toList(),
      ),
    ]);
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label, sub, route;
  final Color color;
  const _ActionCard({required this.icon, required this.label, required this.sub,
      required this.color, required this.route});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.10),
              blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(label, style: GoogleFonts.outfit(fontSize: 13,
              fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text(sub, style: GoogleFonts.outfit(fontSize: 11,
              color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

// ── No Plan Banner ────────────────────────────────────────────────────────────
class _NoPlanCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
              color: AppColors.primaryLight, borderRadius: BorderRadius.circular(13)),
          child: const Icon(Icons.add_task_rounded, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("No Study Plan Yet",
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          Text("Create an AI-powered plan",
              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
        ])),
        GestureDetector(
          onTap: () => context.push('/exam-planner/setup'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
                color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
            child: Text('Create',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

// ── Today's Plan Card ─────────────────────────────────────────────────────────
class _TodayPlanCard extends ConsumerWidget {
  final ExamPlanModel plan;
  const _TodayPlanCard({required this.plan});

  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = _today();
    final tasks = plan.generatedPlan.asMap().entries
        .where((e) => e.value.date == today).take(4).toList();
    final total = plan.generatedPlan.where((t) => t.date == today).length;
    final done  = plan.generatedPlan.where((t) => t.date == today && t.isCompleted).length;
    final pct   = total > 0 ? (done / total) : 0.0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text("Today's Plan", style: GoogleFonts.outfit(fontSize: 17,
            fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        GestureDetector(
          onTap: () => context.push('/exam-planner'),
          child: Text('See All', style: GoogleFonts.outfit(fontSize: 13,
              color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(children: [
          // Progress header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$done / $total tasks completed',
                    style: GoogleFonts.outfit(fontSize: 12,
                        color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct.toDouble(),
                    minHeight: 6,
                    backgroundColor: AppColors.primaryLight,
                    color: AppColors.primary,
                  ),
                ),
              ])),
              const SizedBox(width: 12),
              Text('${(pct * 100).toInt()}%',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFF3F3F7)),
          // Task rows
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Text('🎉', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text('All done for today!',
                    style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary)),
              ]),
            )
          else
            ...tasks.asMap().entries.map((entry) {
              final isLast = entry.key == tasks.length - 1;
              final e = entry.value;
              return Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => ref.read(examPlanNotifierProvider.notifier)
                          .toggleTask(plan.id, e.key, !e.value.isCompleted),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: e.value.isCompleted ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: e.value.isCompleted ? AppColors.primary : AppColors.textLight,
                              width: 1.5),
                        ),
                        child: e.value.isCompleted
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(e.value.topic,
                        style: GoogleFonts.outfit(fontSize: 13,
                            color: e.value.isCompleted ? AppColors.textLight : AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            decoration: e.value.isCompleted ? TextDecoration.lineThrough : null))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6)),
                      child: Text('${e.value.durationMinutes}m',
                          style: GoogleFonts.outfit(fontSize: 11,
                              color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
                if (!isLast) const Divider(height: 1, indent: 50, color: Color(0xFFF3F3F7)),
              ]);
            }),
          const SizedBox(height: 8),
        ]),
      ),
      const SizedBox(height: 28),
    ]);
  }
}

// ── Progress Row ──────────────────────────────────────────────────────────────
class _ProgressRow extends StatelessWidget {
  final TestStats stats;
  const _ProgressRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Your Progress', style: GoogleFonts.outfit(fontSize: 17,
            fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        GestureDetector(
          onTap: () => context.push('/tests/analytics'),
          child: Text('Details', style: GoogleFonts.outfit(fontSize: 13,
              color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        _StatCard(icon: Icons.quiz_rounded, label: 'Tests', value: '${stats.totalTests}',
            color: const Color(0xFF6C4CF1)),
        const SizedBox(width: 10),
        _StatCard(icon: Icons.trending_up_rounded, label: 'Avg Score',
            value: '${stats.avgScore}%', color: const Color(0xFF10B981)),
        const SizedBox(width: 10),
        _StatCard(icon: Icons.gps_fixed_rounded, label: 'Accuracy',
            value: '${stats.overallAccuracy}%', color: const Color(0xFF0EA5E9)),
      ]),
      const SizedBox(height: 28),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatCard({required this.icon, required this.label,
      required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.outfit(fontSize: 18,
              fontWeight: FontWeight.w800, color: color)),
          Text(label, style: GoogleFonts.outfit(fontSize: 10,
              color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}

// ── Exam Countdown ────────────────────────────────────────────────────────────
class _ExamCountdown extends StatelessWidget {
  final ExamPlanModel plan;
  const _ExamCountdown({required this.plan});

  @override
  Widget build(BuildContext context) {
    final daysLeft = plan.examDate.difference(DateTime.now()).inDays;
    final isUrgent = daysLeft <= 3;
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final monthStr = months[plan.examDate.month - 1];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Upcoming Exam', style: GoogleFonts.outfit(fontSize: 17,
            fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        GestureDetector(
          onTap: () => context.push('/exam-planner'),
          child: Text('View Plan', style: GoogleFonts.outfit(fontSize: 13,
              color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () => context.push('/exam-planner'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isUrgent
                ? const Color(0xFFEF4444).withValues(alpha: 0.25)
                : AppColors.primary.withValues(alpha: 0.12)),
            boxShadow: [BoxShadow(
                color: (isUrgent ? const Color(0xFFEF4444) : AppColors.primary)
                    .withValues(alpha: 0.06),
                blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(children: [
            Container(
              width: 50, height: 54,
              decoration: BoxDecoration(
                  color: isUrgent ? const Color(0xFFEF4444) : AppColors.primary,
                  borderRadius: BorderRadius.circular(13)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(monthStr.toUpperCase(),
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 9,
                        fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                Text('${plan.examDate.day}',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 20,
                        fontWeight: FontWeight.w800, height: 1.1)),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(plan.subjects.join(', '), style: GoogleFonts.outfit(fontSize: 14,
                  fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${plan.subjects.length} subject${plan.subjects.length > 1 ? 's' : ''}',
                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isUrgent
                    ? const Color(0xFFEF4444).withValues(alpha: 0.10)
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(daysLeft <= 0 ? 'Today!' : '$daysLeft days',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700,
                      color: isUrgent ? const Color(0xFFEF4444) : AppColors.primary)),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 8),
    ]);
  }
}

// ── Utility shimmer ───────────────────────────────────────────────────────────
class _Shimmer extends StatelessWidget {
  final double height;
  const _Shimmer({required this.height});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 28),
    child: ShimmerBox(height: height, borderRadius: BorderRadius.circular(18)),
  );
}
