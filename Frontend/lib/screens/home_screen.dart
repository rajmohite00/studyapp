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

// ── Shimmer / No-plan ─────────────────────────────────────────────────────────
class _CardShimmer extends StatelessWidget {
  const _CardShimmer();
  @override
  Widget build(BuildContext context) => Container(
        height: 140,
        margin: const EdgeInsets.only(bottom: 28),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
      );
}

class _NoPlanBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration:
              BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.add_task_rounded, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('No Study Plan Yet',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text('Create an AI plan to get daily tasks',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
        GestureDetector(
          onTap: () => context.push('/exam-planner/setup'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration:
                BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
            child: const Text('Create',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

// ── Today's Tasks Section ─────────────────────────────────────────────────────
class _TodayTasksSection extends ConsumerWidget {
  final ExamPlanModel plan;
  const _TodayTasksSection({required this.plan});

  static String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = _todayStr();
    final tasks =
        plan.generatedPlan.asMap().entries.where((e) => e.value.date == today).take(3).toList();
    final total = plan.generatedPlan.where((t) => t.date == today).length;
    final done = plan.generatedPlan.where((t) => t.date == today && t.isCompleted).length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("Today's Plan",
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        GestureDetector(
          onTap: () => context.push('/exam-planner'),
          child: const Text('See All',
              style: TextStyle(
                  fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Column(children: [
          // ── Progress banner inside card ────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle_outline_rounded, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('$done of $total tasks done today',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
              const Spacer(),
              Text(total > 0 ? '${((done / total) * 100).toInt()}%' : '0%',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ]),
          ),
          // ── Task rows ─────────────────────────────────
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(children: [
                Icon(Icons.celebration_rounded, color: AppColors.accentGreen, size: 18),
                SizedBox(width: 8),
                Text('All done for today! 🎉',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ]),
            )
          else
            ...tasks.asMap().entries.map((entry) {
              final isLast = entry.key == tasks.length - 1;
              final e = entry.value;
              return Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => ref
                          .read(examPlanNotifierProvider.notifier)
                          .toggleTask(plan.id, e.key, !e.value.isCompleted),
                      child: Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          color: e.value.isCompleted ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                              color: e.value.isCompleted ? AppColors.primary : AppColors.textLight,
                              width: 1.5),
                        ),
                        child: e.value.isCompleted
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(e.value.topic,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: e.value.isCompleted
                                    ? AppColors.textLight
                                    : AppColors.textPrimary,
                                decoration:
                                    e.value.isCompleted ? TextDecoration.lineThrough : null))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppColors.surface, borderRadius: BorderRadius.circular(6)),
                      child: Text('${e.value.durationMinutes}m',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
                if (!isLast)
                  const Divider(height: 1, indent: 48, color: Color(0xFFF0F0F0)),
              ]);
            }),
          // ── Go to planner button ────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: GestureDetector(
              onTap: () => context.push('/exam-planner'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                    color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.calendar_today_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text('Open Full Planner',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ]),
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 28),
    ]);
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final TestStats stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Your Progress',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        GestureDetector(
          onTap: () => context.push('/tests/analytics'),
          child: const Text('Details',
              style: TextStyle(
                  fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
            child: _StatChip(
                icon: Icons.quiz_rounded,
                label: 'Tests',
                value: '${stats.totalTests}',
                color: const Color(0xFF6C4CF1))),
        const SizedBox(width: 10),
        Expanded(
            child: _StatChip(
                icon: Icons.bar_chart_rounded,
                label: 'Avg Score',
                value: '${stats.avgScore}%',
                color: const Color(0xFF059669))),
        const SizedBox(width: 10),
        Expanded(
            child: _StatChip(
                icon: Icons.gps_fixed_rounded,
                label: 'Accuracy',
                value: '${stats.overallAccuracy}%',
                color: const Color(0xFF0284C7))),
      ]),
      const SizedBox(height: 28),
    ]);
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatChip(
      {required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.07), blurRadius: 6, offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ]),
    );
  }
}

// ── Upcoming Exam Banner ──────────────────────────────────────────────────────
class _UpcomingExamBanner extends StatelessWidget {
  final ExamPlanModel plan;
  const _UpcomingExamBanner({required this.plan});

  @override
  Widget build(BuildContext context) {
    final daysLeft = plan.examDate.difference(DateTime.now()).inDays;
    final isUrgent = daysLeft <= 3;
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final monthStr = months[plan.examDate.month - 1];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Upcoming Exam',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        GestureDetector(
          onTap: () => context.push('/exam-planner'),
          child: const Text('View Plan',
              style: TextStyle(
                  fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () => context.push('/exam-planner'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isUrgent
                    ? const Color(0xFFE53E3E).withValues(alpha: 0.3)
                    : AppColors.primary.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                  color: (isUrgent ? const Color(0xFFE53E3E) : AppColors.primary)
                      .withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Row(children: [
            Container(
              width: 48, height: 52,
              decoration: BoxDecoration(
                color: isUrgent ? const Color(0xFFE53E3E) : AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(monthStr.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                Text('${plan.examDate.day}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.1)),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(plan.subjects.join(', '),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text('${plan.subjects.length} subject${plan.subjects.length > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isUrgent
                    ? const Color(0xFFE53E3E).withValues(alpha: 0.1)
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                daysLeft <= 0 ? 'Today!' : '$daysLeft days',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isUrgent ? const Color(0xFFE53E3E) : AppColors.primary),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 8),
    ]);
  }
}
