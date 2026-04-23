import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/session_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/primary_button.dart';
import '../app_theme.dart';

class SessionSetupScreen extends ConsumerStatefulWidget {
  const SessionSetupScreen({super.key});

  @override
  ConsumerState<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends ConsumerState<SessionSetupScreen> {
  String _subject = '';
  String _topic = '';
  String _mode = 'custom';
  int _durationMinutes = 25;
  String _goal = '';

  Future<void> _start() async {
    if (_subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a subject')));
      return;
    }
    await ref.read(sessionProvider.notifier).startSession(
      subject: _subject,
      topic: _topic.isEmpty ? null : _topic,
      mode: _mode,
      durationMinutes: _durationMinutes,
      goal: _goal.isEmpty ? null : _goal,
    );
    if (mounted) context.pushReplacement('/session/active', extra: {'subject': _subject});
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final subjects = user?.profile.subjects ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('New Study Session')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Subject', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: subjects.map((s) {
                final selected = _subject == s;
                return GestureDetector(
                  onTap: () => setState(() => _subject = s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
                    ),
                    child: Text(s, style: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w500)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: const InputDecoration(labelText: 'Topic (optional)', prefixIcon: Icon(Icons.book_outlined)),
              onChanged: (v) => setState(() => _topic = v),
            ),
            const SizedBox(height: 24),
            const Text('Timer Mode', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _ModeCard(label: 'Pomodoro', subtitle: '25/5 min', icon: Icons.timer_rounded, selected: _mode == 'pomodoro', onTap: () => setState(() { _mode = 'pomodoro'; _durationMinutes = 25; }))),
                const SizedBox(width: 12),
                Expanded(child: _ModeCard(label: 'Custom', subtitle: 'Set duration', icon: Icons.tune_rounded, selected: _mode == 'custom', onTap: () => setState(() => _mode = 'custom'))),
              ],
            ),
            if (_mode == 'custom') ...[
              const SizedBox(height: 20),
              Text('Duration: $_durationMinutes min', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Slider(
                value: _durationMinutes.toDouble(),
                min: 5, max: 180, divisions: 35,
                label: '$_durationMinutes min',
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _durationMinutes = v.round()),
              ),
            ],
            const SizedBox(height: 24),
            TextField(
              decoration: const InputDecoration(labelText: 'Session goal (optional)', hintText: 'e.g. Complete Chapter 5', prefixIcon: Icon(Icons.flag_outlined)),
              onChanged: (v) => setState(() => _goal = v),
            ),
            const SizedBox(height: 32),
            PrimaryButton(text: 'Start Session ▶', onPressed: _start),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String label, subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ModeCard({required this.label, required this.subtitle, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? AppColors.primary : AppColors.divider, width: selected ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 28),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? AppColors.primary : AppColors.textPrimary)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
}
