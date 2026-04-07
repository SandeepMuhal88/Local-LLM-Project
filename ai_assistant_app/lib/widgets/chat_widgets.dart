import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ─── Typing Indicator ─────────────────────────────────────────────────────────
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _AIAvatar(size: 28),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.aiBubble,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: AppColors.aiBubbleBorder, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.accentSecondary,
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .fadeIn(delay: Duration(milliseconds: i * 180), duration: 300.ms)
                    .then()
                    .fadeOut(duration: 300.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.2, 1.2),
                      delay: Duration(milliseconds: i * 180),
                      duration: 300.ms,
                    );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AI Avatar ────────────────────────────────────────────────────────────────
class _AIAvatar extends StatelessWidget {
  final double size;
  const _AIAvatar({this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.accentPrimary, AppColors.accentSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPrimary.withValues(alpha: 0.4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        Icons.auto_awesome,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}

// ─── User Avatar ──────────────────────────────────────────────────────────────
class _UserAvatar extends StatelessWidget {
  final double size;
  const _UserAvatar({this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.bgCard,
        border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Icon(
        Icons.person_rounded,
        color: AppColors.accentPrimary,
        size: size * 0.55,
      ),
    );
  }
}

// ─── Message Bubble (Gemini/ChatGPT style with Copy + Edit) ───────────────────
class MessageBubble extends StatefulWidget {
  final String text;
  final bool isUser;
  final int animIndex;
  final void Function(String)? onEdit;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.animIndex = 0,
    this.onEdit,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _showActions = false;
  bool _copied = false;

  void _copyText() {
    Clipboard.setData(ClipboardData(text: widget.text));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isUser) {
      return _buildUserMessage();
    } else {
      return _buildAIMessage();
    }
  }

  // ── User message (right-aligned, bubble style) ────────────────────────────
  Widget _buildUserMessage() {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = screenWidth < 600 ? screenWidth * 0.78 : 520.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Action buttons (appear on long-press)
              AnimatedOpacity(
                opacity: _showActions ? 1.0 : 0.0,
                duration: 200.ms,
                child: Row(
                  children: [
                    _ActionIconBtn(
                      icon: Icons.edit_rounded,
                      tooltip: 'Edit',
                      onTap: () {
                        setState(() => _showActions = false);
                        widget.onEdit?.call(widget.text);
                      },
                    ),
                    const SizedBox(width: 4),
                    _ActionIconBtn(
                      icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
                      tooltip: _copied ? 'Copied!' : 'Copy',
                      onTap: _copyText,
                      isSuccess: _copied,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              // Bubble
              GestureDetector(
                onLongPress: () => setState(() => _showActions = !_showActions),
                onTap: () {
                  if (_showActions) setState(() => _showActions = false);
                },
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3D35A8), Color(0xFF6C63FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentPrimary.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.55,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _UserAvatar(size: 30),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, curve: Curves.easeOut)
        .slideX(begin: 0.08, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }

  // ── AI message (left-aligned, flat style like Gemini) ────────────────────
  Widget _buildAIMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AIAvatar(size: 30),
              const SizedBox(width: 12),
              // Text takes full remaining width
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      widget.text.isEmpty ? '...' : widget.text,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.65,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Action row below text (always visible, subtle)
                    if (widget.text.isNotEmpty)
                      Row(
                        children: [
                          _ActionIconBtn(
                            icon: _copied ? Icons.check_rounded : Icons.copy_all_rounded,
                            tooltip: _copied ? 'Copied!' : 'Copy response',
                            onTap: _copyText,
                            isSuccess: _copied,
                            small: true,
                          ),
                          const SizedBox(width: 4),
                          _ActionIconBtn(
                            icon: Icons.thumb_up_alt_outlined,
                            tooltip: 'Good response',
                            onTap: () {},
                            small: true,
                          ),
                          const SizedBox(width: 4),
                          _ActionIconBtn(
                            icon: Icons.thumb_down_alt_outlined,
                            tooltip: 'Bad response',
                            onTap: () {},
                            small: true,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          // Bottom border separator (subtle, like Gemini)
          const SizedBox(height: 6),
          Container(
            height: 0.5,
            margin: const EdgeInsets.only(left: 42),
            color: AppColors.aiBubbleBorder.withValues(alpha: 0.4),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms, curve: Curves.easeOut)
        .slideX(begin: -0.06, end: 0, duration: 350.ms, curve: Curves.easeOut);
  }
}

// ─── Action Icon Button ───────────────────────────────────────────────────────
class _ActionIconBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isSuccess;
  final bool small;

  const _ActionIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isSuccess = false,
    this.small = false,
  });

  @override
  State<_ActionIconBtn> createState() => _ActionIconBtnState();
}

class _ActionIconBtnState extends State<_ActionIconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final size = widget.small ? 28.0 : 32.0;
    final iconSize = widget.small ? 14.0 : 16.0;

    return Tooltip(
      message: widget.tooltip,
      preferBelow: false,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 11,
        fontFamily: 'Inter',
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          child: AnimatedContainer(
            duration: 150.ms,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _hovered
                  ? AppColors.bgCard
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _hovered ? AppColors.aiBubbleBorder : Colors.transparent,
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                widget.icon,
                size: iconSize,
                color: widget.isSuccess
                    ? AppColors.success
                    : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Glowing Send Button ──────────────────────────────────────────────────────
class SendButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isLoading;

  const SendButton({super.key, required this.onTap, this.isLoading = false});

  @override
  State<SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<SendButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: 150.ms,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppColors.accentPrimary, AppColors.accentSecondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: AppColors.accentPrimary.withValues(alpha: 0.45),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
        ),
      )
          .animate(target: _pressed ? 1 : 0)
          .scale(begin: const Offset(1, 1), end: const Offset(0.88, 0.88), duration: 100.ms),
    );
  }
}

// ─── Animated gradient AppBar ─────────────────────────────────────────────────
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isOnline;
  final VoidCallback onMenuTap;

  const ChatAppBar({super.key, this.isOnline = true, required this.onMenuTap});

  @override
  Size get preferredSize => const Size.fromHeight(65);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65 + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(
          bottom: BorderSide(color: AppColors.aiBubbleBorder, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Logo with glow + shimmer
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.accentPrimary, AppColors.accentTertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentPrimary.withValues(alpha: 0.4),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .shimmer(duration: 2.5.seconds, color: AppColors.accentSecondary.withValues(alpha: 0.3)),
            const SizedBox(width: 12),
            // Title + status
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.accentPrimary, AppColors.accentSecondary],
                    ).createShader(bounds),
                    child: const Text(
                      'NoNet AI',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Inter',
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOnline ? AppColors.success : AppColors.error,
                          boxShadow: [
                            BoxShadow(
                              color: (isOnline ? AppColors.success : AppColors.error)
                                  .withValues(alpha: 0.6),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .fade(begin: 0.5, end: 1.0, duration: 1.2.seconds),
                      Text(
                        isOnline ? 'Local model · Online' : 'Offline',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // New chat button
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.add_comment_outlined, color: AppColors.textSecondary, size: 20),
              tooltip: 'New chat',
            ),
            // Menu button
            IconButton(
              onPressed: onMenuTap,
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty chat placeholder ───────────────────────────────────────────────────
class EmptyChatPlaceholder extends StatelessWidget {
  const EmptyChatPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated logo
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.accentPrimary, AppColors.accentTertiary, AppColors.accentSecondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentPrimary.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1.05, 1.05),
                  duration: 2.seconds,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 28),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.accentPrimary, AppColors.accentSecondary],
              ).createShader(bounds),
              child: Text(
                'How can I help you?',
                style: TextStyle(
                  fontSize: screenWidth < 400 ? 22 : 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'Inter',
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 600.ms)
                .slideY(begin: 0.1, end: 0, duration: 600.ms),
            const SizedBox(height: 8),
            Text(
              'Ask me anything. I run entirely on-device.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
            const SizedBox(height: 36),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _SuggestionChip(
                  icon: Icons.lightbulb_outline_rounded,
                  label: 'Explain quantum computing',
                  delay: 500,
                ),
                _SuggestionChip(
                  icon: Icons.code_rounded,
                  label: 'Write a Python script',
                  delay: 600,
                ),
                _SuggestionChip(
                  icon: Icons.translate_rounded,
                  label: 'Translate to Hindi',
                  delay: 700,
                ),
                _SuggestionChip(
                  icon: Icons.summarize_rounded,
                  label: 'Summarize a document',
                  delay: 800,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final int delay;

  const _SuggestionChip({
    required this.icon,
    required this.label,
    this.delay = 0,
  });

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: 180.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.bgCard : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: _hovered ? AppColors.accentPrimary.withValues(alpha: 0.5) : AppColors.aiBubbleBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 14, color: AppColors.accentSecondary),
            const SizedBox(width: 7),
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: widget.delay), duration: 400.ms)
        .slideY(begin: 0.2, end: 0, duration: 400.ms);
  }
}
