import 'dio_client.dart';
import '../models/flashcard_model.dart';

class FlashcardService {
  final _dio = DioClient.instance;

  Future<List<Flashcard>> getDueFlashcards() async {
    final response = await _dio.get('/flashcards/due');
    if (response.statusCode == 200) {
      final List data = response.data['data'] ?? [];
      return data.map((e) => Flashcard.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> reviewFlashcard(String cardId, int quality) async {
    await _dio.post('/flashcards/$cardId/review', data: {'quality': quality});
  }
}
