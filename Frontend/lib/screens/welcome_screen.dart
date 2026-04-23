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
        child: Column(
          children: [
            // ── TOP BAR ──────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'STUDY COACH',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1.5),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/login'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.textPrimary, width: 2),
                      ),
                      child: const Text('Log In', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary)),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1.5, color: AppColors.divider),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ── HERO ───────────────────────────────────
                    Container(
                      width: double.infinity,
                      color: AppColors.primary.withOpacity(0.06),
                      padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
                      child: Column(
                        children: [
                          // Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              '✦  THE ULTIMATE STUDY APP',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.2),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Big title
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(fontFamily: 'Inter', color: AppColors.textPrimary, height: 1.1),
                              children: [
                                const TextSpan(text: 'Study\n', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -2)),
                                TextSpan(
                                  text: 'Smarter.',
                                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -2, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Subtitle card
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.divider, width: 1.5),
                            ),
                            child: const Text(
                              'AI coaching, streak tracking, and smart exam planning — all in one place.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Primary CTA
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => context.push('/signup'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: AppColors.primaryDark, width: 2),
                                ),
                                elevation: 0,
                              ),
                              child: const Text('Get Started  →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Secondary CTA
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => context.push('/login'),
                              icon: const Icon(Icons.login_rounded, size: 18),
                              label: const Text('Already have an account'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: AppColors.textPrimary, width: 2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── FEATURES (Floating icon cards) ─────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.star_rounded, size: 20, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          const Text('Key Features', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5)),
                        ],
                      ),
                    ),

                    ...[
                      _WelcomeFeatureCard(icon: Icons.timer_rounded, color: AppColors.primary, title: 'Smart Study Timer', desc: 'Pomodoro & custom sessions. Track focus scores, count interruptions, and build streaks.'),
                      _WelcomeFeatureCard(icon: Icons.smart_toy_rounded, color: AppColors.accentGreen, title: 'AI Study Coach', desc: 'Chat with your personal AI tutor. Get concept explanations and generate instant quizzes.'),
                      _WelcomeFeatureCard(icon: Icons.calendar_today_rounded, color: AppColors.accent, title: 'Exam Planner', desc: 'Enter your exam date and subjects — AI builds a full day-by-day revision plan with PYQs.'),
                      _WelcomeFeatureCard(icon: Icons.bar_chart_rounded, color: AppColors.accentOrange, title: 'Deep Analytics', desc: 'Heatmaps, burnout detection, focus prediction and subject-wise progress breakdowns.'),
                    ],

                    // ── STATS SECTION (sponsor-grid style) ─────────
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryDark, width: 2),
                      ),
                      child: Column(
                        children: [
                          const Text('Join thousands of students', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.3)),
                          const SizedBox(height: 6),
                          const Text('who improved their grades with Study Coach', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4)),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: _StatPill(value: '10K+', label: 'Students')),
                              const SizedBox(width: 12),
                              Expanded(child: _StatPill(value: '500K+', label: 'Sessions')),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _StatPill(value: '98%', label: 'Satisfaction')),
                              const SizedBox(width: 12),
                              Expanded(child: _StatPill(value: '4.9 ★', label: 'Rating')),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── FOOTER ─────────────────────────────────────
                    Container(
                      margin: const EdgeInsets.only(top: 32),
                      color: AppColors.textPrimary,
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          const Text('STUDY COACH', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
                          const SizedBox(height: 8),
                          const Text('Focus, plan, and execute.\nCrush your next exam.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5)),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _FooterIconBtn(icon: Icons.timer_rounded),
                              const SizedBox(width: 12),
                              _FooterIconBtn(icon: Icons.smart_toy_rounded),
                              const SizedBox(width: 12),
                              _FooterIconBtn(icon: Icons.bar_chart_rounded),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text('© 2026 STUDY COACH. ALL RIGHTS RESERVED.', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 0.5, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeFeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, desc;
  const _WelcomeFeatureCard({required this.icon, required this.color, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 28),
              padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.textPrimary, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 0, offset: const Offset(4, 4))],
              ),
              child: Column(
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text(desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
                ],
              ),
            ),
            Container(
              width: 58, height: 58,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.textPrimary, width: 2.5),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
          ],
        ),
      );
}

class _StatPill extends StatelessWidget {
  final String value, label;
  const _StatPill({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      );
}

class _FooterIconBtn extends StatelessWidget {
  final IconData icon;
  const _FooterIconBtn({required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      );
}
