import 'package:ai_assistant_app/app_provider.dart';
import 'package:ai_assistant_app/screens/welcome_screen.dart';
import 'package:ai_assistant_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('premium onboarding presents its primary controls',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: MaterialApp(theme: AppTheme.light, home: const WelcomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Your Smart AI'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    expect(find.text('Voice'), findsOneWidget);
    expect(find.text('Refresh'), findsOneWidget);
  });
}
