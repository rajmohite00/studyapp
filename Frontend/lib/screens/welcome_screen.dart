import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../widgets/animations.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background gradient blobs
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withValues(alpha: 0.18),
                  AppColors.primary.withValues(alpha: 0.0),
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.accentTeal.withValues(alpha: 0.15),
                  AppColors.accentTeal.withValues(alpha: 0.0),
                ]),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: FadeSlideIn(
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            gradient: AppColors.heroGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Study Coach',
                          style: GoogleFonts.outfit(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 100),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: AppColors.heroGradient,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome, color: Colors.white, size: 13),
                                const SizedBox(width: 6),
                                Text(
                                  'AI-POWERED LEARNING',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Headline - fixed to not overflow
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 150),
                          child: Text(
                            'Study\nSmarter.',
                            style: GoogleFonts.outfit(
                              color: AppColors.textPrimary,
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                              letterSpacing: -2.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Subtitle
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 200),
                          child: Text(
                            'Your personal AI coach, smart exam planning, and streak tracking to achieve your academic goals.',
                            style: GoogleFonts.outfit(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Feature pills
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 260),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _FeaturePill(icon: Icons.timer_rounded, label: 'Focus Timer', color: AppColors.primary),
                              _FeaturePill(icon: Icons.smart_toy_rounded, label: 'AI Coach', color: AppColors.accentGreen),
                              _FeaturePill(icon: Icons.calendar_today_rounded, label: 'Exam Planner', color: AppColors.accent),
                              _FeaturePill(icon: Icons.bar_chart_rounded, label: 'Analytics', color: AppColors.accentOrange),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom CTAs
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: FadeSlideIn(
                    delay: const Duration(milliseconds: 320),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppColors.heroGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () => context.push('/signup'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Get Started  →',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account?',
                              style: GoogleFonts.outfit(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/login'),
                              child: Text(
                                'Log in',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _FeaturePill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
