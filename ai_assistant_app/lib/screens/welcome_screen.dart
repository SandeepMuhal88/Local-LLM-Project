import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_provider.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import 'home_shell.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _nameCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late ConfettiController _confetti;
  late AnimationController _bgAnim;

  bool _showCelebration = false;
  bool _isLoading = false;
  String _greeting = '';

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
    _bgAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    _greeting = _getGreeting();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _bgAnim.dispose();
    _nameCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '🌅 Good Morning';
    if (hour < 17) return '☀️ Good Afternoon';
    if (hour < 20) return '🌆 Good Evening';
    return '🌙 Good Night';
  }

  Future<void> _onContinue() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _focusNode.requestFocus();
      return;
    }

    setState(() => _isLoading = true);
    _focusNode.unfocus();

    final provider = context.read<AppProvider>();
    await provider.setUserName(name);
    await StorageService.setNotFirstLaunch();
    await provider.createNewSession();

    setState(() {
      _showCelebration = true;
      _isLoading = false;
    });
    _confetti.play();

    await Future.delayed(const Duration(milliseconds: 3200));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, anim, __) => const HomeShell(),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppProvider>().isDarkMode;
    AppColors.init(isDark);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Stack(
        children: [
          // Animated background
          _AnimatedBg(controller: _bgAnim, isDark: isDark),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 60,
              maxBlastForce: 40,
              minBlastForce: 8,
              gravity: 0.15,
              colors: const [
                Color(0xFF7C6FFF),
                Color(0xFF00D9FF),
                Color(0xFF9D4EDD),
                Color(0xFFFFB830),
                Color(0xFFFF5670),
                Color(0xFF10D9A0),
              ],
              shouldLoop: false,
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: size.width < 600 ? 28 : size.width * 0.25,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // ── Logo ─────────────────────────────────────────────────
                  Center(
                    child: _buildLogo(),
                  ),

                  const SizedBox(height: 32),

                  // ── App name ─────────────────────────────────────────────
                  Center(
                    child: ShaderMask(
                      shaderCallback: (b) => LinearGradient(
                        colors: [AppColors.gradStart, AppColors.accentSecondary],
                      ).createShader(b),
                      child: Text(
                        'Rama AI',
                        style: GoogleFonts.inter(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
                  ),

                  const SizedBox(height: 8),

                  Center(
                    child: Text(
                      'Your intelligent offline companion',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                  ),

                  const SizedBox(height: 48),

                  // ── Welcome card ─────────────────────────────────────────
                  _WelcomeCard(
                    greeting: _greeting,
                    isDark: isDark,
                    nameCtrl: _nameCtrl,
                    focusNode: _focusNode,
                    onContinue: _onContinue,
                    isLoading: _isLoading,
                    showCelebration: _showCelebration,
                  ).animate().fadeIn(delay: 400.ms, duration: 700.ms)
                      .slideY(begin: 0.15, end: 0),

                  const SizedBox(height: 60),

                  // ── Feature pills ─────────────────────────────────────────
                  _FeaturePills(isDark: isDark)
                      .animate()
                      .fadeIn(delay: 700.ms, duration: 600.ms),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _bgAnim,
      builder: (_, __) {
        return Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.gradStart, AppColors.accentTertiary, AppColors.accentSecondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentPrimary.withValues(alpha: 0.4 + _bgAnim.value * 0.2),
                blurRadius: 30 + _bgAnim.value * 15,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 42),
        );
      },
    ).animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.05, 1.05),
          duration: 2.seconds,
          curve: Curves.easeInOut,
        );
  }
}

// ─── Welcome Card ─────────────────────────────────────────────────────────────
class _WelcomeCard extends StatelessWidget {
  final String greeting;
  final bool isDark;
  final TextEditingController nameCtrl;
  final FocusNode focusNode;
  final VoidCallback onContinue;
  final bool isLoading;
  final bool showCelebration;

  const _WelcomeCard({
    required this.greeting,
    required this.isDark,
    required this.nameCtrl,
    required this.focusNode,
    required this.onContinue,
    required this.isLoading,
    required this.showCelebration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.aiBubbleBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPrimary.withValues(alpha: 0.08),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text(
            '$greeting!',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'What should I call you?',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 24),

          // Name input
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.aiBubbleBorder),
            ),
            child: TextField(
              controller: nameCtrl,
              focusNode: focusNode,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Your name...',
                hintStyle: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 16,
                ),
                prefixIcon: Icon(Icons.person_outline_rounded,
                    color: AppColors.accentPrimary, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onSubmitted: (_) => onContinue(),
            ),
          ),

          const SizedBox(height: 20),

          // Continue button
          _ContinueButton(
            onTap: onContinue,
            isLoading: isLoading,
            showCelebration: showCelebration,
          ),
        ],
      ),
    );
  }
}

class _ContinueButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isLoading;
  final bool showCelebration;

  const _ContinueButton({
    required this.onTap,
    required this.isLoading,
    required this.showCelebration,
  });

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.showCelebration) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.celebration_rounded, color: AppColors.success, size: 22),
              const SizedBox(width: 10),
              Text(
                'Welcome! Launching Rama AI... 🚀',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ).animate().scale(duration: 300.ms, curve: Curves.elasticOut);
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: 150.ms,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.gradStart, AppColors.accentSecondary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: AppColors.accentPrimary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Let\'s Go',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 20),
                  ],
                ),
        ),
      ).animate(target: _pressed ? 1 : 0)
          .scale(begin: const Offset(1, 1), end: const Offset(0.97, 0.97),
              duration: 100.ms),
    );
  }
}

// ─── Feature Pills ────────────────────────────────────────────────────────────
class _FeaturePills extends StatelessWidget {
  final bool isDark;
  const _FeaturePills({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final features = [
      (Icons.offline_bolt_rounded, 'Fully Offline'),
      (Icons.history_rounded, 'Chat History'),
      (Icons.lock_rounded, '100% Private'),
      (Icons.speed_rounded, 'Fast & Responsive'),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: features.asMap().entries.map((e) {
        final delay = e.key * 100;
        final (icon, label) = e.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.aiBubbleBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: AppColors.accentSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(
              delay: Duration(milliseconds: 700 + delay),
              duration: 400.ms,
            );
      }).toList(),
    );
  }
}

// ─── Animated Background ──────────────────────────────────────────────────────
class _AnimatedBg extends StatelessWidget {
  final AnimationController controller;
  final bool isDark;
  const _AnimatedBg({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return Stack(
          children: [
            Positioned(
              top: -100 + (t * 40),
              left: -80 + (t * 30),
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentPrimary.withValues(alpha: isDark ? 0.06 : 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: 80 + (t * 50),
              right: -100 + (t * 30),
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentSecondary.withValues(alpha: isDark ? 0.04 : 0.04),
                ),
              ),
            ),
            Positioned(
              top: 200 + (t * 30),
              right: 20 + (t * 20),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentTertiary.withValues(alpha: isDark ? 0.035 : 0.03),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
