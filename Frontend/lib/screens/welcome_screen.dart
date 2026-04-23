import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app_theme.dart';
import '../widgets/primary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.textPrimary, // Black safe area top
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP BAR (Black) ──────────────────────────────────
            Container(
              color: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'STUDY COACH',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/login'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.white),
                        boxShadow: const [BoxShadow(color: Colors.grey, offset: Offset(3, 3))],
                      ),
                      child: const Text('Log in', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textPrimary)),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Container(
                color: AppColors.accent, // Pink bg
                width: double.infinity,
                child: CustomPaint(
                  painter: _GridPainter(),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary, // Yellow
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: AppColors.textPrimary, width: 3),
                          ),
                          child: const Text(
                            'THE ULTIMATE APP',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 1.5),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Big title
                        RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            style: TextStyle(fontFamily: 'Inter', color: Colors.white, height: 1.0),
                            children: [
                              TextSpan(text: 'Study\n', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, letterSpacing: -2)),
                              TextSpan(
                                text: 'Smarter.',
                                style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, letterSpacing: -2, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        // Underline decoration
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          width: 80,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Subtitle card
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.textPrimary, width: 3),
                          ),
                          child: const Text(
                            'AI coaching, streak tracking, and smart exam planning.\n\nJoin the study revolution.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: AppColors.textPrimary, height: 1.5, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Primary CTA
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => context.push('/signup'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.textPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: AppColors.textPrimary, width: 3),
                                ),
                                elevation: 0,
                              ).copyWith(
                                // Add Neo-brutalism shadow effect hack
                                shadowColor: MaterialStateProperty.all(AppColors.textPrimary),
                                elevation: MaterialStateProperty.all(6),
                              ),
                              child: const Text('Register Now  →', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Secondary CTA
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => context.push('/login'),
                              icon: const Icon(Icons.menu_book_rounded, size: 20),
                              label: const Text('Instructions'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: AppColors.textPrimary, width: 3),
                                ),
                                elevation: 0,
                              ).copyWith(
                                shadowColor: MaterialStateProperty.all(AppColors.textPrimary),
                                elevation: MaterialStateProperty.all(6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary.withOpacity(0.1)
      ..strokeWidth = 1.0;

    const step = 40.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


