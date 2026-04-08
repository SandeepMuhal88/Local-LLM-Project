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

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<Message> get _messages =>
      context.read<AppProvider>().currentSession?.messages ?? [];

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

    // Auto-title session from first user message
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
          _AnimatedBackground(controller: _bgAnimController, isDark: provider.isDarkMode),
          SafeArea(
            top: false,
            child: Column(
              children: [
                // Message list
                Expanded(
                  child: messages.isEmpty
                      ? EmptyChatPlaceholder(userName: provider.userName)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 40 : 0,
                            vertical: 12,
                          ),
                          itemCount: messages.length,
                          itemBuilder: (context, i) {
                            final msg = messages[i];
                            return MessageBubble(
                              key: ValueKey('${provider.currentSession?.id}_$i'),
                              text: msg.text,
                              isUser: msg.isUser,
                              animIndex: i,
                              onEdit: msg.isUser ? _editMessage : null,
                            );
                          },
                        ),
                ),

                // Typing indicator
                AnimatedSwitcher(
                  duration: 300.ms,
                  child: _isTyping
                      ? const TypingIndicator()
                      : const SizedBox.shrink(),
                ),

                // Input bar
                _InputBar(
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
      preferredSize: const Size.fromHeight(65),
      child: Container(
        height: 65 + MediaQuery.of(context).padding.top,
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          border: Border(
            bottom: BorderSide(color: AppColors.aiBubbleBorder, width: 1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              // Hamburger / drawer open
              IconButton(
                onPressed: () => widget.scaffoldKey.currentState?.openDrawer(),
                icon: Icon(Icons.menu_rounded, color: AppColors.textSecondary),
                tooltip: 'Menu',
              ),

              // Logo
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.gradStart, AppColors.accentTertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentPrimary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .shimmer(
                    duration: 2.5.seconds,
                    color: AppColors.accentSecondary.withValues(alpha: 0.3),
                  ),
              const SizedBox(width: 10),

              // Title
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (b) => LinearGradient(
                        colors: [AppColors.gradStart, AppColors.accentSecondary],
                      ).createShader(b),
                      child: Text(
                        'Rama AI',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withValues(alpha: 0.6),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .fade(begin: 0.4, end: 1.0, duration: 1.2.seconds),
                        Text(
                          'Local model · Offline',
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

              // New chat
              IconButton(
                onPressed: () async {
                  await provider.createNewSession();
                  setState(() {});
                },
                icon: Icon(Icons.add_comment_outlined, color: AppColors.textSecondary, size: 20),
                tooltip: 'New chat',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Animated Background ──────────────────────────────────────────────────────
class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;
  final bool isDark;
  const _AnimatedBackground({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return Stack(
          children: [
            Positioned(
              top: -80 + (t * 30),
              left: -60 + (t * 20),
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentPrimary.withValues(alpha: isDark ? 0.045 : 0.03),
                ),
              ),
            ),
            Positioned(
              bottom: 100 + (t * 40),
              right: -80 + (t * 20),
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentSecondary.withValues(alpha: isDark ? 0.035 : 0.025),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────
class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasText;
  final bool isLoading;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final bool isTablet;
  final List<PlatformFile> attachedFiles;
  final void Function(int) onRemoveFile;

  const _InputBar({
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
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      setState(() => _focused = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgInputBar,
        border: Border(
          top: BorderSide(color: AppColors.aiBubbleBorder, width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        widget.isTablet ? 60 : 16,
        10,
        widget.isTablet ? 60 : 16,
        10 + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attached files chips
          if (widget.attachedFiles.isNotEmpty) ...[
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.attachedFiles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final file = widget.attachedFiles[i];
                  return _FileChip(
                    name: file.name,
                    onRemove: () => widget.onRemoveFile(i),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Main input row
          AnimatedContainer(
            duration: 200.ms,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: _focused
                    ? AppColors.accentPrimary.withValues(alpha: 0.6)
                    : AppColors.aiBubbleBorder,
                width: _focused ? 1.5 : 1,
              ),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: AppColors.accentPrimary.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // File attach
                _AttachButton(onTap: widget.onAttach),

                // Text field
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 140),
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
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Message Rama AI...',
                          hintStyle: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Mic
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, right: 2),
                  child: IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.mic_none_rounded, color: AppColors.textMuted, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    tooltip: 'Voice input',
                  ),
                ),

                // Send button
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, right: 6),
                  child: AnimatedSwitcher(
                    duration: 200.ms,
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: (widget.hasText || widget.isLoading || widget.attachedFiles.isNotEmpty)
                        ? SendButton(
                            key: const ValueKey('send'),
                            onTap: widget.onSend,
                            isLoading: widget.isLoading,
                          )
                        : const SizedBox(
                            key: ValueKey('empty'),
                            width: 44,
                            height: 44,
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),
          Text(
            'Enter to send · Shift+Enter for new line',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Attach button ────────────────────────────────────────────────────────────
class _AttachButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AttachButton({required this.onTap});

  @override
  State<_AttachButton> createState() => _AttachButtonState();
}

class _AttachButtonState extends State<_AttachButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 6),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: 150.ms,
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _hovered
                  ? AppColors.accentPrimary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(Icons.attach_file_rounded, color: AppColors.textMuted, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── File chip ────────────────────────────────────────────────────────────────
class _FileChip extends StatelessWidget {
  final String name;
  final VoidCallback onRemove;
  const _FileChip({required this.name, required this.onRemove});

  IconData _iconForFile(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf': return Icons.picture_as_pdf_rounded;
      case 'png': case 'jpg': case 'jpeg': case 'webp': return Icons.image_rounded;
      case 'mp3': case 'wav': return Icons.audio_file_rounded;
      case 'mp4': case 'mov': return Icons.video_file_rounded;
      case 'py': case 'dart': case 'js': case 'ts': return Icons.code_rounded;
      default: return Icons.insert_drive_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.aiBubbleBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconForFile(name), size: 14, color: AppColors.accentSecondary),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}