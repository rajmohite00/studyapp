import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/exam_plan_provider.dart';
import '../models/exam_plan_model.dart';
import '../app_theme.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});
  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(examPlanNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Planner',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, color: AppColors.textSecondary),
            onPressed: () => context.push('/exam-planner/setup'),
          ),
        ],
      ),
      body: planAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
        error: (_, __) => _EmptyPlanner(),
        data: (plan) => plan == null ? _EmptyPlanner() : _PlannerBody(plan: plan),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────
class _EmptyPlanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.calendar_today_rounded,
                color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 20),
          const Text('No Exam Plan Yet',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Create a personalized AI study plan to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => context.push('/exam-planner/setup'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                  color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
              child: const Text('+ Create Plan',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Planner body ───────────────────────────────────────────────────────────────
class _PlannerBody extends ConsumerStatefulWidget {
  final ExamPlanModel plan;
  const _PlannerBody({required this.plan});
  @override
  ConsumerState<_PlannerBody> createState() => _PlannerBodyState();
}

class _PlannerBodyState extends ConsumerState<_PlannerBody> {
  late DateTime _selectedDay = DateTime.now();
  late DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final tasksForDay = _getTasksForDay(_selectedDay);

    return Column(
      children: [
        // ── Month Calendar ─────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(children: [
            // Month header
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(_monthLabel(_focusedMonth),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Row(children: [
                _NavBtn(icon: Icons.chevron_left_rounded, onTap: () {
                  setState(() => _focusedMonth =
                      DateTime(_focusedMonth.year, _focusedMonth.month - 1));
                }),
                const SizedBox(width: 4),
                _NavBtn(icon: Icons.chevron_right_rounded, onTap: () {
                  setState(() => _focusedMonth =
                      DateTime(_focusedMonth.year, _focusedMonth.month + 1));
                }),
              ]),
            ]),
            const SizedBox(height: 10),
            // Day-of-week headers
            Row(
              children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((d) {
                return Expanded(
                  child: Center(
                    child: Text(d,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            // Calendar grid
            ..._buildCalendarRows(),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),

        // ── Task list for selected day ──────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(_dayLabel(_selectedDay),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  if (tasksForDay.isNotEmpty)
                    Text('${tasksForDay.length} Tasks',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 14),
                if (tasksForDay.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No tasks for this day.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    ),
                  )
                else
                  ...tasksForDay.map((e) => _PlannerTaskCard(
                        task: e.value,
                        index: e.key,
                        planId: widget.plan.id,
                      )),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => context.push('/exam-planner/setup'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                        color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text('+ Add Task',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCalendarRows() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final startWeekday = firstDay.weekday % 7; // Sun=0
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;

    final rows = <Widget>[];
    var day = 1 - startWeekday;

    while (day <= daysInMonth) {
      final cells = <Widget>[];
      for (int wd = 0; wd < 7; wd++) {
        if (day < 1 || day > daysInMonth) {
          cells.add(const Expanded(child: SizedBox()));
        } else {
          final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
          final isSelected = _isSameDay(date, _selectedDay);
          final isToday = _isSameDay(date, DateTime.now());
          final hasTasks = _getTasksForDay(date).isNotEmpty;

          cells.add(Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedDay = date),
              child: Container(
                margin: const EdgeInsets.all(2),
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : isToday
                          ? AppColors.primaryLight
                          : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('$day',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                        )),
                    if (hasTasks && !isSelected)
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                            color: AppColors.primary, shape: BoxShape.circle),
                      ),
                  ]),
                ),
              ),
            ),
          ));
        }
        day++;
      }
      rows.add(Row(children: cells));
    }
    return rows;
  }

  List<MapEntry<int, DailyTaskModel>> _getTasksForDay(DateTime day) {
    final ds = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return widget.plan.generatedPlan
        .asMap()
        .entries
        .where((e) => e.value.date == ds)
        .toList();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthLabel(DateTime d) {
    const m = ['January','February','March','April','May','June',
        'July','August','September','October','November','December'];
    return '${m[d.month - 1]} ${d.year}';
  }

  String _dayLabel(DateTime d) {
    const wds = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    const ms = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${wds[d.weekday - 1]}, ${d.day} ${ms[d.month - 1]}';
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}

// ── Planner Task Card ──────────────────────────────────────────────────────────
class _PlannerTaskCard extends ConsumerWidget {
  final DailyTaskModel task;
  final int index;
  final String planId;
  const _PlannerTaskCard(
      {required this.task, required this.index, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => ref
              .read(examPlanNotifierProvider.notifier)
              .toggleTask(planId, index, !task.isCompleted),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: task.isCompleted ? AppColors.primary : Colors.transparent,
              border: Border.all(
                  color: task.isCompleted ? AppColors.primary : AppColors.textLight,
                  width: 1.5),
              borderRadius: BorderRadius.circular(5),
            ),
            child: task.isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(task.topic,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: task.isCompleted ? AppColors.textLight : AppColors.textPrimary,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null)),
            const SizedBox(height: 2),
            Text('${task.durationMinutes} min  ·  ${task.subject}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ),
      ]),
    );
  }
}
