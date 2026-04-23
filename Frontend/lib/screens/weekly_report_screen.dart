import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/analytics_provider.dart';
import '../app_theme.dart';

class WeeklyReportScreen extends ConsumerWidget {
  const WeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(weeklyReportProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Report')),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final totalMins = data['totalStudyMinutes'] ?? 0;
          final focus = data['avgFocusScore'] ?? 0;
          final suggestions = List<String>.from(data['aiSuggestions'] ?? []);
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text('Total Studied', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text('${totalMins ~/ 60}h ${totalMins % 60}m', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text('AI Coach Suggestions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...suggestions.map((s) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.2))),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.tips_and_updates_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(s, style: const TextStyle(height: 1.5))),
                    ],
                  ),
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}
