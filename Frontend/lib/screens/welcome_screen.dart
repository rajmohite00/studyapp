import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app_theme.dart';
import '../widgets/primary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school_rounded, size: 64, color: AppColors.primary),
              ),
              const SizedBox(height: 32),
              const Text('Study Smarter\nWith AI', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.2)),
              const SizedBox(height: 16),
              const Text(
                'Track sessions, beat streaks, and get\npersonalized AI coaching — all in one place.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.6),
              ),
              const Spacer(),
              PrimaryButton(text: 'Get Started', onPressed: () => context.push('/signup')),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push('/login'),
                child: const Text('Already have an account? Log in',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
