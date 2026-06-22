import 'dart:async';

import 'message.dart';
import '../services/chat_service.dart';

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

  /// Send [question] to the backend and stream the assistant reply.
  ///
  /// Returns a stream of incremental tokens/chunks from the backend so the
  /// UI can render progressive responses. When the stream completes the
  /// assistant message is appended to `messages`.
  Stream<String> askAndAppend(String question, {String? baseUrl}) {
    final service = ChatService(baseUrl: baseUrl ?? 'http://127.0.0.1:8000');

    // append user message immediately
    messages.add(Message(text: question, isUser: true));

    final controller = StreamController<String>();
    final buffer = StringBuffer();

    service.askStream(question).listen((chunk) {
      controller.add(chunk);
      buffer.write(chunk);
    }, onError: (e, st) {
      controller.addError(e, st);
      controller.close();
    }, onDone: () {
      final assistantText = buffer.toString();
      messages.add(Message(text: assistantText, isUser: false));
      controller.close();
    });

    return controller.stream;
  }
}
