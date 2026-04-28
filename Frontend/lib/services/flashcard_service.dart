import 'dart:convert';
import 'dio_client.dart';
import '../models/flashcard_model.dart';
import 'storage_service.dart';

class FlashcardService {
  final _dio = DioClient.instance;

  Future<void> syncOfflineReviews() async {
    try {
      final List offlineReviews = StorageService.get('offline_flashcard_reviews') ?? [];
      if (offlineReviews.isEmpty) return;

      for (var review in offlineReviews) {
        try {
          await _dio.post('/flashcards/${review['cardId']}/review', data: {'quality': review['quality']});
        } catch (_) {}
      }
      await StorageService.delete('offline_flashcard_reviews');
    } catch (_) {}
  }

  Future<List<Flashcard>> getDueFlashcards() async {
    try {
      // Try to sync any offline reviews before fetching new cards
      await syncOfflineReviews();

      final response = await _dio.get('/flashcards/due');
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        await StorageService.put('cached_flashcards', jsonEncode(data));
        return data.map((e) => Flashcard.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      final cachedStr = StorageService.get<String>('cached_flashcards');
      if (cachedStr != null) {
        final List data = jsonDecode(cachedStr);
        return data.map((e) => Flashcard.fromJson(e)).toList();
      }
      return [];
    }
  }

  Future<void> reviewFlashcard(String cardId, int quality) async {
    try {
      await _dio.post('/flashcards/$cardId/review', data: {'quality': quality});
    } catch (e) {
      // Save offline
      final List offlineReviews = StorageService.get('offline_flashcard_reviews') ?? [];
      offlineReviews.add({'cardId': cardId, 'quality': quality});
      await StorageService.put('offline_flashcard_reviews', offlineReviews);
    }
  }
}
