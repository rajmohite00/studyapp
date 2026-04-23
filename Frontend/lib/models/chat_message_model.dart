class ChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime timestamp;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: json['role'] ?? 'user',
        content: json['content'] ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'])
            : DateTime.now(),
      );

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

class AiConversation {
  final String id;
  final String? subject;
  final List<ChatMessage> messages;
  final int tokensUsed;
  final DateTime createdAt;

  const AiConversation({
    required this.id,
    this.subject,
    required this.messages,
    this.tokensUsed = 0,
    required this.createdAt,
  });

  factory AiConversation.fromJson(Map<String, dynamic> json) => AiConversation(
        id: json['_id'] ?? json['id'] ?? '',
        subject: json['subject'],
        messages: (json['messages'] as List<dynamic>? ?? [])
            .map((m) => ChatMessage.fromJson(m))
            .toList(),
        tokensUsed: json['tokensUsed'] ?? 0,
        createdAt: DateTime.parse(json['createdAt']),
      );
}
