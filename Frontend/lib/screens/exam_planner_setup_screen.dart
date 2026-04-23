import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app_theme.dart';
import '../providers/exam_plan_provider.dart';

// Common subjects list
const _kSubjects = [
  'Mathematics', 'Physics', 'Chemistry', 'Biology',
  'Computer Science', 'Economics', 'History', 'Geography',
  'English', 'Data Structures', 'Algorithms', 'Database Management',
  'Operating Systems', 'Organic Chemistry', 'Mechanics', 'Thermodynamics',
  'Calculus', 'Linear Algebra', 'Probability', 'Genetics',
];

class ExamPlannerSetupScreen extends ConsumerStatefulWidget {
  const ExamPlannerSetupScreen({super.key});
  @override
  ConsumerState<ExamPlannerSetupScreen> createState() => _SetupState();
}

class _SetupState extends ConsumerState<ExamPlannerSetupScreen> {
  final Set<String> _selected = {};
  final _customCtrl = TextEditingController();
  DateTime? _examDate;
  double _dailyHours = 4;
  int _step = 0; // 0 = subjects, 1 = date+hours
  bool _loading = false;

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  void _addCustom() {
    final val = _customCtrl.text.trim();
    if (val.isEmpty) return;
    setState(() {
      _selected.add(val);
      _customCtrl.clear();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _examDate = picked);
  }

  Future<void> _create() async {
    if (_selected.isEmpty || _examDate == null) return;
    setState(() => _loading = true);
    final err = await ref.read(examPlanNotifierProvider.notifier).createPlan(
      subjects: _selected.toList(),
      examDate: _examDate!,
      dailyStudyHours: _dailyHours,
    );
    setState(() => _loading = false);
    if (!mounted) return;
    if (err == null) {
      context.go('/exam-planner');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $err'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(_step == 0 ? 'Select Subjects' : 'Exam Details',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: _step == 1
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _step = 0))
            : null,
      ),
      body: Column(
        children: [
          // Step indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(children: [
              _StepDot(active: _step == 0, done: _step > 0, label: '1'),
              Expanded(child: Container(height: 2, color: _step > 0 ? AppColors.primary : AppColors.divider)),
              _StepDot(active: _step == 1, done: false, label: '2'),
            ]),
          ),
          Expanded(
            child: _step == 0 ? _SubjectStep(
              selected: _selected,
              customCtrl: _customCtrl,
              onToggle: (s) => setState(() => _selected.contains(s) ? _selected.remove(s) : _selected.add(s)),
              onAddCustom: _addCustom,
            ) : _DateStep(
              examDate: _examDate,
              dailyHours: _dailyHours,
              onPickDate: _pickDate,
              onHoursChanged: (v) => setState(() => _dailyHours = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: _loading ? null : () {
                if (_step == 0) {
                  if (_selected.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select at least one subject.')),
                    );
                    return;
                  }
                  setState(() => _step = 1);
                } else {
                  if (_examDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please pick your exam date.')),
                    );
                    return;
                  }
                  _create();
                }
              },
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_step == 0 ? 'Next →' : 'Generate Plan ✨'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool active, done;
  final String label;
  const _StepDot({required this.active, required this.done, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = (active || done) ? AppColors.primary : AppColors.divider;
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: done
          ? const Icon(Icons.check, color: Colors.white, size: 16)
          : Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}

// ── Step 1: Subject Selection ────────────────────────────────────────────────
class _SubjectStep extends StatelessWidget {
  final Set<String> selected;
  final TextEditingController customCtrl;
  final void Function(String) onToggle;
  final VoidCallback onAddCustom;

  const _SubjectStep({
    required this.selected,
    required this.customCtrl,
    required this.onToggle,
    required this.onAddCustom,
  });

  @override
  Widget build(BuildContext context) {
    final allSubjects = {..._kSubjects, ...selected}.toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose your exam subjects', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${selected.length} selected', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: allSubjects.map((s) {
              final isSel = selected.contains(s);
              return GestureDetector(
                onTap: () => onToggle(s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSel ? AppColors.primary : AppColors.divider),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (isSel) const Icon(Icons.check, size: 14, color: Colors.white),
                    if (isSel) const SizedBox(width: 4),
                    Text(s, style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      color: isSel ? Colors.white : AppColors.textPrimary,
                    )),
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text('Add custom subject', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: customCtrl,
                decoration: const InputDecoration(hintText: 'e.g. Fluid Mechanics'),
                onSubmitted: (_) => onAddCustom(),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: onAddCustom,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(56, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Step 2: Exam Date + Daily Hours ──────────────────────────────────────────
class _DateStep extends StatelessWidget {
  final DateTime? examDate;
  final double dailyHours;
  final VoidCallback onPickDate;
  final void Function(double) onHoursChanged;

  const _DateStep({
    required this.examDate,
    required this.dailyHours,
    required this.onPickDate,
    required this.onHoursChanged,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = examDate != null
        ? examDate!.difference(DateTime.now()).inDays
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Set your exam date', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onPickDate,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: examDate != null ? AppColors.primary : AppColors.divider, width: examDate != null ? 2 : 1),
              ),
              child: Row(children: [
                Icon(Icons.calendar_today_rounded,
                    color: examDate != null ? AppColors.primary : AppColors.textSecondary),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    examDate != null ? _fmtDate(examDate!) : 'Tap to pick date',
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600,
                      color: examDate != null ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                  if (daysLeft != null) ...[
                    const SizedBox(height: 4),
                    Text('$daysLeft days remaining', style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ])),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ]),
            ),
          ),
          const SizedBox(height: 32),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Daily study hours', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Text('${dailyHours.toInt()}h/day', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 8),
          Slider(
            value: dailyHours,
            min: 1, max: 10, divisions: 9,
            activeColor: AppColors.primary,
            label: '${dailyHours.toInt()} hours',
            onChanged: onHoursChanged,
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
            Text('1h (Light)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text('5h (Moderate)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text('10h (Intense)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
          if (examDate != null) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(children: [
                const Row(children: [
                  Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Text('Plan Summary', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ]),
                const SizedBox(height: 12),
                _SummaryRow(label: 'Exam in', value: '$daysLeft days'),
                _SummaryRow(label: 'Daily study', value: '${dailyHours.toInt()} hours'),
                _SummaryRow(label: 'Total study hours', value: '${(daysLeft! * dailyHours).toInt()} hours'),
                _SummaryRow(label: 'Revision days', value: '~${(daysLeft * 0.15).ceil()} days'),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const weekdays = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    ]),
  );
}
