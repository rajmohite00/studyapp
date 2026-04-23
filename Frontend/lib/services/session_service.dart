import 'dio_client.dart';
import '../models/session_model.dart';

class SessionService {
  final _dio = DioClient.instance;

  Future<SessionModel> startSession({
    required String subject,
    String? topic,
    String mode = 'custom',
    int plannedDurationMinutes = 25,
    String? goal,
  }) async {
    final res = await _dio.post('/sessions', data: {
      'subject': subject,
      if (topic != null) 'topic': topic,
      'mode': mode,
      'plannedDurationMinutes': plannedDurationMinutes,
      if (goal != null) 'goal': goal,
    });
    return SessionModel.fromJson(res.data['data']);
  }

  Future<SessionModel> updateSession(
    String id, {
    String? action,
    String? subject,
    int? interruptions,
    String? notes,
    int? rating,
    bool? goalCompleted,
  }) async {
    final res = await _dio.patch('/sessions/$id', data: {
      if (action != null) 'action': action,
      if (subject != null) 'subject': subject,
      if (interruptions != null) 'interruptions': interruptions,
      if (notes != null) 'notes': notes,
      if (rating != null) 'rating': rating,
      if (goalCompleted != null) 'goalCompleted': goalCompleted,
    });
    return SessionModel.fromJson(res.data['data']);
  }

  Future<Map<String, dynamic>> getSessions({
    String? subject,
    String? status,
    String? from,
    String? to,
    String? cursor,
    int limit = 20,
  }) async {
    final res = await _dio.get('/sessions', queryParameters: {
      if (subject != null) 'subject': subject,
      if (status != null) 'status': status,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (cursor != null) 'cursor': cursor,
      'limit': limit,
    });
    final data = res.data['data'] as List;
    return {
      'sessions': data.map((s) => SessionModel.fromJson(s)).toList(),
      'nextCursor': res.data['meta']?['nextCursor'],
      'hasMore': res.data['meta']?['hasMore'] ?? false,
    };
  }

  Future<SessionModel?> getActiveSession() async {
    final res = await _dio.get('/sessions/active');
    if (res.data['data'] == null) return null;
    return SessionModel.fromJson(res.data['data']);
  }

  Future<SessionModel> getSession(String id) async {
    final res = await _dio.get('/sessions/$id');
    return SessionModel.fromJson(res.data['data']);
  }

  Future<void> deleteSession(String id) => _dio.delete('/sessions/$id');
}
