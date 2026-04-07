import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../models/message.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_widgets.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isTyping = false;
  bool _hasText = false;

  // Attached files
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
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
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

  // ─── Send message ──────────────────────────────────────────────────────────
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if ((text.isEmpty && _attachedFiles.isEmpty) || _isTyping) return;

    HapticFeedback.lightImpact();

    // Build prompt — include file names if any
    String prompt = text;
    if (_attachedFiles.isNotEmpty) {
      final fileNames = _attachedFiles.map((f) => f.name).join(', ');
      prompt = text.isEmpty
          ? '[Files attached: $fileNames]'
          : '$text\n[Files: $fileNames]';
    }

    setState(() {
      _messages.add(Message(text: prompt, isUser: true));
      _controller.clear();
      _hasText = false;
      _attachedFiles = [];
      _isTyping = true;
    });

    _scrollToBottom();

    String aiText = '';
    setState(() {
      _messages.add(Message(text: '', isUser: false));
    });

    final int idx = _messages.length - 1;

    try {
      await for (final chunk in ApiService.streamMessage(prompt)) {
        aiText += chunk;
        setState(() {
          _messages[idx] = Message(text: aiText, isUser: false);
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _messages[idx] = Message(
          text: '⚠️ Connection error. Make sure the local server is running.',
          isUser: false,
        );
      });
    }

    setState(() => _isTyping = false);
  }

  // ─── Edit user message ─────────────────────────────────────────────────────
  void _editMessage(String originalText) {
    _controller.text = originalText;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: originalText.length),
    );
    _focusNode.requestFocus();
    // Scroll to bottom so input is visible
    Future.delayed(300.ms, _scrollToBottom);
  }

  // ─── File picker ───────────────────────────────────────────────────────────
  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _attachedFiles = [
            ..._attachedFiles,
            ...result.files,
          ];
        });
        HapticFeedback.lightImpact();
      }
    } catch (_) {}
  }

  void _removeFile(int index) {
    setState(() => _attachedFiles.removeAt(index));
  }

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

  void _clearChat() {
    setState(() => _messages.clear());
    Navigator.of(context).pop();
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _OptionsSheet(onClear: _clearChat),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final isTablet = screenWidth >= 600;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      extendBodyBehindAppBar: false,
      appBar: ChatAppBar(
        isOnline: true,
        onMenuTap: () => _showMenu(context),
      ),
      body: Stack(
        children: [
          // Subtle animated BG gradient blob
          _AnimatedBackground(controller: _bgAnimController),

          // Main content
          SafeArea(
            top: false,
            child: Column(
              children: [
                // ── Message list ─────────────────────────────────────────
                Expanded(
                  child: _messages.isEmpty
                      ? const EmptyChatPlaceholder()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 40 : 0,
                            vertical: 12,
                          ),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) {
                            final msg = _messages[i];
                            return MessageBubble(
                              key: ValueKey(i),
                              text: msg.text,
                              isUser: msg.isUser,
                              animIndex: i,
                              onEdit: msg.isUser ? _editMessage : null,
                            );
                          },
                        ),
                ),

                // ── Typing indicator ──────────────────────────────────────
                AnimatedSwitcher(
                  duration: 300.ms,
                  child: _isTyping
                      ? const TypingIndicator()
                      : const SizedBox.shrink(),
                ),

                // ── Input bar ─────────────────────────────────────────────
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
}

// ─── Animated background blobs ────────────────────────────────────────────────
class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedBackground({required this.controller});

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
                  color: AppColors.accentPrimary.withValues(alpha: 0.045),
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
                  color: AppColors.accentSecondary.withValues(alpha: 0.035),
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
        border: const Border(
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
                        color: AppColors.accentPrimary.withValues(alpha: 0.12),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // ── File attach button ───────────────────────────────────
                _AttachButton(onTap: widget.onAttach),

                // ── Text field ───────────────────────────────────────────
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 140),
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) {
                        // Enter = send, Shift+Enter = newline
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
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontFamily: 'Inter',
                          height: 1.5,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Message NoNet AI...',
                          hintStyle: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 15,
                            fontFamily: 'Inter',
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Extra action buttons ─────────────────────────────────
                // Mic (optional, placeholder)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, right: 2),
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.mic_none_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    tooltip: 'Voice input',
                  ),
                ),

                // ── Send button ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, right: 6),
                  child: AnimatedSwitcher(
                    duration: 200.ms,
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: child,
                    ),
                    child: (widget.hasText ||
                            widget.isLoading ||
                            widget.attachedFiles.isNotEmpty)
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

          // Hint text
          const SizedBox(height: 6),
          Text(
            'Enter to send · Shift+Enter for new line',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── File attach button ────────────────────────────────────────────────────────
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
            child: const Center(
              child: Icon(
                Icons.attach_file_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
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
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom sheet options ──────────────────────────────────────────────────────
class _OptionsSheet extends StatelessWidget {
  final VoidCallback onClear;
  const _OptionsSheet({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Options',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 20),
          _SheetTile(
            icon: Icons.delete_sweep_rounded,
            label: 'Clear conversation',
            color: AppColors.error,
            onTap: onClear,
          ),
          const SizedBox(height: 10),
          _SheetTile(
            icon: Icons.info_outline_rounded,
            label: 'About NoNet AI',
            color: AppColors.accentSecondary,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SheetTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.aiBubbleBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}