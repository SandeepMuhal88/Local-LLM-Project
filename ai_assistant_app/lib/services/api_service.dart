import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000";

  // STREAM RESPONSE
  static Stream<String> streamMessage(String message) async* {
    final request = http.Request(
      "POST",
      Uri.parse("$baseUrl/ask-stream"),
    );

    request.headers["Content-Type"] = "application/json";
    request.body = jsonEncode({"question": message});

    final response = await request.send();

    await for (var chunk in response.stream.transform(utf8.decoder)) {
      yield chunk;
    }
  }

  // FILE UPLOAD
  static Future<void> uploadFile(List<int> bytes, String filename) async {
    var request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/upload"),
    );

    request.files.add(
      http.MultipartFile.fromBytes("file", bytes, filename: filename),
    );

    await request.send();
  }
}