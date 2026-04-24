import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../providers/exam_plan_provider.dart';
import '../models/exam_plan_model.dart';
import '../widgets/animations.dart';

class ExamPlannerScreen extends ConsumerStatefulWidget {
  const ExamPlannerScreen({super.key});
  @override
  ConsumerState<ExamPlannerScreen> createState() => _ExamPlannerScreenState();
}

class _ExamPlannerScreenState extends ConsumerState<ExamPlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(examPlanNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: PressButton(
          scaleDown: 0.88,
          onTap: () => context.go('/home'),
          child: Container(
            margin: const EdgeInsets.only(left: 12),
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 8)],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary),
          ),
        ),
        title: Text(
          'Exam Planner',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textPrimary),
        ),
        centerTitle: false,
        actions: [
          if (planAsync.valueOrNull != null)
            PressButton(
              scaleDown: 0.88,
              onTap: () => context.push('/exam-planner/setup'),
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              ),
            ),
        ],
        bottom: planAsync.valueOrNull != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.07), blurRadius: 12)],
                  ),
                  child: TabBar(
                    controller: _tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicator: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                    unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Study Plan'),
                      Tab(text: 'Topics & PYQ'),
                      Tab(text: 'Progress'),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (plan) {
          if (plan == null) return _NoPlanView();
          return TabBarView(
            controller: _tab,
            children: [
              _StudyPlanTab(plan: plan),
              _TopicsPyqTab(subjects: plan.subjects),
              _ProgressTab(plan: plan),
            ],
          );
        },
      ),
      floatingActionButton: planAsync.valueOrNull == null
          ? Container(
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: FloatingActionButton.extended(
                onPressed: () => context.push('/exam-planner/setup'),
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text('Create Plan', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            )
          : null,
    );
  }
}

// ── No Plan View ─────────────────────────────────────────────────────────────
class _NoPlanView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeSlideIn(
        duration: const Duration(milliseconds: 400),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calendar_today_rounded, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text('No Exam Plan Yet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                'Create your personalized AI study plan with PYQ-prioritized topics and daily tasks.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Study Plan Tab ────────────────────────────────────────────────────────────
class _StudyPlanTab extends ConsumerWidget {
  final ExamPlanModel plan;
  const _StudyPlanTab({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final byDay = <int, List<MapEntry<int, DailyTaskModel>>>{};
    for (int i = 0; i < plan.generatedPlan.length; i++) {
      final t = plan.generatedPlan[i];
      byDay.putIfAbsent(t.day, () => []).add(MapEntry(i, t));
    }
    final days = byDay.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: days.length,
      itemBuilder: (ctx, i) {
        final day = days[i];
        final tasks = byDay[day]!;
        final isToday = tasks.first.value.date == today;
        return _DayCard(
          day: day,
          tasks: tasks,
          isToday: isToday,
          planId: plan.id,
        );
      },
    );
  }
}

class _DayCard extends ConsumerWidget {
  final int day;
  final List<MapEntry<int, DailyTaskModel>> tasks;
  final bool isToday;
  final String planId;
  const _DayCard({required this.day, required this.tasks, required this.isToday, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allDone = tasks.every((e) => e.value.isCompleted);
    final date = tasks.first.value.date;
    final headerGradient = isToday
        ? AppColors.heroGradient
        : allDone
            ? AppColors.cardGradientGreen
            : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isToday
                ? AppColors.primary.withOpacity(0.18)
                : Colors.black.withOpacity(0.04),
            blurRadius: isToday ? 20 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                gradient: headerGradient,
                color: headerGradient == null ? AppColors.surface : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    if (tasks.first.value.isRevision) Container(
                      padding: const EdgeInsets.all(4),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: (isToday || allDone) ? Colors.white.withOpacity(0.25) : AppColors.accentTeal.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.refresh_rounded, size: 13, color: (isToday || allDone) ? Colors.white : AppColors.accentTeal),
                    ),
                    Text(
                      'Day $day${tasks.first.value.isRevision ? " · Revision" : ""}',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: (isToday || allDone) ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ]),
                  Row(children: [
                    if (isToday) Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('TODAY', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(date),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: (isToday || allDone) ? Colors.white.withOpacity(0.8) : AppColors.textSecondary,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            ...tasks.map((entry) {
              return _TaskTile(
                task: entry.value,
                globalIndex: entry.key,
                planId: planId,
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day} ${months[d.month - 1]}';
    } catch (_) { return iso; }
  }
}

class _TaskTile extends ConsumerWidget {
  final DailyTaskModel task;
  final int globalIndex;
  final String planId;
  const _TaskTile({required this.task, required this.globalIndex, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: globalIndex < 0 ? null : () {
        ref.read(examPlanNotifierProvider.notifier).toggleTask(planId, globalIndex, !task.isCompleted);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider, width: 0.8)),
          color: task.isCompleted ? AppColors.primaryLight.withOpacity(0.3) : Colors.white,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 26, height: 26,
              decoration: BoxDecoration(
                gradient: task.isCompleted ? AppColors.heroGradient : null,
                color: task.isCompleted ? null : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: task.isCompleted ? AppColors.primary : AppColors.divider,
                  width: task.isCompleted ? 0 : 1.5,
                ),
                boxShadow: task.isCompleted ? [
                  BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
                ] : [],
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.topic,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      color: task.isCompleted ? AppColors.textLight : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    task.subject,
                    style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${task.durationMinutes}m',
                style: GoogleFonts.outfit(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Topics & PYQ Tab ─────────────────────────────────────────────────────────
class _TopicsPyqTab extends StatelessWidget {
  final List<String> subjects;
  const _TopicsPyqTab({required this.subjects});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: subjects.length,
      itemBuilder: (ctx, i) {
        final subject = subjects[i];
        final color = AppColors.subjectColors[i % AppColors.subjectColors.length];
        
        return FadeSlideIn(
          delay: Duration(milliseconds: 60 * i),
          child: InkWell(
            onTap: () => context.push('/exam-planner/subject-info', extra: subject),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(Icons.auto_awesome_rounded, color: color, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(subject, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text('Generate AI Topics & PYQs', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textLight),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Progress Tab ─────────────────────────────────────────────────────────────
class _ProgressTab extends ConsumerWidget {
  final ExamPlanModel plan;
  const _ProgressTab({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(examProgressProvider);
    final total = plan.generatedPlan.length;
    final done = plan.generatedPlan.where((t) => t.isCompleted).length;
    final pct = total > 0 ? done / total : 0.0;
    final daysLeft = plan.examDate.difference(DateTime.now()).inDays;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Big progress ring
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(children: [
              const Text('Overall Progress', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 16),
              Stack(alignment: Alignment.center, children: [
                SizedBox(
                  width: 130, height: 130,
                  child: CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 12,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                Column(children: [
                  Text('${(pct * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const Text('Complete', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ]),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _StatChip(label: 'Done', value: '$done', icon: Icons.check_circle_outline),
                _StatChip(label: 'Left', value: '${total - done}', icon: Icons.pending_outlined),
                _StatChip(label: 'Days Left', value: '$daysLeft', icon: Icons.calendar_today_rounded),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          // Subjects
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Subjects', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ...plan.subjects.asMap().entries.map((e) {
                final color = AppColors.subjectColors[e.key % AppColors.subjectColors.length];
                final subjectTasks = plan.generatedPlan.where((t) => t.subject == e.value).toList();
                final subjectDone = subjectTasks.where((t) => t.isCompleted).length;
                final subjectPct = subjectTasks.isEmpty ? 0.0 : subjectDone / subjectTasks.length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(e.value, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('$subjectDone/${subjectTasks.length}', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: subjectPct,
                        backgroundColor: color.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      ),
                    ),
                  ]),
                );
              }),
            ]),
          ),
          const SizedBox(height: 16),
          // Daily study info
          progressAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (p) {
              if (p == null) return const SizedBox();
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Today's Tasks", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _InfoTile(label: 'Tasks Today', value: '${p.todayTasks}', color: AppColors.primary),
                    _InfoTile(label: 'Done Today', value: '${p.todayCompleted}', color: AppColors.accentGreen),
                    _InfoTile(label: 'Study Hours', value: '${p.dailyStudyHours}h', color: AppColors.accentOrange),
                  ]),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatChip({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, color: Colors.white70, size: 18),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
  ]);
}

class _InfoTile extends StatelessWidget {
  final String label, value;
  final Color color;
  const _InfoTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
  ]);
}
