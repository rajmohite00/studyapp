import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/exam_plan_provider.dart';
import '../models/exam_plan_model.dart';
import '../widgets/bottom_nav_bar.dart';
import '../app_theme.dart';
import 'planner_screen.dart';
import 'ai_screen.dart';
import 'tests_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _idx = 0;

  late final List<Widget> _pages = [
    const _HomeTab(),
    const PlannerScreen(),
    const AiScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _idx, children: _pages),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
      ),
    );
  }
}

// ─────────────────────────── HOME TAB ────────────────────────────────────────
class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final planAsync = ref.watch(examPlanNotifierProvider);
    final firstName = user?.name.split(' ').first ?? 'Student';

    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning,' : hour < 17 ? 'Good Afternoon,' : 'Good Evening,';

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(examPlanNotifierProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top bar ────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: AppColors.primary, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Greeting ──────────────────────────────────
              Text(greeting,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Row(children: [
                Text('$firstName ',
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const Text('👋', style: TextStyle(fontSize: 24)),
              ]),
              const SizedBox(height: 4),
              const Text("Let's make today productive.",
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 24),

              // ── Today's Plan ──────────────────────────────
              planAsync.when(
                loading: () => _TodayPlanCard(tasks: const [], planId: '', isLoading: true),
                error: (_, __) => _TodayPlanCard(tasks: const [], planId: '', isLoading: false),
                data: (plan) {
                  if (plan == null) return _NoPlanCard();
                  final today = _todayStr();
                  final todayTasks = plan.generatedPlan
                      .asMap()
                      .entries
                      .where((e) => e.value.date == today)
                      .take(3)
                      .toList();
                  return _TodayPlanCard(
                      tasks: todayTasks, planId: plan.id, isLoading: false);
                },
              ),
              const SizedBox(height: 20),

              // ── AI Study Assistant quick card ──────────────
              _AiQuickCard(),
              const SizedBox(height: 20),

              // ── Upcoming Exams ────────────────────────────
              planAsync.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (plan) => plan == null
                    ? const SizedBox()
                    : _UpcomingExamCard(plan: plan),
              ),
              const SizedBox(height: 20),

              // ── Continue Learning ─────────────────────────
              planAsync.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (plan) {
                  if (plan == null || plan.subjects.isEmpty) return const SizedBox();
                  return _ContinueLearningSection(plan: plan);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}

// ── Today's Plan Card ──────────────────────────────────────────────────────────
class _TodayPlanCard extends ConsumerWidget {
  final List<MapEntry<int, DailyTaskModel>> tasks;
  final String planId;
  final bool isLoading;
  const _TodayPlanCard(
      {required this.tasks, required this.planId, required this.isLoading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Today\'s Plan',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            GestureDetector(
              onTap: () => context.push('/exam-planner'),
              child: const Text('View All',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
          else if (tasks.isEmpty)
            const Text('No tasks for today',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
          else
            ...tasks.map((e) => _TaskRow(
                  task: e.value,
                  index: e.key,
                  planId: planId,
                )),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => context.push('/exam-planner'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Go to Planner',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends ConsumerWidget {
  final DailyTaskModel task;
  final int index;
  final String planId;
  const _TaskRow({required this.task, required this.index, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        GestureDetector(
          onTap: () => ref
              .read(examPlanNotifierProvider.notifier)
              .toggleTask(planId, index, !task.isCompleted),
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: task.isCompleted ? AppColors.primary : Colors.transparent,
              border: Border.all(
                  color: task.isCompleted ? AppColors.primary : AppColors.textLight,
                  width: 1.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: task.isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 12)
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(task.topic,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: task.isCompleted
                      ? AppColors.textLight
                      : AppColors.textPrimary,
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null)),
        ),
        Text('${task.durationMinutes} min',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]),
    );
  }
}

// ── No Plan Card ───────────────────────────────────────────────────────────────
class _NoPlanCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Today's Plan",
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          const Text('No exam plan yet. Create one to see your daily tasks.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => context.push('/exam-planner/setup'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                  color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Create Plan',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── AI Quick Card ──────────────────────────────────────────────────────────────
class _AiQuickCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Study Assistant',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text('Ask anything about your studies.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ]),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push('/ai/chat'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                  color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [
                Expanded(
                    child: Text('Type your question...',
                        style: TextStyle(color: AppColors.textLight, fontSize: 13))),
                Icon(Icons.arrow_circle_right_rounded,
                    color: AppColors.primary, size: 28),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Upcoming Exam Card ─────────────────────────────────────────────────────────
class _UpcomingExamCard extends StatelessWidget {
  final ExamPlanModel plan;
  const _UpcomingExamCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final daysLeft = plan.examDate.difference(DateTime.now()).inDays;
    final month = _months[plan.examDate.month - 1];
    final day = plan.examDate.day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Upcoming Exams',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          GestureDetector(
            onTap: () => context.push('/exam-planner'),
            child: const Text('View All',
                style: TextStyle(
                    fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDeco(),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(month.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                Text('$day',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(plan.subjects.join(', '),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text('${plan.subjects.length} subject${plan.subjects.length > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: daysLeft <= 3 ? const Color(0xFFFFEDE8) : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                daysLeft <= 0 ? 'Today' : '$daysLeft Days Left',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: daysLeft <= 3 ? AppColors.accent : AppColors.primary),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
  ];
}

// ── Continue Learning ──────────────────────────────────────────────────────────
class _ContinueLearningSection extends StatelessWidget {
  final ExamPlanModel plan;
  const _ContinueLearningSection({required this.plan});

  @override
  Widget build(BuildContext context) {
    final total = plan.generatedPlan.length;
    final done = plan.generatedPlan.where((t) => t.isCompleted).length;
    final pct = total > 0 ? done / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Continue Learning',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          GestureDetector(
            onTap: () => context.push('/exam-planner'),
            child: const Text('View All',
                style: TextStyle(
                    fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => context.push('/exam-planner'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: _cardDeco(),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.menu_book_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(plan.subjects.first,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text(plan.subjects.join(' & '),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 5,
                      backgroundColor: AppColors.primaryLight,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

BoxDecoration _cardDeco() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))
      ],
    );
