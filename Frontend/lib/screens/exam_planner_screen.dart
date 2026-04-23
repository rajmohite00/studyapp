import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app_theme.dart';
import '../providers/exam_plan_provider.dart';
import '../models/exam_plan_model.dart';

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
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Exam Planner', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (planAsync.valueOrNull != null)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
              tooltip: 'New Plan',
              onPressed: () => context.push('/exam-planner/setup'),
            ),
        ],
        bottom: planAsync.valueOrNull != null
            ? TabBar(
                controller: _tab,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Study Plan'),
                  Tab(text: 'Topics & PYQ'),
                  Tab(text: 'Progress'),
                ],
              )
            : null,
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (plan) {
          if (plan == null) return _NoPlanView();
          return TabBarView(
            controller: _tab,
            children: [
              _StudyPlanTab(plan: plan),
              _TopicsPyqTab(topics: plan.importantTopics),
              _ProgressTab(plan: plan),
            ],
          );
        },
      ),
      floatingActionButton: planAsync.valueOrNull == null
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/exam-planner/setup'),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Create Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final byDay = <int, List<DailyTaskModel>>{};
    for (final t in plan.generatedPlan) {
      byDay.putIfAbsent(t.day, () => []).add(t);
    }
    final days = byDay.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: days.length,
      itemBuilder: (ctx, i) {
        final day = days[i];
        final tasks = byDay[day]!;
        final isToday = tasks.first.date == today;
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
  final List<DailyTaskModel> tasks;
  final bool isToday;
  final String planId;
  const _DayCard({required this.day, required this.tasks, required this.isToday, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allDone = tasks.every((t) => t.isCompleted);
    final date = tasks.first.date;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isToday ? Border.all(color: AppColors.primary, width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isToday ? AppColors.primary : (allDone ? AppColors.accentGreen : AppColors.surface),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  if (tasks.first.isRevision) const Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
                  if (tasks.first.isRevision) const SizedBox(width: 6),
                  Text(
                    'Day $day${tasks.first.isRevision ? " (Revision)" : ""}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: (isToday || allDone) ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ]),
                Row(children: [
                  if (isToday) Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                    child: const Text('TODAY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(date),
                    style: TextStyle(fontSize: 12, color: (isToday || allDone) ? Colors.white70 : AppColors.textSecondary),
                  ),
                ]),
              ],
            ),
          ),
          ...tasks.asMap().entries.map((entry) {
            final globalIdx = _findGlobalIndex(ref, entry.value, planId);
            return _TaskTile(
              task: entry.value,
              globalIndex: globalIdx,
              planId: planId,
            );
          }),
        ],
      ),
    );
  }

  int _findGlobalIndex(WidgetRef ref, DailyTaskModel task, String planId) {
    final plan = ref.read(examPlanNotifierProvider).valueOrNull;
    if (plan == null) return -1;
    return plan.generatedPlan.indexWhere(
      (t) => t.day == task.day && t.topic == task.topic && t.subject == task.subject,
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
    return ListTile(
      leading: Checkbox(
        value: task.isCompleted,
        activeColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        onChanged: globalIndex < 0 ? null : (val) {
          ref.read(examPlanNotifierProvider.notifier).toggleTask(planId, globalIndex, val ?? false);
        },
      ),
      title: Text(
        task.topic,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          color: task.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(task.subject, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('${task.durationMinutes}m', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Topics & PYQ Tab ─────────────────────────────────────────────────────────
class _TopicsPyqTab extends StatefulWidget {
  final List<ImportantTopicModel> topics;
  const _TopicsPyqTab({required this.topics});
  @override
  State<_TopicsPyqTab> createState() => _TopicsPyqTabState();
}

class _TopicsPyqTabState extends State<_TopicsPyqTab> {
  int? _expanded;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: widget.topics.length,
      itemBuilder: (ctx, i) {
        final topic = widget.topics[i];
        final isOpen = _expanded == i;
        return _TopicCard(
          topic: topic,
          isExpanded: isOpen,
          onTap: () => setState(() => _expanded = isOpen ? null : i),
        );
      },
    );
  }
}

class _TopicCard extends StatelessWidget {
  final ImportantTopicModel topic;
  final bool isExpanded;
  final VoidCallback onTap;
  const _TopicCard({required this.topic, required this.isExpanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final priority = topic.priority;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: priority.color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: priority.color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text(priority.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: priority.color)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(topic.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${topic.frequencyScore}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: priority.color)),
                      const Text('freq', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                ],
              ),
            ),
            if (isExpanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Previous Year Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    ...topic.pyqs.map((pyq) => _PYQTile(pyq: pyq)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PYQTile extends StatelessWidget {
  final PYQModel pyq;
  const _PYQTile({required this.pyq});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pyq.isHighlighted ? const Color(0xFFFFF9E6) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: pyq.isHighlighted ? Border.all(color: Colors.amber.withOpacity(0.5)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (pyq.isHighlighted) const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
            if (pyq.isHighlighted) const SizedBox(width: 4),
            if (pyq.year != null) Text('${pyq.year}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            const Spacer(),
            Row(children: List.generate(pyq.frequency, (_) => const Icon(Icons.circle, size: 6, color: AppColors.primary))),
          ]),
          const SizedBox(height: 6),
          Text(pyq.question, style: const TextStyle(fontSize: 13, height: 1.5)),
        ],
      ),
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
