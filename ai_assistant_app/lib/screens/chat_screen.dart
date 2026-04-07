import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> messages = [];
  TextEditingController controller = TextEditingController();
  ScrollController scrollController = ScrollController();

  bool isTyping = false;

  // ================= SEND MESSAGE =================
  void sendMessage() async {
    String text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add(Message(text: text, isUser: true));
      controller.clear();
      isTyping = true;
    });

    _scrollToBottom();

    String aiText = "";

    setState(() {
      messages.add(Message(text: "", isUser: false));
    });

    int index = messages.length - 1;

    await for (var chunk in ApiService.streamMessage(text)) {
      aiText += chunk;

      setState(() {
        messages[index] = Message(text: aiText, isUser: false);
      });

      _scrollToBottom();
    }

    setState(() {
      isTyping = false;
    });
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("NoNet AI"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisAlignment: msg.isUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      Container(
                        constraints: BoxConstraints(maxWidth: 280),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: msg.isUser
                              ? Color(0xFF1E88E5)
                              : Color(0xFF2C2C2C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg.text,
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Typing indicator
          if (isTyping)
            Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  Text("AI is typing...",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),

          // Input Box
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: Color(0xFF1A1A1A),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Ask something...",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}