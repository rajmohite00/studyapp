import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/session_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/primary_button.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/animations.dart';
import '../app_theme.dart';

class SessionSetupScreen extends ConsumerStatefulWidget {
  const SessionSetupScreen({super.key});

  @override
  ConsumerState<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends ConsumerState<SessionSetupScreen> {
  final TextEditingController _subjectController = TextEditingController();
  String _subject = '';
  String _topic = '';
  String _mode = 'custom';
  int _durationMinutes = 25;
  String _goal = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(sessionProvider.notifier).startSession(
        subject: _subject,
        topic: _topic.isEmpty ? null : _topic,
        mode: _mode,
        durationMinutes: _durationMinutes,
        goal: _goal.isEmpty ? null : _goal,
      );
      if (mounted) context.pushReplacement('/session/active');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final subjects = user?.profile.subjects ?? [];
    final sessionState = ref.watch(sessionProvider);
    final hasActive = sessionState.status == SessionStatus.active || sessionState.status == SessionStatus.paused;

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: Text(
            hasActive ? 'Resume Session' : 'New Study Session',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          centerTitle: false,
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
            if (hasActive) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.timer_outlined, size: 48, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'You have an active session!',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Subject: ${sessionState.currentSession?.subject}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: 'Resume Session ▶',
                      onPressed: () => context.pushReplacement('/session/active'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => ref.read(sessionProvider.notifier).endSession(notes: 'Abandoned to start new'),
                      child: const Text('End current session and start new', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ] else ...[
              // ── Subject picker ───────────────────────────
              _FieldLabel(label: 'Subject', icon: Icons.book_outlined),
              const SizedBox(height: 12),
              TextField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  hintText: 'Enter or search subject name...',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                ),
                onChanged: (v) => setState(() => _subject = v.trim()),
              ),
              if (subjects.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: subjects.map((s) {
                    final selected = _subject.toLowerCase() == s.toLowerCase();
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _subject = s;
                          _subjectController.text = s;
                        });
                      },
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
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
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
            ],
          ),
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
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
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
  Widget build(BuildContext context) => PressButton(
        scaleDown: 0.95,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.heroGradient : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: selected
                ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))]
                : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withOpacity(0.25) : AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: selected ? Colors.white : AppColors.primary, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: selected ? Colors.white.withOpacity(0.8) : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
}
