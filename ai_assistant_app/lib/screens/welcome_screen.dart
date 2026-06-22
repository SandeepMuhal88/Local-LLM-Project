import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../app_provider.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _mascotController;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _mascotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _mascotController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    HapticFeedback.mediumImpact();
    final provider = context.read<AppProvider>();
    if (provider.userName.isEmpty) await provider.setUserName('Friend');
    if (provider.currentSession == null) await provider.createNewSession();
    await StorageService.setNotFirstLaunch();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  void _refreshMascot() {
    HapticFeedback.selectionClick();
    _mascotController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const _BrandPill(),
                          _RoundIcon(
                            icon: Icons.more_horiz_rounded,
                            label: 'More options',
                            onTap: () {},
                            size: 44,
                          ),
                        ],
                      ).animate().fadeIn(duration: 450.ms),
                      const Spacer(),
                      AnimatedBuilder(
                        animation: _mascotController,
                        builder: (context, child) => Transform.rotate(
                          angle:
                              math.sin(_mascotController.value * math.pi * 2) *
                                  .045,
                          child: Transform.scale(
                            scale: 1 +
                                math.sin(_mascotController.value * math.pi) *
                                    .04,
                            child: child,
                          ),
                        ),
                        child: Container(
                          width: 278,
                          height: 278,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0E9DD),
                            borderRadius: BorderRadius.circular(64),
                            boxShadow: AppShadows.card,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            'assets/images/ai_mascot.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const _MascotFallback(),
                          ),
                        ),
                      ).animate().fadeIn(delay: 120.ms, duration: 600.ms).scale(
                            begin: const Offset(.9, .9),
                            curve: Curves.easeOutBack,
                          ),
                      const SizedBox(height: 40),
                      Text(
                        'Your Smart AI\nAssistant Here',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ).animate().fadeIn(delay: 220.ms).slideY(begin: .08),
                      const SizedBox(height: 16),
                      const Text(
                        'Create, explore, and get things done\nwith a private intelligence by your side.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ).animate().fadeIn(delay: 320.ms),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: AppShadows.floating,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _Control(
                              icon: Icons.close_rounded,
                              label: 'Close',
                              onTap: _finish,
                            ),
                            _Control(
                              icon: _leaving
                                  ? Icons.more_horiz_rounded
                                  : Icons.mic_rounded,
                              label: _leaving ? 'Opening' : 'Voice',
                              onTap: _finish,
                              primary: true,
                            ),
                            _Control(
                              icon: Icons.refresh_rounded,
                              label: 'Refresh',
                              onTap: _refreshMascot,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 420.ms).slideY(begin: .18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandPill extends StatelessWidget {
  const _BrandPill();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0x4DFFFFFF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xB3FFFFFF)),
        ),
        child: const Row(children: [
          Icon(Icons.auto_awesome_rounded, size: 15),
          SizedBox(width: 7),
          Text('RAMA  /  PERSONAL AI',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1)),
        ]),
      );
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double size;
  const _RoundIcon(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.size = 52});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Material(
          color: AppColors.bgSurface,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
                width: size, height: size, child: Icon(icon, size: size * .42)),
          ),
        ),
      );
}

class _Control extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  const _Control(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.primary = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: 220.ms,
              width: primary ? 62 : 48,
              height: primary ? 62 : 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary ? AppColors.accentPrimary : AppColors.bgBase,
              ),
              child: Icon(icon,
                  color: primary ? Colors.white : AppColors.textPrimary,
                  size: primary ? 26 : 21),
            ),
            const SizedBox(height: 7),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary)),
          ],
        ),
      );
}

class _MascotFallback extends StatelessWidget {
  const _MascotFallback();

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
              width: 154,
              height: 128,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(48),
                  boxShadow: AppShadows.card)),
          Container(
            width: 112,
            height: 72,
            decoration: BoxDecoration(
                color: const Color(0xFF2A2927),
                borderRadius: BorderRadius.circular(32)),
            child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.circle, color: Color(0xFFD9B184), size: 16),
                  Icon(Icons.circle, color: Color(0xFFD9B184), size: 16),
                ]),
          ),
        ],
      );
}
