import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ChatService {
  final String baseUrl;

  ChatService({this.baseUrl = 'http://127.0.0.1:8000'});

  Stream<String> askStream(String question) async* {
    final uri = Uri.parse('$baseUrl/ask-stream');
    final client = http.Client();
    try {
      final request = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({'question': question});

      final response = await client.send(request);
      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        throw Exception('Request failed: ${response.statusCode} $body');
      }

      // Stream decoded UTF8 chunks
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        yield chunk;
      }
    } finally {
      client.close();
    }
  }
}
