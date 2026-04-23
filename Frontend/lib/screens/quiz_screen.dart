import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app_theme.dart';
import '../widgets/primary_button.dart';

class QuizScreen extends StatelessWidget {
  final Map<String, dynamic> quizData;
  const QuizScreen({super.key, required this.quizData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Quiz')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz_rounded, size: 64, color: AppColors.accentOrange),
            const SizedBox(height: 16),
            Text('Quiz for ${quizData['subject'] ?? 'Subject'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Quiz interaction flow goes here', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: PrimaryButton(text: 'End Quiz', onPressed: () => context.pop()),
            ),
          ],
        ),
      ),
    );
  }
}
