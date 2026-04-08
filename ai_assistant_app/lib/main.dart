import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'app_provider.dart';
import 'theme/app_theme.dart';
import 'services/storage_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Animate.restartOnHotReload = true;

  final provider = AppProvider();
  await provider.load();

  runApp(
    ChangeNotifierProvider.value(
      value: provider,
      child: const RamaAIApp(),
    ),
  );
}

class RamaAIApp extends StatelessWidget {
  const RamaAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    AppColors.init(provider.isDarkMode);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rama AI',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: _RootGate(provider: provider),
    );
  }
}

class _RootGate extends StatefulWidget {
  final AppProvider provider;
  const _RootGate({required this.provider});

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  late Future<bool> _firstLaunch;

  @override
  void initState() {
    super.initState();
    _firstLaunch = StorageService.isFirstLaunch();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _firstLaunch,
      builder: (context, snap) {
        if (!snap.hasData) {
          // Loading splash
          return Scaffold(
            backgroundColor: AppColors.bgBase,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.gradStart, AppColors.accentSecondary],
                      ),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 36),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1.1, 1.1),
                        duration: 1.seconds,
                      ),
                ],
              ),
            ),
          );
        }

        final isFirst = snap.data!;

        if (isFirst || widget.provider.userName.isEmpty) {
          return const WelcomeScreen();
        }
        return const HomeShell();
      },
    );
  }
}