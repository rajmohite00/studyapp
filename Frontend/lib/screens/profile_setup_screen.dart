import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app_theme.dart';
import '../widgets/primary_button.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  String _grade = '';
  String _targetExam = '';
  int _dailyGoal = 120;
  final List<String> _subjects = [];
  final _subjectCtrl = TextEditingController();

  final _grades = ['Grade 9', 'Grade 10', 'Grade 11', 'Grade 12', 'UG Year 1', 'UG Year 2', 'UG Year 3', 'UG Year 4', 'PG', 'Self-study'];
  final _exams = ['JEE', 'NEET', 'UPSC', 'GATE', 'SAT', 'CAT', 'CA', 'Other', 'None'];

  void _addSubject() {
    final s = _subjectCtrl.text.trim();
    if (s.isNotEmpty && !_subjects.contains(s)) {
      setState(() => _subjects.add(s));
      _subjectCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text('Set up your profile 🎓', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Help us personalize your experience', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              _SectionLabel('Grade / Year'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _grades.map((g) => _Chip(label: g, selected: _grade == g, onTap: () => setState(() => _grade = g))).toList(),
              ),
              const SizedBox(height: 24),
              _SectionLabel('Target Exam (Optional)'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _exams.map((e) => _Chip(label: e, selected: _targetExam == e, onTap: () => setState(() => _targetExam = e))).toList(),
              ),
              const SizedBox(height: 24),
              _SectionLabel('Subjects'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subjectCtrl,
                      decoration: const InputDecoration(hintText: 'e.g. Physics, Maths'),
                      onSubmitted: (_) => _addSubject(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(onPressed: _addSubject, icon: const Icon(Icons.add), style: IconButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white)),
                ],
              ),
              if (_subjects.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _subjects.map((s) => Chip(label: Text(s), onDeleted: () => setState(() => _subjects.remove(s)), backgroundColor: AppColors.primary.withOpacity(0.1))).toList(),
                ),
              ],
              const SizedBox(height: 24),
              _SectionLabel('Daily Study Goal'),
              Slider(
                value: _dailyGoal.toDouble(),
                min: 30,
                max: 600,
                divisions: 19,
                label: '${_dailyGoal ~/ 60}h ${_dailyGoal % 60}m',
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _dailyGoal = v.round()),
              ),
              Center(child: Text('${_dailyGoal ~/ 60}h ${_dailyGoal % 60}m per day', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Start Studying 🚀',
                onPressed: _subjects.isNotEmpty ? () => context.go('/home') : null,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
          ),
          child: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      );
}
