import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app_theme.dart';
import '../widgets/primary_button.dart';

class SessionSummaryScreen extends StatelessWidget {
  final Map<String, dynamic> session;
  const SessionSummaryScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final subject = session['subject'] ?? '';
    final mins = session['actualDurationMinutes'] ?? 0;
    final focus = (session['focusScore'] ?? 0).toDouble();
    final interruptions = session['interruptions'] ?? 0;
    final focusColor = _focusColor(focus);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            children: [
              // ── Badge / icon ──────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: focusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: focusColor.withOpacity(0.3), width: 2),
                ),
                child: Icon(_focusIcon(focus), color: focusColor, size: 36),
              ),
              const SizedBox(height: 20),
              const Text(
                'Session Complete! 🎉',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                subject,
                style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),

              // ── Stats row ─────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatBox(label: 'Duration', value: '${mins}m', icon: Icons.timer_rounded, color: AppColors.primary),
                    _Divider(),
                    _StatBox(label: 'Focus', value: '${focus.toInt()}', icon: Icons.bolt_rounded, color: AppColors.accentGreen),
                    _Divider(),
                    _StatBox(label: 'Breaks', value: '$interruptions', icon: Icons.notifications_off_outlined, color: AppColors.accentOrange),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Focus feedback card ────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: focusColor.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: focusColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _focusLabel(focus),
                      style: TextStyle(color: focusColor, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _focusTip(focus, interruptions),
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── Actions ───────────────────────────────
              PrimaryButton(text: 'Back to Home', onPressed: () => context.go('/home')),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.pushReplacement('/session/setup'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: AppColors.divider, width: 1.5),
                    foregroundColor: AppColors.textPrimary,
                  ),
                  child: const Text('Start Another Session', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _focusColor(double f) => f >= 80
      ? AppColors.accentGreen
      : f >= 60
          ? AppColors.primary
          : f >= 40
              ? AppColors.accentOrange
              : const Color(0xFFE07A5F);

  IconData _focusIcon(double f) => f >= 80
      ? Icons.star_rounded
      : f >= 60
          ? Icons.thumb_up_rounded
          : Icons.info_rounded;

  String _focusLabel(double f) => f >= 80
      ? 'Excellent Focus! ⭐'
      : f >= 60
          ? 'Good Focus 👍'
          : f >= 40
              ? 'Fair Focus'
              : 'Poor Focus — keep going!';

  String _focusTip(double f, int i) => i == 0
      ? 'Zero interruptions — incredible discipline! Keep it up.'
      : 'You had $i interruption${i != 1 ? 's' : ''}. Try enabling Do Not Disturb next time.';
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 40, color: AppColors.divider);
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      );
}
