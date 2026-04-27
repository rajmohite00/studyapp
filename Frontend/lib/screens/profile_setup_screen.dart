import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/primary_button.dart';
import '../widgets/loading_overlay.dart';

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

  final _grades = [
    'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12',
    'UG Year 1', 'UG Year 2', 'UG Year 3', 'UG Year 4',
    'PG', 'Self-study',
  ];
  final _exams = ['JEE', 'NEET', 'UPSC', 'GATE', 'SAT', 'CAT', 'CA', 'Other', 'None'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).user;
      if (user != null) {
        setState(() {
          _grade = user.profile.grade.isNotEmpty ? user.profile.grade : _grade;
          _targetExam = user.profile.targetExam.isNotEmpty ? user.profile.targetExam : _targetExam;
          _dailyGoal = user.profile.dailyGoalMinutes > 0 ? user.profile.dailyGoalMinutes : _dailyGoal;
          _subjects.addAll(user.profile.subjects);
        });
      }
    });
  }

  void _addSubject() {
    final s = _subjectCtrl.text.trim();
    if (s.isNotEmpty && !_subjects.contains(s)) {
      setState(() => _subjects.add(s));
      _subjectCtrl.clear();
    }
  }

  Future<void> _save() async {
    try {
      await ref.read(authStateProvider.notifier).updateProfile({
        'profile': {
          'grade': _grade,
          'targetExam': _targetExam,
          'dailyGoalMinutes': _dailyGoal,
          'subjects': _subjects,
        }
      });
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: const Color(0xFFE07A5F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return LoadingOverlay(
      isLoading: authState.isLoading,
      child: Scaffold(
        backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Setup Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Intro ─────────────────────────────────────
            const Text(
              'Set up your profile 🎓',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5),
            ),
            const SizedBox(height: 6),
            const Text(
              'Help us personalize your study experience',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 28),

            // ── Grade / Year ───────────────────────────────
            const _SectionLabel(label: 'Grade / Year', icon: Icons.school_outlined),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _grades.map((g) => _SelectChip(
                label: g,
                selected: _grade == g,
                onTap: () => setState(() => _grade = g),
              )).toList(),
            ),
            const SizedBox(height: 28),

            // ── Target Exam ────────────────────────────────
            const _SectionLabel(label: 'Target Exam', icon: Icons.flag_outlined),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _exams.map((e) => _SelectChip(
                label: e,
                selected: _targetExam == e,
                onTap: () => setState(() => _targetExam = e),
              )).toList(),
            ),
            const SizedBox(height: 28),

            // ── Subjects ───────────────────────────────────
            const _SectionLabel(label: 'Subjects', icon: Icons.book_outlined),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subjectCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Physics, Maths',
                      prefixIcon: Icon(Icons.add_circle_outline_rounded, size: 20),
                    ),
                    onSubmitted: (_) => _addSubject(),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    onPressed: _addSubject,
                    icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    tooltip: 'Add subject',
                  ),
                ),
              ],
            ),
            if (_subjects.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _subjects.map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s, style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _subjects.remove(s)),
                        child: const Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ],
            const SizedBox(height: 28),

            // ── Daily Goal ─────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionLabel(label: 'Daily Study Goal', icon: Icons.timer_outlined),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_dailyGoal ~/ 60}h ${_dailyGoal % 60}m',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.primary.withOpacity(0.12),
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withOpacity(0.1),
                trackHeight: 4,
              ),
              child: Slider(
                value: _dailyGoal.toDouble(),
                min: 30, max: 600, divisions: 19,
                label: '${_dailyGoal ~/ 60}h ${_dailyGoal % 60}m',
                onChanged: (v) => setState(() => _dailyGoal = v.round()),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('30 min', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                  Text('10 hrs', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // ── Save ───────────────────────────────────────
            PrimaryButton(
              text: authState.isLoading ? 'Saving...' : 'Start Studying 🚀',
              onPressed: !authState.isLoading ? _save : null,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ));
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      );
}

class _SelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SelectChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [BoxShadow(color: AppColors.primary.withOpacity(0.18), blurRadius: 8, offset: const Offset(0, 3))]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
}
