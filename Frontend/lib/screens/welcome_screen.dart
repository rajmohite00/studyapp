import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top logo bar ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Text('StudyCoach',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
              ]),
            ),

            // ── Hero content ──────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.primary
                                .withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              size: 12, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text('AI-POWERED LEARNING',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  letterSpacing: 0.8)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Headline
                    const Text('Study\nSmarter.',
                        style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            height: 1.05,
                            letterSpacing: -1.5)),
                    const SizedBox(height: 18),

                    // Subtitle
                    const Text(
                        'Your personal AI study coach with smart exam planning, practice tests, and AI tutoring.',
                        style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.6)),
                    const SizedBox(height: 32),

                    // Feature pills — only current features
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _Pill(Icons.auto_awesome_rounded, 'AI Tutor',
                            AppColors.primary),
                        _Pill(Icons.calendar_today_rounded,
                            'Exam Planner', Color(0xFF059669)),
                        _Pill(Icons.quiz_rounded, 'Practice Tests',
                            Color(0xFFD97706)),
                        _Pill(Icons.smart_toy_rounded, 'AI Chat',
                            Color(0xFF0284C7)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom CTAs ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => context.push('/signup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Get Started',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?',
                        style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary)),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => context.push('/login'),
                      child: const Text('Log in',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Pill(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
