import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(NoNetAI());
}

class NoNetAI extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "NoNet AI",
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF0D0D0D),
      ),
      home: ChatScreen(),
    );
  }
}