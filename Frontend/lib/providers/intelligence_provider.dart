import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/intelligence_service.dart';

final intelligenceServiceProvider = Provider((_) => IntelligenceService());

final burnoutProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(intelligenceServiceProvider).getBurnout();
});

final predictionProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(intelligenceServiceProvider).getPrediction();
});

final insightsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(intelligenceServiceProvider).getInsights();
});

final performanceProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(intelligenceServiceProvider).getPerformance();
});
