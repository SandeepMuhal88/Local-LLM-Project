import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'screens/chat_screen.dart';
import 'theme/app_theme.dart';

void main() {
  Animate.restartOnHotReload = true;
  runApp(const NoNetAI());
}

class NoNetAI extends StatelessWidget {
  const NoNetAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NoNet AI',
      theme: AppTheme.dark,
      home: const ChatScreen(),
    );
  }
}