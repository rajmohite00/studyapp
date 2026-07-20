import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/exam_plan_provider.dart';
import '../models/exam_plan_model.dart';
import '../app_theme.dart';
import '../widgets/shimmer_box.dart';

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
      appBar: _buildAppBar(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/exam-planner/setup'),
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('New Plan',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: planAsync.when(
        loading: () => _buildShimmer(),
        error: (_, __) => _buildEmpty(context),
        data: (plan) => plan == null ? _buildEmpty(context) : _PlannerBody(plan: plan),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    centerTitle: true,
    title: Text('Planner', style: GoogleFonts.outfit(
        fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    actions: [
      IconButton(
        icon: const Icon(Icons.tune_rounded, color: AppColors.textSecondary),
        onPressed: () => context.push('/exam-planner'),
      ),
    ],
    bottom: const PreferredSize(preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFF0F0F5))),
  );

  Widget _buildShimmer() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      ShimmerBox(height: 240, borderRadius: BorderRadius.circular(18)),
      const SizedBox(height: 16),
      ShimmerBox(height: 56, borderRadius: BorderRadius.circular(14)),
      const SizedBox(height: 8),
      const ShimmerCard(height: 72),
      const ShimmerCard(height: 72),
    ]),
  );

  Widget _buildEmpty(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(22)),
        child: const Icon(Icons.event_note_rounded, color: AppColors.primary, size: 38),
      ),
      const SizedBox(height: 20),
      Text('No Exam Plan Yet', style: GoogleFonts.outfit(fontSize: 18,
          fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const SizedBox(height: 6),
      Text('Build an AI-powered plan to get started',
          style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary),
          textAlign: TextAlign.center),
      const SizedBox(height: 24),
      GestureDetector(
        onTap: () => context.push('/exam-planner/setup'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(color: AppColors.primary,
              borderRadius: BorderRadius.circular(14)),
          child: Text('+ Create Plan', style: GoogleFonts.outfit(color: Colors.white,
              fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      ),
    ]),
  );
}

// ── Planner Body ──────────────────────────────────────────────────────────────
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
    final tasks = _getTasksForDay(_selectedDay);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Month Calendar ───────────────────────────────
        Container(
          decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12, offset: const Offset(0, 4))]),
          child: Column(children: [
            // Month header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(_monthLabel(_focusedMonth), style: GoogleFonts.outfit(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Row(children: [
                  _CalNavBtn(icon: Icons.chevron_left_rounded, onTap: () {
                    setState(() => _focusedMonth =
                        DateTime(_focusedMonth.year, _focusedMonth.month - 1));
                  }),
                  const SizedBox(width: 4),
                  _CalNavBtn(icon: Icons.chevron_right_rounded, onTap: () {
                    setState(() => _focusedMonth =
                        DateTime(_focusedMonth.year, _focusedMonth.month + 1));
                  }),
                ]),
              ]),
            ),
            // Day headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) => Expanded(
                  child: Center(child: Text(d, style: GoogleFonts.outfit(fontSize: 12,
                      fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                )).toList(),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
              child: Column(children: _buildCalendarRows()),
            ),
          ]),
        ),
        const SizedBox(height: 20),

        // ── Task section ─────────────────────────────────
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_dayLabel(_selectedDay), style: GoogleFonts.outfit(fontSize: 16,
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text('${tasks.length} task${tasks.length != 1 ? 's' : ''}',
                style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ]),
        const SizedBox(height: 14),

        if (tasks.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text('No tasks for this day',
                  style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14)),
            ),
          )
        else
          ...tasks.map((e) => _TaskCard(task: e.value, index: e.key, planId: widget.plan.id)),
      ]),
    );
  }

  List<Widget> _buildCalendarRows() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final startWd = firstDay.weekday % 7;
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final rows = <Widget>[];
    var day = 1 - startWd;

    while (day <= daysInMonth) {
      final cells = <Widget>[];
      for (int w = 0; w < 7; w++) {
        if (day < 1 || day > daysInMonth) {
          cells.add(const Expanded(child: SizedBox(height: 40)));
        } else {
          final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
          final isSel = _isSameDay(date, _selectedDay);
          final isToday = _isSameDay(date, DateTime.now());
          final hasTask = _getTasksForDay(date).isNotEmpty;
          cells.add(Expanded(child: GestureDetector(
            onTap: () => setState(() => _selectedDay = date),
            child: Container(
              height: 40,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSel ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('$day', style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: isSel || isToday ? FontWeight.w700 : FontWeight.w400,
                  color: isSel ? Colors.white : isToday ? AppColors.primary : AppColors.textPrimary,
                )),
                if (!isSel && (isToday || hasTask))
                  Container(width: 4, height: 4,
                    decoration: BoxDecoration(
                        color: isToday ? AppColors.primary : AppColors.accentGreen,
                        shape: BoxShape.circle)),
              ])),
            ),
          )));
        }
        day++;
      }
      rows.add(Row(children: cells));
    }
    return rows;
  }

  List<MapEntry<int, DailyTaskModel>> _getTasksForDay(DateTime day) {
    final ds = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return widget.plan.generatedPlan.asMap().entries.where((e) => e.value.date == ds).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthLabel(DateTime d) {
    const m = ['January','February','March','April','May','June',
        'July','August','September','October','November','December'];
    return '${m[d.month - 1]} ${d.year}';
  }

  String _dayLabel(DateTime d) {
    const wd = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    const ms = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${wd[d.weekday - 1]}, ${d.day} ${ms[d.month - 1]}';
  }
}

// ── Task Card ─────────────────────────────────────────────────────────────────
class _TaskCard extends ConsumerWidget {
  final DailyTaskModel task;
  final int index;
  final String planId;
  const _TaskCard({required this.task, required this.index, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(examPlanNotifierProvider).valueOrNull;
    final t = (live != null && index < live.generatedPlan.length) ? live.generatedPlan[index] : task;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: () => ref.read(examPlanNotifierProvider.notifier)
            .toggleTask(planId, index, !t.isCompleted),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: t.isCompleted ? AppColors.accentGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                    color: t.isCompleted ? AppColors.accentGreen : const Color(0xFFD0D0DC),
                    width: 1.5),
              ),
              child: t.isCompleted
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 15) : null,
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.topic, style: GoogleFonts.outfit(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: t.isCompleted ? AppColors.textLight : AppColors.textPrimary,
                decoration: t.isCompleted ? TextDecoration.lineThrough : null,
              )),
              const SizedBox(height: 3),
              Text('${t.subject}  ·  ${t.durationMinutes} min',
                  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: t.isCompleted
                    ? AppColors.accentGreen.withValues(alpha: 0.10) : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${t.durationMinutes}m', style: GoogleFonts.outfit(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: t.isCompleted ? AppColors.accentGreen : AppColors.primary,
              )),
            ),
          ]),
        ),
      ),
    );
  }
}

class _CalNavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CalNavBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30, height: 30,
      decoration: BoxDecoration(color: AppColors.surface,
          borderRadius: BorderRadius.circular(9)),
      child: Icon(icon, size: 20, color: AppColors.textSecondary),
    ),
  );
}
