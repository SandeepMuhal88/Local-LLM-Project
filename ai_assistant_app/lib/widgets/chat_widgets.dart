import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ─── Enhanced Typing Indicator ─────────────────────────────────────────────────
class EnhancedTypingIndicator extends StatelessWidget {
  const EnhancedTypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          // Avatar
          _AIAvatar(size: 30),
          const SizedBox(width: 12),

          // Bubble
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.aiBubble.withValues(alpha: 0.9),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(color: AppColors.glassBorder, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.gradStart, AppColors.gradEnd],
                        ),
                        shape: BoxShape.circle,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .fadeIn(delay: Duration(milliseconds: i * 200), duration: 300.ms)
                        .then()
                        .fadeOut(duration: 300.ms)
                        .moveY(begin: 0, end: -5, delay: Duration(milliseconds: i * 200), duration: 300.ms)
                        .then()
                        .moveY(begin: -5, end: 0, duration: 300.ms);
                  }),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),
          Text(
            'Thinking...',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.4, end: 1.0, duration: 1.seconds),
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
        gradient: LinearGradient(
          colors: [AppColors.gradStart, AppColors.gradMid, AppColors.gradEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gradStart.withValues(alpha: 0.4),
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
        gradient: LinearGradient(
          colors: [
            AppColors.accentPrimary.withValues(alpha: 0.8),
            AppColors.accentSecondary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.person_rounded,
        color: Colors.white,
        size: size * 0.58,
      ),
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────
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
  bool _liked = false;
  bool _disliked = false;

  void _copyText() {
    Clipboard.setData(ClipboardData(text: widget.text));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.isUser ? _buildUserMessage() : _buildAIMessage();
  }

  Widget _buildUserMessage() {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = screenWidth < 600 ? screenWidth * 0.78 : 520.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Action buttons (on hover/tap)
          AnimatedOpacity(
            opacity: _showActions ? 1.0 : 0.0,
            duration: 200.ms,
            child: Row(
              children: [
                _MiniActionBtn(
                  icon: Icons.edit_note_rounded,
                  tooltip: 'Edit',
                  onTap: () {
                    setState(() => _showActions = false);
                    widget.onEdit?.call(widget.text);
                  },
                ),
                const SizedBox(width: 4),
                _MiniActionBtn(
                  icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
                  tooltip: _copied ? 'Copied!' : 'Copy',
                  onTap: _copyText,
                  isSuccess: _copied,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),

          // User bubble
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
                  gradient: LinearGradient(
                    colors: [AppColors.gradStart, AppColors.accentSecondary],
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
                      color: AppColors.gradStart.withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  widget.text,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.55,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _UserAvatar(size: 30),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, curve: Curves.easeOut)
        .slideX(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }

  Widget _buildAIMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AIAvatar(size: 30),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI name badge
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (b) => LinearGradient(
                          colors: [AppColors.gradStart, AppColors.gradEnd],
                        ).createShader(b),
                        child: Text(
                          'Rama AI',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.accentPrimary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          'AI',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Message content (with markdown-style code detection)
                widget.text.isEmpty
                    ? Text(
                        '...',
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 15,
                          height: 1.65,
                        ),
                      )
                    : _buildRichText(widget.text),

                // Action bar
                const SizedBox(height: 10),
                if (widget.text.isNotEmpty)
                  _AIActionBar(
                    copied: _copied,
                    liked: _liked,
                    disliked: _disliked,
                    onCopy: _copyText,
                    onLike: () => setState(() {
                      _liked = !_liked;
                      if (_liked) _disliked = false;
                    }),
                    onDislike: () => setState(() {
                      _disliked = !_disliked;
                      if (_disliked) _liked = false;
                    }),
                    onShare: () {},
                    onRegenerate: () {},
                  ),

                const SizedBox(height: 4),
                Divider(color: AppColors.glassBorder, height: 1, thickness: 0.6),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms, curve: Curves.easeOut)
        .slideX(begin: -0.05, end: 0, duration: 350.ms, curve: Curves.easeOut);
  }

  Widget _buildRichText(String text) {
    // Simple code block detection
    if (text.contains('```')) {
      return _RichMessageContent(text: text);
    }
    return SelectableText(
      text,
      style: GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 15,
        height: 1.68,
      ),
    );
  }
}

// ─── Rich Message Content (code blocks) ──────────────────────────────────────
class _RichMessageContent extends StatelessWidget {
  final String text;
  const _RichMessageContent({required this.text});

  @override
  Widget build(BuildContext context) {
    final parts = _parseMessage(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts.map((part) {
        if (part['type'] == 'code') {
          return _CodeBlock(code: part['content']!, language: part['lang'] ?? '');
        }
        return SelectableText(
          part['content']!,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 15,
            height: 1.68,
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, String>> _parseMessage(String text) {
    final regex = RegExp(r'```(\w*)\n([\s\S]*?)```', multiLine: true);
    List<Map<String, String>> parts = [];
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        parts.add({'type': 'text', 'content': text.substring(lastEnd, match.start)});
      }
      parts.add({
        'type': 'code',
        'lang': match.group(1) ?? '',
        'content': match.group(2) ?? '',
      });
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      parts.add({'type': 'text', 'content': text.substring(lastEnd)});
    }

    return parts;
  }
}

// ─── Code Block ───────────────────────────────────────────────────────────────
class _CodeBlock extends StatefulWidget {
  final String code;
  final String language;
  const _CodeBlock({required this.code, required this.language});

  @override
  State<_CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<_CodeBlock> {
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    Future.delayed(2.seconds, () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with language + copy
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bgCard.withValues(alpha: 0.8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
            ),
            child: Row(
              children: [
                Icon(Icons.code_rounded, size: 14, color: AppColors.accentTertiary),
                const SizedBox(width: 6),
                Text(
                  widget.language.isEmpty ? 'Code' : widget.language.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentTertiary,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _copy,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _copied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 12,
                          color: _copied ? AppColors.success : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _copied ? 'Copied!' : 'Copy',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: _copied ? AppColors.success : AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Code content
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              widget.code.trimRight(),
              style: GoogleFonts.firaCode(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AI Action Bar ────────────────────────────────────────────────────────────
class _AIActionBar extends StatelessWidget {
  final bool copied;
  final bool liked;
  final bool disliked;
  final VoidCallback onCopy;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onShare;
  final VoidCallback onRegenerate;

  const _AIActionBar({
    required this.copied,
    required this.liked,
    required this.disliked,
    required this.onCopy,
    required this.onLike,
    required this.onDislike,
    required this.onShare,
    required this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MiniActionBtn(
          icon: copied ? Icons.check_rounded : Icons.copy_all_rounded,
          tooltip: copied ? 'Copied!' : 'Copy',
          onTap: onCopy,
          isSuccess: copied,
          small: true,
        ),
        const SizedBox(width: 2),
        _MiniActionBtn(
          icon: liked ? Icons.thumb_up_rounded : Icons.thumb_up_alt_outlined,
          tooltip: 'Good response',
          onTap: onLike,
          isSuccess: liked,
          small: true,
        ),
        const SizedBox(width: 2),
        _MiniActionBtn(
          icon: disliked ? Icons.thumb_down_rounded : Icons.thumb_down_alt_outlined,
          tooltip: 'Bad response',
          onTap: onDislike,
          small: true,
        ),
        const SizedBox(width: 2),
        _MiniActionBtn(
          icon: Icons.share_outlined,
          tooltip: 'Share',
          onTap: onShare,
          small: true,
        ),
        const SizedBox(width: 2),
        _MiniActionBtn(
          icon: Icons.refresh_rounded,
          tooltip: 'Regenerate',
          onTap: onRegenerate,
          small: true,
        ),
      ],
    );
  }
}

// ─── Mini Action Button ───────────────────────────────────────────────────────
class _MiniActionBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isSuccess;
  final bool small;

  const _MiniActionBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isSuccess = false,
    this.small = false,
  });

  @override
  State<_MiniActionBtn> createState() => _MiniActionBtnState();
}

class _MiniActionBtnState extends State<_MiniActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final size = widget.small ? 28.0 : 34.0;
    final iconSize = widget.small ? 14.0 : 16.0;

    return Tooltip(
      message: widget.tooltip,
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
                  ? widget.isSuccess
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.bgCard
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _hovered ? AppColors.glassBorder : Colors.transparent,
              ),
            ),
            child: Center(
              child: Icon(
                widget.icon,
                size: iconSize,
                color: widget.isSuccess ? AppColors.success : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty Chat Placeholder ───────────────────────────────────────────────────
class EmptyChatPlaceholder extends StatefulWidget {
  final String userName;
  final void Function(String)? onSuggestionTap;

  const EmptyChatPlaceholder({
    super.key,
    this.userName = '',
    this.onSuggestionTap,
  });

  @override
  State<EmptyChatPlaceholder> createState() => _EmptyChatPlaceholderState();
}

class _EmptyChatPlaceholderState extends State<EmptyChatPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _orbitController;
  int _selectedCategory = 0;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _orbitController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 20) return 'Good Evening';
    return 'Good Night';
  }

  final List<Map<String, dynamic>> _categories = [
    {
      'label': 'Create',
      'icon': Icons.draw_rounded,
      'color': Color(0xFF8B5CF6),
      'suggestions': [
        'Write a poem about the ocean',
        'Create a short story idea',
        'Draft an email to my team',
        'Write a product description',
      ],
    },
    {
      'label': 'Explore',
      'icon': Icons.explore_rounded,
      'color': Color(0xFF4A90D9),
      'suggestions': [
        'Explain quantum computing',
        'What is machine learning?',
        'How does the brain work?',
        'History of the internet',
      ],
    },
    {
      'label': 'Code',
      'icon': Icons.code_rounded,
      'color': Color(0xFF10B981),
      'suggestions': [
        'Write a Python web scraper',
        'Explain async/await in Dart',
        'Debug my JavaScript code',
        'Best practices for REST APIs',
      ],
    },
    {
      'label': 'Analyze',
      'icon': Icons.analytics_rounded,
      'color': Color(0xFFF59E0B),
      'suggestions': [
        'Summarize a document',
        'Compare two approaches',
        'Pros and cons of Flutter',
        'Analyze this data trend',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 24, vertical: 32),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // ── Animated Hero Logo ──────────────────────────────────────────
          _HeroLogo(controller: _orbitController),

          const SizedBox(height: 28),

          // ── Greeting ────────────────────────────────────────────────────
          if (widget.userName.isNotEmpty)
            Text(
              '${_getGreeting()}, ${widget.userName}! 👋',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms, duration: 600.ms),

          const SizedBox(height: 12),

          // ── Main headline ────────────────────────────────────────────────
          ShaderMask(
            shaderCallback: (b) => LinearGradient(
              colors: [AppColors.gradStart, AppColors.gradMid, AppColors.gradEnd],
            ).createShader(b),
            child: Text(
              'How can I help you today?',
              style: GoogleFonts.inter(
                fontSize: screenWidth < 400 ? 24 : 30,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.8,
              ),
              textAlign: TextAlign.center,
            ),
          )
              .animate()
              .fadeIn(delay: 150.ms, duration: 700.ms)
              .slideY(begin: 0.1, end: 0, duration: 700.ms),

          const SizedBox(height: 8),

          Text(
            'Your private AI assistant. All processing happens on your device.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 250.ms, duration: 600.ms),

          const SizedBox(height: 36),

          // ── Category Tabs ────────────────────────────────────────────────
          _CategoryTabs(
            categories: _categories,
            selected: _selectedCategory,
            onSelect: (i) => setState(() => _selectedCategory = i),
          ).animate().fadeIn(delay: 350.ms, duration: 600.ms),

          const SizedBox(height: 16),

          // ── Suggestion Grid ──────────────────────────────────────────────
          _SuggestionGrid(
            suggestions: (_categories[_selectedCategory]['suggestions'] as List<String>),
            color: _categories[_selectedCategory]['color'] as Color,
            icon: _categories[_selectedCategory]['icon'] as IconData,
            onTap: widget.onSuggestionTap,
          ),

          const SizedBox(height: 32),

          // ── Feature Pills ────────────────────────────────────────────────
          _FeaturePills(),
        ],
      ),
    );
  }
}

// ─── Hero Logo ────────────────────────────────────────────────────────────────
class _HeroLogo extends StatelessWidget {
  final AnimationController controller;
  const _HeroLogo({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer rotating ring
              Transform.rotate(
                angle: controller.value * 2 * 3.14159,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.transparent,
                    ),
                  ),
                  child: CustomPaint(
                    painter: _DashedCirclePainter(
                      color: AppColors.gradStart.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              // Inner pulsing gradient circle
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      AppColors.gradStart,
                      AppColors.gradMid,
                      AppColors.gradEnd,
                      AppColors.gradStart,
                    ],
                    startAngle: controller.value * 2 * 3.14159,
                    endAngle: controller.value * 2 * 3.14159 + 2 * 3.14159,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gradStart.withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
              ),
            ],
          );
        },
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.05, 1.05),
          duration: 2.seconds,
          curve: Curves.easeInOut,
        );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    const dashes = 12;
    const dashLen = 0.2;

    for (int i = 0; i < dashes; i++) {
      final start = i * (2 * 3.14159 / dashes);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        dashLen,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Category Tabs ────────────────────────────────────────────────────────────
class _CategoryTabs extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final int selected;
  final void Function(int) onSelect;

  const _CategoryTabs({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(categories.length, (i) {
        final cat = categories[i];
        final isSelected = i == selected;
        final color = cat['color'] as Color;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: 200.ms,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.15) : AppColors.bgCard,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: isSelected ? color.withValues(alpha: 0.5) : AppColors.glassBorder,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(cat['icon'] as IconData, size: 14, color: isSelected ? color : AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  cat['label'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? color : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─── Suggestion Grid ──────────────────────────────────────────────────────────
class _SuggestionGrid extends StatelessWidget {
  final List<String> suggestions;
  final Color color;
  final IconData icon;
  final void Function(String)? onTap;

  const _SuggestionGrid({
    required this.suggestions,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: suggestions.asMap().entries.map((entry) {
        final i = entry.key;
        final suggestion = entry.value;
        return _SuggestionCard(
          text: suggestion,
          icon: icon,
          color: color,
          delay: i * 80,
          onTap: () => onTap?.call(suggestion),
        );
      }).toList(),
    );
  }
}

class _SuggestionCard extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color color;
  final int delay;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.text,
    required this.icon,
    required this.color,
    this.delay = 0,
    required this.onTap,
  });

  @override
  State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: 180.ms,
          width: 190,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.1)
                : AppColors.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.4)
                  : AppColors.glassBorder,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.12),
                      blurRadius: 16,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, size: 17, color: widget.color),
              ),
              const SizedBox(height: 10),
              Text(
                widget.text,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: _hovered ? AppColors.textPrimary : AppColors.textSecondary,
                  height: 1.4,
                  fontWeight: _hovered ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: _hovered ? widget.color : AppColors.textMuted,
                  ),
                ],
              ),
            ],
          ),
        ).animate(target: _pressed ? 1 : 0).scale(
              begin: const Offset(1, 1),
              end: const Offset(0.96, 0.96),
              duration: 100.ms,
            ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: widget.delay + 400), duration: 400.ms)
        .slideY(begin: 0.15, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

// ─── Feature Pills ────────────────────────────────────────────────────────────
class _FeaturePills extends StatelessWidget {
  final List<Map<String, dynamic>> _features = const [
    {'icon': Icons.lock_outline_rounded, 'label': '100% Private', 'color': Color(0xFF10B981)},
    {'icon': Icons.offline_bolt_rounded, 'label': 'Works Offline', 'color': Color(0xFF4A90D9)},
    {'icon': Icons.speed_rounded, 'label': 'Fast Responses', 'color': Color(0xFF8B5CF6)},
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _features.asMap().entries.map((e) {
        final feat = e.value;
        final color = feat['color'] as Color;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(feat['icon'] as IconData, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                feat['label'] as String,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: e.key * 100 + 700), duration: 400.ms)
            .slideY(begin: 0.2, end: 0);
      }).toList(),
    );
  }
}

// ─── Legacy SendButton (kept for backward compatibility) ──────────────────────
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
          gradient: LinearGradient(
            colors: [AppColors.gradStart, AppColors.gradEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: AppColors.gradStart.withValues(alpha: 0.45),
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
      ).animate(target: _pressed ? 1 : 0).scale(
            begin: const Offset(1, 1),
            end: const Offset(0.88, 0.88),
            duration: 100.ms,
          ),
    );
  }
}
