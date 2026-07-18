import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app_theme.dart';
import '../providers/exam_plan_provider.dart';
import '../models/exam_plan_model.dart';
import '../widgets/shimmer_box.dart';

class ExamPlannerScreen extends ConsumerStatefulWidget {
  const ExamPlannerScreen({super.key});
  @override
  ConsumerState<ExamPlannerScreen> createState() => _ExamPlannerScreenState();
}

class _ExamPlannerScreenState extends ConsumerState<ExamPlannerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(examPlanNotifierProvider);
    final hasPlan = planAsync.valueOrNull != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const Text('Exam Planner',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        actions: [
          if (hasPlan)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
              onPressed: () => context.push('/exam-planner/setup'),
              tooltip: 'New Plan',
            ),
        ],
        bottom: hasPlan
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TabBar(
                    controller: _tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Study Plan'),
                      Tab(text: 'Topics'),
                      Tab(text: 'Progress'),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: planAsync.when(
        loading: () => _ExamPlannerShimmer(),
        error: (e, _) => _NoPlanView(),
        data: (plan) => plan == null
            ? _NoPlanView()
            : TabBarView(
                controller: _tab,
                children: [
                  _StudyPlanTab(plan: plan),
                  _TopicsTab(subjects: plan.subjects),
                  _ProgressTab(plan: plan),
                ],
              ),
      ),
      floatingActionButton: planAsync.valueOrNull == null
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/exam-planner/setup'),
              backgroundColor: AppColors.primary,
              elevation: 2,
              icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
              label: const Text('Create AI Plan',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }
}

// ── Shimmer placeholder ───────────────────────────────────────────────────────
class _ExamPlannerShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(children: [
        const ShimmerCard(height: 60),
        const ShimmerCard(height: 60),
        const ShimmerCard(height: 60),
        const ShimmerCard(height: 60),
      ]),
    );
  }
}

// ── No Plan ───────────────────────────────────────────────────────────────────
class _NoPlanView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
                color: AppColors.primaryLight, borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.auto_awesome_rounded, size: 44, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text('No Exam Plan Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text(
            'Create a personalised AI study plan with daily tasks, topics and PYQs.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
          ),
        ]),
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
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Group tasks by day number, preserving their TRUE array index in generatedPlan.
    // Key = day number, Value = list of (arrayIndex, task) pairs.
    final byDay = <int, List<_IndexedTask>>{};
    for (int i = 0; i < plan.generatedPlan.length; i++) {
      final task = plan.generatedPlan[i];
      byDay.putIfAbsent(task.day, () => []).add(_IndexedTask(arrayIndex: i, task: task));
    }
    final days = byDay.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: days.length,
      itemBuilder: (ctx, i) {
        final day = days[i];
        final entries = byDay[day]!;
        final isToday = entries.any((e) => e.task.date == todayStr);
        final allDone = entries.every((e) => e.task.isCompleted);

        return _DaySection(
          day: day,
          entries: entries,
          isToday: isToday,
          allDone: allDone,
          planId: plan.id,
        );
      },
    );
  }
}

/// Bundles the true array index with the task so it's never lost when filtering.
class _IndexedTask {
  final int arrayIndex;
  final DailyTaskModel task;
  const _IndexedTask({required this.arrayIndex, required this.task});
}

class _DaySection extends ConsumerWidget {
  final int day;
  final List<_IndexedTask> entries;
  final bool isToday, allDone;
  final String planId;
  const _DaySection({
    required this.day,
    required this.entries,
    required this.isToday,
    required this.allDone,
    required this.planId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headerColor = isToday
        ? AppColors.primary
        : allDone
            ? AppColors.accentGreen
            : const Color(0xFFF0F0F5);
    final headerTextColor = (isToday || allDone) ? Colors.white : AppColors.textSecondary;
    final date = entries.first.task.date;
    final dateLabel = _fmtDate(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday
              ? AppColors.primary.withValues(alpha: 0.3)
              : const Color(0xFFE8E8E8),
        ),
        boxShadow: isToday
            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))]
            : [const BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Day header ─────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: headerColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: Row(children: [
            if (entries.first.task.isRevision)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(Icons.refresh_rounded, size: 13, color: headerTextColor),
              ),
            Text(
              'Day $day${entries.first.task.isRevision ? "  ·  Revision" : ""}',
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14, color: headerTextColor),
            ),
            const Spacer(),
            if (isToday)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6)),
                child: const Text('TODAY',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            if (isToday) const SizedBox(width: 8),
            Text(dateLabel,
                style: TextStyle(
                    fontSize: 11,
                    color: (isToday || allDone)
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppColors.textSecondary)),
          ]),
        ),
        // ── Task rows ──────────────────────────────────────
        ...entries.asMap().entries.map((entry) {
          final idx = entry.key;
          final it = entry.value;
          final isLast = idx == entries.length - 1;
          return _TaskRow(
            indexedTask: it,
            planId: planId,
            showDivider: !isLast,
          );
        }),
      ]),
    );
  }

  static String _fmtDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day} ${months[d.month - 1]}';
    } catch (_) { return iso; }
  }
}

class _TaskRow extends ConsumerWidget {
  final _IndexedTask indexedTask;
  final String planId;
  final bool showDivider;
  const _TaskRow({required this.indexedTask, required this.planId, required this.showDivider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = indexedTask.task;
    final arrayIndex = indexedTask.arrayIndex; // ← always the TRUE array position

    return Column(children: [
      InkWell(
        onTap: () => ref
            .read(examPlanNotifierProvider.notifier)
            .toggleTask(planId, arrayIndex, !task.isCompleted),
        borderRadius: showDivider
            ? BorderRadius.zero
            : const BorderRadius.vertical(bottom: Radius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: task.isCompleted ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: task.isCompleted ? AppColors.primary : const Color(0xFFD0D0D0),
                  width: 1.5,
                ),
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            // Task info
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(task.topic,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: task.isCompleted ? AppColors.textLight : AppColors.textPrimary,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null)),
              const SizedBox(height: 2),
              Text(task.subject,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ])),
            // Duration badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: task.isCompleted
                    ? AppColors.accentGreen.withValues(alpha: 0.1)
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${task.durationMinutes}m',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: task.isCompleted ? AppColors.accentGreen : AppColors.primary)),
            ),
          ]),
        ),
      ),
      if (showDivider)
        const Divider(height: 1, indent: 48, endIndent: 0, color: Color(0xFFF0F0F0)),
    ]);
  }
}

// ── Topics Tab ────────────────────────────────────────────────────────────────
class _TopicsTab extends StatelessWidget {
  final List<String> subjects;
  const _TopicsTab({required this.subjects});

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty) {
      return const Center(
        child: Text('No subjects in plan.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    const colors = AppColors.subjectColors;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: subjects.length,
      itemBuilder: (ctx, i) {
        final subject = subjects[i];
        final color = colors[i % colors.length];
        return GestureDetector(
          onTap: () => context.push('/exam-planner/subject-info', extra: subject),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.auto_awesome_rounded, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(subject,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const Text('Tap to view AI topics & PYQs',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ])),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textLight),
            ]),
          ),
        );
      },
    );
  }
}

// ── Progress Tab ──────────────────────────────────────────────────────────────
class _ProgressTab extends ConsumerWidget {
  final ExamPlanModel plan;
  const _ProgressTab({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = plan.generatedPlan.length;
    final done = plan.generatedPlan.where((t) => t.isCompleted).length;
    final pct = total > 0 ? done / total : 0.0;
    final daysLeft = plan.examDate.difference(DateTime.now()).inDays;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(children: [
        // ── Overall progress card ───────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: [
            const Text('Overall Progress',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 120, height: 120,
                child: CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 10,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(children: [
                Text('${(pct * 100).toInt()}%',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                const Text('done', style: TextStyle(color: Colors.white60, fontSize: 12)),
              ]),
            ]),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _ProgressChip(label: 'Completed', value: '$done', icon: Icons.check_circle_outline_rounded),
              _ProgressChip(label: 'Remaining', value: '${total - done}', icon: Icons.radio_button_unchecked_rounded),
              _ProgressChip(label: 'Days Left', value: daysLeft > 0 ? '$daysLeft' : '0', icon: Icons.event_rounded),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Per-subject bars ────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8E8E8)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Subject Progress',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 14),
            ...plan.subjects.asMap().entries.map((e) {
              final color = AppColors.subjectColors[e.key % AppColors.subjectColors.length];
              final subjectTasks = plan.generatedPlan.where((t) => t.subject == e.value).toList();
              final subjectDone = subjectTasks.where((t) => t.isCompleted).length;
              final subjectPct = subjectTasks.isEmpty ? 0.0 : subjectDone / subjectTasks.length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(e.value,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text('$subjectDone / ${subjectTasks.length}',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: subjectPct,
                      minHeight: 7,
                      backgroundColor: color.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ]),
              );
            }),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Exam date banner ────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: daysLeft <= 3 && daysLeft >= 0
                ? const Color(0xFFFFF0F0)
                : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: daysLeft <= 3 && daysLeft >= 0
                  ? AppColors.accent.withValues(alpha: 0.4)
                  : AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(children: [
            Icon(
              Icons.event_rounded,
              color: daysLeft <= 3 && daysLeft >= 0 ? AppColors.accent : AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                daysLeft > 0 ? '$daysLeft days until exam' : daysLeft == 0 ? 'Exam is today!' : 'Exam passed',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: daysLeft <= 3 && daysLeft >= 0 ? AppColors.accent : AppColors.primary),
              ),
              Text(_fmtExamDate(plan.examDate),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ])),
          ]),
        ),
      ]),
    );
  }

  static String _fmtExamDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const wds = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${wds[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _ProgressChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _ProgressChip({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Column(children: [
        Icon(icon, color: Colors.white60, size: 16),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ]);
}
