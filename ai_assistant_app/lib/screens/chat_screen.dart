import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../app_provider.dart';
import '../models/message.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_widgets.dart';

class ChatScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const ChatScreen({super.key, required this.scaffoldKey});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isTyping = false;
  bool _hasText = false;

  List<PlatformFile> _attachedFiles = [];

  late AnimationController _bgAnimController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    _pulseController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ─── Send message ─────────────────────────────────────────────────────────
  Future<void> _sendMessage() async {
    final provider = context.read<AppProvider>();
    final session = provider.currentSession;
    if (session == null) return;

    final text = _controller.text.trim();
    if ((text.isEmpty && _attachedFiles.isEmpty) || _isTyping) return;

    HapticFeedback.lightImpact();

    String prompt = text;
    if (_attachedFiles.isNotEmpty) {
      final fileNames = _attachedFiles.map((f) => f.name).join(', ');
      prompt = text.isEmpty ? '[Files attached: $fileNames]' : '$text\n[Files: $fileNames]';
    }

    final userMsg = Message(text: prompt, isUser: true);
    session.messages.add(userMsg);

    if (session.messages.length == 1) {
      session.title = prompt.length > 40 ? '${prompt.substring(0, 40)}...' : prompt;
    }

    setState(() {
      _controller.clear();
      _hasText = false;
      _attachedFiles = [];
      _isTyping = true;
    });

    _scrollToBottom();

    final aiMsg = Message(text: '', isUser: false);
    session.messages.add(aiMsg);
    setState(() {});

    final int idx = session.messages.length - 1;
    String aiText = '';

    try {
      await for (final chunk in ApiService.streamMessage(prompt)) {
        aiText += chunk;
        session.messages[idx] = Message(text: aiText, isUser: false);
        setState(() {});
        _scrollToBottom();
      }
    } catch (e) {
      session.messages[idx] = Message(
        text: '⚠️ Connection error. Make sure the local server is running.',
        isUser: false,
      );
      setState(() {});
    }

    setState(() => _isTyping = false);
    await provider.updateCurrentSession();
  }

  void _editMessage(String originalText) {
    _controller.text = originalText;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: originalText.length),
    );
    _focusNode.requestFocus();
    Future.delayed(300.ms, _scrollToBottom);
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.pickFiles(allowMultiple: true, type: FileType.any);
      if (result != null && result.files.isNotEmpty) {
        setState(() => _attachedFiles = [..._attachedFiles, ...result.files]);
        HapticFeedback.lightImpact();
      }
    } catch (_) {}
  }

  void _removeFile(int index) => setState(() => _attachedFiles.removeAt(index));

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    AppColors.init(provider.isDarkMode);

    final mq = MediaQuery.of(context);
    final isTablet = mq.size.width >= 600;
    final messages = provider.currentSession?.messages ?? [];

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: _buildAppBar(context, provider),
      body: Stack(
        children: [
          // Animated ambient background
          _AmbientBackground(controller: _bgAnimController, isDark: provider.isDarkMode),

          SafeArea(
            top: false,
            child: Column(
              children: [
                // Message list
                Expanded(
                  child: messages.isEmpty
                      ? EmptyChatPlaceholder(
                          userName: provider.userName,
                          onSuggestionTap: (suggestion) {
                            _controller.text = suggestion;
                            setState(() => _hasText = true);
                          },
                        )
                      : _MessageListView(
                          messages: messages,
                          scrollController: _scrollController,
                          isTablet: isTablet,
                          provider: provider,
                          onEdit: _editMessage,
                        ),
                ),

                // Typing indicator with streaming effect
                AnimatedSwitcher(
                  duration: 300.ms,
                  child: _isTyping
                      ? const EnhancedTypingIndicator()
                      : const SizedBox.shrink(),
                ),

                // Input bar
                _EnhancedInputBar(
                  controller: _controller,
                  focusNode: _focusNode,
                  hasText: _hasText,
                  isLoading: _isTyping,
                  onSend: _sendMessage,
                  onAttach: _pickFiles,
                  isTablet: isTablet,
                  attachedFiles: _attachedFiles,
                  onRemoveFile: _removeFile,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AppProvider provider) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(68),
      child: Container(
        height: 68 + MediaQuery.of(context).padding.top,
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        decoration: BoxDecoration(
          color: AppColors.bgSurface.withValues(alpha: 0.9),
          border: Border(
            bottom: BorderSide(color: AppColors.glassBorder, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  // Drawer button
                  _AppBarButton(
                    icon: Icons.menu_rounded,
                    onTap: () => widget.scaffoldKey.currentState?.openDrawer(),
                    tooltip: 'Menu',
                  ),

                  // Animated logo
                  _AnimatedLogo(pulseController: _pulseController),
                  const SizedBox(width: 10),

                  // Title + status
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (_, __) {
                            return ShaderMask(
                              shaderCallback: (b) => LinearGradient(
                                colors: [
                                  AppColors.gradStart,
                                  AppColors.gradMid,
                                  AppColors.gradEnd,
                                ],
                                stops: [0.0, _pulseController.value * 0.7, 1.0],
                              ).createShader(b),
                              child: Text(
                                'Rama AI',
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            );
                          },
                        ),
                        Row(
                          children: [
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (_, __) => Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(right: 5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.success,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.success.withValues(
                                        alpha: 0.3 + 0.4 * _pulseController.value,
                                      ),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Text(
                              'Local model · Offline ready',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action buttons
                  _AppBarButton(
                    icon: Icons.tune_rounded,
                    onTap: () {},
                    tooltip: 'Settings',
                  ),
                  _AppBarButton(
                    icon: Icons.add_comment_rounded,
                    onTap: () async {
                      await provider.createNewSession();
                      setState(() {});
                    },
                    tooltip: 'New chat',
                    isAccent: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── App Bar Button ───────────────────────────────────────────────────────────
class _AppBarButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool isAccent;

  const _AppBarButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.isAccent = false,
  });

  @override
  State<_AppBarButton> createState() => _AppBarButtonState();
}

class _AppBarButtonState extends State<_AppBarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: 150.ms,
            width: 40,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isAccent && _hovered
                  ? AppColors.accentPrimary
                  : _hovered
                      ? AppColors.bgCard
                      : Colors.transparent,
              border: _hovered
                  ? Border.all(color: AppColors.glassBorder)
                  : null,
            ),
            child: Icon(
              widget.icon,
              size: 20,
              color: widget.isAccent
                  ? (_hovered ? Colors.white : AppColors.accentPrimary)
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Animated Logo ────────────────────────────────────────────────────────────
class _AnimatedLogo extends StatelessWidget {
  final AnimationController pulseController;
  const _AnimatedLogo({required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (_, __) {
        return Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.gradStart, AppColors.gradMid, AppColors.gradEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gradStart.withValues(
                  alpha: 0.2 + 0.3 * pulseController.value,
                ),
                blurRadius: 12 + 8 * pulseController.value,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
        );
      },
    );
  }
}

// ─── Ambient Background ───────────────────────────────────────────────────────
class _AmbientBackground extends StatelessWidget {
  final AnimationController controller;
  final bool isDark;
  const _AmbientBackground({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return Stack(
          children: [
            Positioned(
              top: -100 + t * 60,
              left: -80 + t * 40,
              child: _AmbientBlob(
                width: 320,
                height: 320,
                color: AppColors.gradStart.withValues(alpha: isDark ? 0.04 : 0.03),
              ),
            ),
            Positioned(
              top: size.height * 0.3 + t * 30,
              right: -100 + t * 50,
              child: _AmbientBlob(
                width: 280,
                height: 280,
                color: AppColors.gradMid.withValues(alpha: isDark ? 0.03 : 0.02),
              ),
            ),
            Positioned(
              bottom: 80 + t * 50,
              left: size.width * 0.2 + t * 20,
              child: _AmbientBlob(
                width: 240,
                height: 240,
                color: AppColors.gradEnd.withValues(alpha: isDark ? 0.035 : 0.025),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AmbientBlob extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const _AmbientBlob({required this.width, required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

// ─── Message List View ────────────────────────────────────────────────────────
class _MessageListView extends StatelessWidget {
  final List<Message> messages;
  final ScrollController scrollController;
  final bool isTablet;
  final AppProvider provider;
  final void Function(String) onEdit;

  const _MessageListView({
    required this.messages,
    required this.scrollController,
    required this.isTablet,
    required this.provider,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 48 : 0,
        vertical: 16,
      ),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final msg = messages[i];
        return MessageBubble(
          key: ValueKey('${provider.currentSession?.id}_$i'),
          text: msg.text,
          isUser: msg.isUser,
          animIndex: i,
          onEdit: msg.isUser ? onEdit : null,
        );
      },
    );
  }
}

// ─── Enhanced Input Bar ────────────────────────────────────────────────────────
class _EnhancedInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasText;
  final bool isLoading;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final bool isTablet;
  final List<PlatformFile> attachedFiles;
  final void Function(int) onRemoveFile;

  const _EnhancedInputBar({
    required this.controller,
    required this.focusNode,
    required this.hasText,
    required this.isLoading,
    required this.onSend,
    required this.onAttach,
    required this.isTablet,
    required this.attachedFiles,
    required this.onRemoveFile,
  });

  @override
  State<_EnhancedInputBar> createState() => _EnhancedInputBarState();
}

class _EnhancedInputBarState extends State<_EnhancedInputBar>
    with SingleTickerProviderStateMixin {
  bool _focused = false;
  late AnimationController _borderAnimController;

  @override
  void initState() {
    super.initState();
    _borderAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    widget.focusNode.addListener(() {
      setState(() => _focused = widget.focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _borderAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final hPad = widget.isTablet ? 60.0 : 16.0;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgInputBar.withValues(alpha: 0.95),
            border: Border(
              top: BorderSide(color: AppColors.glassBorder, width: 1),
            ),
          ),
          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 12 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Attached files chips
              if (widget.attachedFiles.isNotEmpty) ...[
                SizedBox(
                  height: 50,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.attachedFiles.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final file = widget.attachedFiles[i];
                      return _FileChip(
                        name: file.name,
                        onRemove: () => widget.onRemoveFile(i),
                      ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.2, end: 0);
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Main input container
              AnimatedBuilder(
                animation: _borderAnimController,
                builder: (_, child) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: _focused
                            ? _getAnimatedBorderColor()
                            : AppColors.glassBorder,
                        width: _focused ? 1.5 : 1,
                      ),
                      boxShadow: _focused
                          ? [
                              BoxShadow(
                                color: AppColors.accentPrimary.withValues(alpha: 0.12),
                                blurRadius: 24,
                                spreadRadius: 2,
                              )
                            ]
                          : [],
                    ),
                    child: child,
                  );
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Attach + camera
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: _InputActionGroup(onAttach: widget.onAttach),
                    ),

                    // Text field
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 160),
                        child: KeyboardListener(
                          focusNode: FocusNode(),
                          onKeyEvent: (event) {
                            if (event is KeyDownEvent &&
                                event.logicalKey == LogicalKeyboardKey.enter &&
                                !HardwareKeyboard.instance.isShiftPressed) {
                              widget.onSend();
                            }
                          },
                          child: TextField(
                            controller: widget.controller,
                            focusNode: widget.focusNode,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              height: 1.55,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Ask Rama AI anything...',
                              hintStyle: GoogleFonts.inter(
                                color: AppColors.textMuted,
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Right actions: mic + send
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, right: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!widget.hasText && !widget.isLoading)
                            _MicButton(),
                          const SizedBox(width: 4),
                          _SendOrStopButton(
                            hasText: widget.hasText,
                            isLoading: widget.isLoading,
                            hasFiles: widget.attachedFiles.isNotEmpty,
                            onSend: widget.onSend,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom hint
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline_rounded, size: 11, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'Enter to send · Shift+Enter for new line',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAnimatedBorderColor() {
    final t = _borderAnimController.value;
    final colors = [
      AppColors.gradStart,
      AppColors.gradMid,
      AppColors.gradEnd,
      AppColors.gradStart,
    ];
    final progress = t * (colors.length - 1);
    final idx = progress.floor().clamp(0, colors.length - 2);
    final blend = progress - idx;
    return Color.lerp(colors[idx], colors[idx + 1], blend)!;
  }
}

// ─── Input action group (attach + camera) ─────────────────────────────────────
class _InputActionGroup extends StatelessWidget {
  final VoidCallback onAttach;
  const _InputActionGroup({required this.onAttach});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SmallActionBtn(
          icon: Icons.attach_file_rounded,
          tooltip: 'Attach file',
          onTap: onAttach,
        ),
        _SmallActionBtn(
          icon: Icons.image_outlined,
          tooltip: 'Add image',
          onTap: () {},
        ),
      ],
    );
  }
}

class _SmallActionBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _SmallActionBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_SmallActionBtn> createState() => _SmallActionBtnState();
}

class _SmallActionBtnState extends State<_SmallActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: 150.ms,
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: _hovered
                  ? AppColors.accentPrimary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: _hovered ? AppColors.accentPrimary : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Mic Button ───────────────────────────────────────────────────────────────
class _MicButton extends StatefulWidget {
  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: 150.ms,
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hovered
                ? AppColors.accentSecondary.withValues(alpha: 0.15)
                : AppColors.bgCard,
            border: Border.all(
              color: _hovered
                  ? AppColors.accentSecondary.withValues(alpha: 0.4)
                  : AppColors.glassBorder,
            ),
          ),
          child: Icon(
            Icons.mic_rounded,
            size: 18,
            color: _hovered ? AppColors.accentSecondary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

// ─── Send / Stop Button ───────────────────────────────────────────────────────
class _SendOrStopButton extends StatefulWidget {
  final bool hasText;
  final bool isLoading;
  final bool hasFiles;
  final VoidCallback onSend;

  const _SendOrStopButton({
    required this.hasText,
    required this.isLoading,
    required this.hasFiles,
    required this.onSend,
  });

  @override
  State<_SendOrStopButton> createState() => _SendOrStopButtonState();
}

class _SendOrStopButtonState extends State<_SendOrStopButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_SendOrStopButton old) {
    super.didUpdateWidget(old);
    if (widget.isLoading && !old.isLoading) {
      _rotateController.repeat();
    } else if (!widget.isLoading && old.isLoading) {
      _rotateController.stop();
    }
  }

  bool get _canSend => widget.hasText || widget.hasFiles;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onSend();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: 180.ms,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: _canSend || widget.isLoading
              ? LinearGradient(
                  colors: [AppColors.gradStart, AppColors.gradEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: _canSend || widget.isLoading ? null : AppColors.bgSurface,
          border: Border.all(
            color: _canSend || widget.isLoading
                ? Colors.transparent
                : AppColors.glassBorder,
          ),
          boxShadow: (_canSend || widget.isLoading) && !_pressed
              ? [
                  BoxShadow(
                    color: AppColors.gradStart.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: widget.isLoading
            ? AnimatedBuilder(
                animation: _rotateController,
                builder: (_, __) => Transform.rotate(
                  angle: _rotateController.value * 2 * math.pi,
                  child: Icon(
                    Icons.stop_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              )
            : Icon(
                Icons.arrow_upward_rounded,
                color: _canSend ? Colors.white : AppColors.textMuted,
                size: 20,
              ),
      ).animate(target: _pressed ? 1 : 0).scale(
            begin: const Offset(1, 1),
            end: const Offset(0.88, 0.88),
            duration: 100.ms,
          ),
    );
  }
}

// ─── File Chip ─────────────────────────────────────────────────────────────────
class _FileChip extends StatelessWidget {
  final String name;
  final VoidCallback onRemove;
  const _FileChip({required this.name, required this.onRemove});

  IconData _iconForFile(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'webp':
        return Icons.image_rounded;
      case 'mp3':
      case 'wav':
        return Icons.audio_file_rounded;
      case 'mp4':
      case 'mov':
        return Icons.video_file_rounded;
      case 'py':
      case 'dart':
      case 'js':
      case 'ts':
        return Icons.code_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentTertiary.withValues(alpha: 0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconForFile(name), size: 15, color: AppColors.accentTertiary),
          const SizedBox(width: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withValues(alpha: 0.15),
              ),
              child: Icon(Icons.close_rounded, size: 11, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}