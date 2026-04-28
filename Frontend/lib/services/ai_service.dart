import 'package:dio/dio.dart';
import 'dio_client.dart';
import '../models/chat_message_model.dart';
import '../models/quiz_model.dart';

class AiService {
  final _dio = DioClient.instance;

  Future<Map<String, dynamic>> chat({
    required String message,
    String? conversationId,
    String? subject,
  }) async {
    final res = await _dio.post('/ai/chat', data: {
      'message': message,
      if (conversationId != null) 'conversationId': conversationId,
      if (subject != null) 'subject': subject,
    });
    return res.data['data'];
  }

  Future<Map<String, dynamic>> uploadNotes({
    required String filePath,
    required String fileName,
    String? subject,
  }) async {
    final formData = FormData.fromMap({
      'note': await MultipartFile.fromFile(filePath, filename: fileName),
      if (subject != null) 'subject': subject,
    });
    final res = await DioClient.instance.post(
      '/ai/upload-notes',
      data: formData,
    );
    return res.data['data'];
  }

  Future<List<AiConversation>> getConversations() async {
    final res = await _dio.get('/ai/conversations');
    return (res.data['data'] as List).map((c) => AiConversation.fromJson(c)).toList();
  }

  Future<AiConversation> getConversation(String id) async {
    final res = await _dio.get('/ai/conversations/$id');
    return AiConversation.fromJson(res.data['data']);
  }

  Future<String> explain({required String concept, required String subject}) async {
    final res = await _dio.post('/ai/explain', data: {'concept': concept, 'subject': subject});
    return res.data['data']['explanation'];
  }

  Future<QuizModel> generateQuiz({
    required String subject,
    String? chapter,
    String? topic,
    String difficulty = 'intermediate',
    int count = 5,
  }) async {
    final res = await _dio.post('/ai/quiz', data: {
      'subject': subject,
      if (chapter != null) 'chapter': chapter,
      if (topic != null) 'topic': topic,
      'difficulty': difficulty,
      'count': count,
    });
    return QuizModel.fromJson(res.data['data']);
  }

  Future<QuizResult> submitQuiz(String quizId, List<String> answers) async {
    final res = await _dio.post('/ai/quiz/$quizId/submit', data: {'answers': answers});
    return QuizResult.fromJson(res.data['data']);
  }

  Future<String> getRecommendations() async {
    final res = await _dio.get('/ai/recommend');
    return res.data['data']['recommendations'];
  }

  Future<List<Map<String, dynamic>>> getWeakTopics() async {
    final res = await _dio.get('/ai/weak-topics');
    return List<Map<String, dynamic>>.from(res.data['data']);
  }
}
