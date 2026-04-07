import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/message.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> messages = [];
  TextEditingController controller = TextEditingController();

  SpeechToText speech = SpeechToText();

  // ================= SEND MESSAGE =================
  void sendMessage() async {
    String text = controller.text;
    if (text.isEmpty) return;

    setState(() {
      messages.add(Message(text: text, isUser: true));
      controller.clear();
      messages.add(Message(text: "", isUser: false));
    });

    int index = messages.length - 1;
    String aiText = "";

    await for (var chunk in ApiService.streamMessage(text)) {
      aiText += chunk;

      setState(() {
        messages[index] = Message(text: aiText, isUser: false);
      });
    }
  }

  // ================= VOICE =================
  void startListening() async {
    bool available = await speech.initialize();

    if (available) {
      speech.listen(onResult: (result) {
        controller.text = result.recognizedWords;
      });
    }
  }

  // ================= FILE UPLOAD =================
  void uploadFile() async {
    var result = await FilePicker.platform.pickFiles();

    if (result != null) {
      var file = result.files.first;
      await ApiService.uploadFile(file.bytes!, file.name);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("File Uploaded")),
      );
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("AI Assistant"),
        actions: [
          IconButton(
            icon: Icon(Icons.upload),
            onPressed: uploadFile,
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];

                return Align(
                  alignment: msg.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.all(8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg.isUser ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(msg.text),
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "Ask something...",
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.mic),
                onPressed: startListening,
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: sendMessage,
              )
            ],
          )
        ],
      ),
    );
  }
}