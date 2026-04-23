import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app_theme.dart';
import '../widgets/primary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Hero illustration
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accentGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.school_rounded, size: 64, color: Colors.white),
              ),
              const SizedBox(height: 36),

              // Headline
              const Text(
                'Study Smarter\nWith AI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  letterSpacing: -1,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              const Text(
                'Track sessions, beat streaks, and get\npersonalized AI coaching — all in one place.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 40),

              // Feature pills
              Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: const [
                  _FeaturePill(icon: Icons.timer_rounded, label: 'Study Timer'),
                  _FeaturePill(icon: Icons.smart_toy_rounded, label: 'AI Coach'),
                  _FeaturePill(icon: Icons.bar_chart_rounded, label: 'Analytics'),
                  _FeaturePill(icon: Icons.calendar_today_rounded, label: 'Exam Planner'),
                ],
              ),

              const Spacer(flex: 3),

              // Primary CTA
              PrimaryButton(
                text: 'Get Started',
                onPressed: () => context.push('/signup'),
              ),
              const SizedBox(height: 12),

              // Secondary CTA
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => context.push('/login'),
                  child: const Text(
                    'Already have an account? Log in',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      );
}
