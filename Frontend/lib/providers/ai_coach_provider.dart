import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/chat_message_model.dart';
import '../services/ai_service.dart';

class AiCoachState {
  final List<ChatMessage> messages;
  final String? conversationId;
  final bool isLoading;
  final bool isUploading;
  final String? error;

  const AiCoachState({
    this.messages = const [],
    this.conversationId,
    this.isLoading = false,
    this.isUploading = false,
    this.error,
  });

  AiCoachState copyWith({
    List<ChatMessage>? messages,
    String? conversationId,
    bool? isLoading,
    bool? isUploading,
    String? error,
  }) =>
      AiCoachState(
        messages: messages ?? this.messages,
        conversationId: conversationId ?? this.conversationId,
        isLoading: isLoading ?? this.isLoading,
        isUploading: isUploading ?? this.isUploading,
        error: error,
      );
}

class AiCoachNotifier extends StateNotifier<AiCoachState> {
  final AiService _service;

  AiCoachNotifier(this._service) : super(const AiCoachState());

  Future<void> sendMessage(String message, {String? subject}) async {
    // Optimistically add user message
    final userMsg = ChatMessage(role: 'user', content: message, timestamp: DateTime.now());
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      final result = await _service.chat(
        message: message,
        conversationId: state.conversationId,
        subject: subject,
      );

      final aiMsg = ChatMessage(
        role: 'assistant',
        content: result['reply'] ?? '',
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        conversationId: result['conversationId'],
        isLoading: false,
      );
    } catch (e) {
      String errMsg = 'Failed to get response. Try again.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['error'] != null) {
          errMsg = data['error']['message'] ?? errMsg;
        }
      }
      state = state.copyWith(
        isLoading: false,
        error: errMsg,
      );
    }
  }

  void clearChat() {
    state = const AiCoachState();
  }

  Future<void> uploadNotes(String filePath, String fileName, {String? subject}) async {
    state = state.copyWith(isUploading: true, error: null);
    try {
      final result = await _service.uploadNotes(
        filePath: filePath,
        fileName: fileName,
        subject: subject,
      );
      // Start new conversation with the uploaded notes context
      final aiMsg = ChatMessage(
        role: 'assistant',
        content: result['reply'] ?? 'Notes uploaded! How can I help?',
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [aiMsg],
        conversationId: result['conversationId'],
        isUploading: false,
      );
    } catch (e) {
      String errMsg = 'Failed to process file. Please try again.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['error'] != null) {
          if (data['error'] is Map) {
            errMsg = data['error']['message'] ?? errMsg;
          } else {
            errMsg = data['error'].toString();
          }
        }
      }
      state = state.copyWith(
        isUploading: false,
        error: errMsg,
      );
    }
  }

  void loadConversation(AiConversation conversation) {
    state = AiCoachState(
      messages: conversation.messages,
      conversationId: conversation.id,
    );
  }
}

final aiServiceProvider = Provider((_) => AiService());

final aiCoachProvider = StateNotifierProvider<AiCoachNotifier, AiCoachState>(
  (ref) => AiCoachNotifier(ref.read(aiServiceProvider)),
);

final weakTopicsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.read(aiServiceProvider).getWeakTopics();
});
