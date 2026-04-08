import 'message.dart';

class ChatSession {
  final String id;
  String title;
  final DateTime createdAt;
  List<Message> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.messages,
  });

  factory ChatSession.create() {
    final now = DateTime.now();
    return ChatSession(
      id: '${now.millisecondsSinceEpoch}',
      title: 'New Chat',
      createdAt: now,
      messages: [],
    );
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      messages: (json['messages'] as List<dynamic>)
          .map((m) => Message.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  String get subtitle {
    if (messages.isEmpty) return 'Empty chat';
    final last = messages.last;
    final txt = last.text.trim();
    return txt.length > 50 ? '${txt.substring(0, 50)}...' : txt;
  }
}
