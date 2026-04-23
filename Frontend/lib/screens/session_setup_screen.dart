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
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('New Study Session'),
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
            // ── Subject picker ───────────────────────────
            _FieldLabel(label: 'Subject', icon: Icons.book_outlined),
            const SizedBox(height: 12),
            subjects.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
                    child: const Text('No subjects set up — go to Profile to add them.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: subjects.map((s) {
                      final selected = _subject == s;
                      return GestureDetector(
                        onTap: () => setState(() => _subject = s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: selected ? AppColors.primary : AppColors.divider,
                              width: selected ? 2 : 1,
                            ),
                            boxShadow: selected
                                ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))]
                                : [],
                          ),
                          child: Text(
                            s,
                            style: TextStyle(
                              color: selected ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 24),

            // ── Topic ───────────────────────────────────
            _FieldLabel(label: 'Topic', icon: Icons.label_outline_rounded),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Optional — e.g. Chapter 5: Thermodynamics',
                prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
              ),
              onChanged: (v) => setState(() => _topic = v),
            ),
            const SizedBox(height: 24),

            // ── Timer Mode ──────────────────────────────
            _FieldLabel(label: 'Timer Mode', icon: Icons.timer_outlined),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ModeCard(
                    label: 'Pomodoro',
                    subtitle: '25 min focus',
                    icon: Icons.timer_rounded,
                    selected: _mode == 'pomodoro',
                    onTap: () => setState(() { _mode = 'pomodoro'; _durationMinutes = 25; }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ModeCard(
                    label: 'Custom',
                    subtitle: 'Set your own',
                    icon: Icons.tune_rounded,
                    selected: _mode == 'custom',
                    onTap: () => setState(() => _mode = 'custom'),
                  ),
                ),
              ],
            ),

            // ── Duration slider (custom mode) ───────────
            if (_mode == 'custom') ...[
              const SizedBox(height: 24),
              _FieldLabel(label: 'Duration: $_durationMinutes min', icon: Icons.hourglass_empty_rounded),
              const SizedBox(height: 4),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.primary.withOpacity(0.15),
                  thumbColor: AppColors.primary,
                  overlayColor: AppColors.primary.withOpacity(0.1),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _durationMinutes.toDouble(),
                  min: 5, max: 180, divisions: 35,
                  label: '$_durationMinutes min',
                  onChanged: (v) => setState(() => _durationMinutes = v.round()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('5 min', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                    Text('3 hrs', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // ── Goal ────────────────────────────────────
            _FieldLabel(label: 'Session Goal', icon: Icons.flag_outlined),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Optional — e.g. Complete Chapter 5',
                prefixIcon: Icon(Icons.flag_rounded, size: 20),
              ),
              onChanged: (v) => setState(() => _goal = v),
            ),
            const SizedBox(height: 36),

            // ── Start button ────────────────────────────
            PrimaryButton(
              text: _subject.isEmpty ? 'Select a Subject to Start' : 'Start Session ▶',
              onPressed: _subject.isEmpty ? null : _start,
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _FieldLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      );
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withOpacity(0.07) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (selected ? AppColors.primary : AppColors.textLight).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 24),
              ),
              const SizedBox(height: 10),
              Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? AppColors.primary : AppColors.textPrimary, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
}
