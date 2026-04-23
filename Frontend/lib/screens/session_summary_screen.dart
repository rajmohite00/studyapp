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

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Text('Session Complete! 🎉', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(subject, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatBox(label: 'Duration', value: '${mins}m', icon: Icons.timer_rounded, color: AppColors.primary),
                  _StatBox(label: 'Focus Score', value: '${focus.toInt()}', icon: Icons.bolt_rounded, color: AppColors.accentGreen),
                  _StatBox(label: 'Interruptions', value: '$interruptions', icon: Icons.notifications_off_outlined, color: AppColors.accentOrange),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _focusColor(focus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(_focusIcon(focus), color: _focusColor(focus), size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_focusLabel(focus), style: TextStyle(color: _focusColor(focus), fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(_focusTip(focus, interruptions), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(text: 'Back to Home', onPressed: () => context.go('/home')),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.pushReplacement('/session/setup'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Start Another Session'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _focusColor(double f) => f >= 80 ? AppColors.accentGreen : f >= 60 ? AppColors.primary : f >= 40 ? AppColors.accentOrange : AppColors.accent;
  IconData _focusIcon(double f) => f >= 80 ? Icons.star_rounded : f >= 60 ? Icons.thumb_up_rounded : Icons.info_rounded;
  String _focusLabel(double f) => f >= 80 ? 'Excellent Focus!' : f >= 60 ? 'Good Focus' : f >= 40 ? 'Fair Focus' : 'Poor Focus';
  String _focusTip(double f, int i) => i == 0 ? 'Zero interruptions. Great discipline!' : 'You had $i interruption${i != 1 ? 's' : ''}. Try Do Not Disturb next time.';
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      );
}
