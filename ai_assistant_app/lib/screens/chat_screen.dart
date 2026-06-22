import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../app_provider.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final VoidCallback? onBack;
  final String? initialPrompt;

  const ChatScreen(
      {super.key, this.scaffoldKey, this.onBack, this.initialPrompt});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _isTyping = false;
  List<PlatformFile> _files = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt?.trim().isNotEmpty == true) {
      _controller.text = widget.initialPrompt!.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendMessage());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final provider = context.read<AppProvider>();
    var session = provider.currentSession;
    session ??= await provider.createNewSession();
    final raw = _controller.text.trim();
    if ((raw.isEmpty && _files.isEmpty) || _isTyping) return;
    HapticFeedback.lightImpact();

    final fileText = _files.isEmpty
        ? ''
        : '\n[Attached: ${_files.map((e) => e.name).join(', ')}]';
    final prompt = '$raw$fileText'.trim();
    session.messages.add(Message(text: prompt, isUser: true));
    if (session.messages.length == 1) {
      session.title =
          prompt.length > 38 ? '${prompt.substring(0, 38)}…' : prompt;
    }
    setState(() {
      _controller.clear();
      _files = [];
      _isTyping = true;
    });
    _toBottom();

    final responseIndex = session.messages.length;
    session.messages.add(Message(text: '', isUser: false));
    var response = '';
    try {
      await for (final chunk in ApiService.streamMessage(prompt)) {
        response += chunk;
        session.messages[responseIndex] =
            Message(text: response, isUser: false);
        if (mounted) setState(() {});
        _toBottom();
      }
      if (response.trim().isEmpty) {
        throw const FormatException('Empty response');
      }
    } catch (_) {
      session.messages[responseIndex] = Message(
        text:
            'I couldn’t reach the local model just now. Start the local server and try again — your message is safely saved.',
        isUser: false,
      );
    }
    if (!mounted) return;
    setState(() => _isTyping = false);
    await provider.updateCurrentSession();
    _toBottom();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(allowMultiple: true);
    if (result != null && mounted) {
      setState(() => _files = [..._files, ...result.files]);
    }
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: 320.ms,
            curve: Curves.easeOutCubic,
          );
        }
      });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final messages = provider.currentSession?.messages ?? [];
    return Scaffold(
      appBar: _ChatAppBar(
        title: provider.currentSession?.title == 'New Chat'
            ? 'Rama AI'
            : provider.currentSession?.title ?? 'Rama AI',
        onBack: widget.onBack ?? () => Navigator.maybePop(context),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? const _ConversationPreview()
                  : ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      itemCount: messages.length,
                      itemBuilder: (_, index) {
                        final message = messages[index];
                        final showImage = !message.isUser &&
                            index > 0 &&
                            messages[index - 1]
                                .text
                                .toLowerCase()
                                .contains('image');
                        return _MessageBubble(
                          message: message,
                          showImage: showImage,
                          isStreaming:
                              _isTyping && index == messages.length - 1,
                        ).animate().fadeIn(duration: 260.ms).slideY(begin: .04);
                      },
                    ),
            ),
            if (_isTyping) const _TypingRow(),
            _Composer(
              controller: _controller,
              focusNode: _focusNode,
              files: _files,
              isTyping: _isTyping,
              onAttach: _pickFiles,
              onSend: _sendMessage,
              onRemove: (index) => setState(() => _files.removeAt(index)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBack;
  const _ChatAppBar({required this.title, required this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) => AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.bgBase,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 72,
        leadingWidth: 68,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: _CircleButton(
              icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
        ),
        titleSpacing: 4,
        title: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
                color: AppColors.accentPrimary, shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                const Row(children: [
                  Icon(Icons.circle, color: AppColors.success, size: 7),
                  SizedBox(width: 5),
                  Text('Online  •  Local & private',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600)),
                ]),
              ])),
        ]),
        actions: [
          _CircleButton(icon: Icons.more_horiz_rounded, onTap: () {}),
          const SizedBox(width: 16),
        ],
      );
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0x80FFFFFF),
        shape: const CircleBorder(),
        child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child:
                SizedBox(width: 44, height: 44, child: Icon(icon, size: 19))),
      );
}

class _ConversationPreview extends StatelessWidget {
  const _ConversationPreview();
  @override
  Widget build(BuildContext context) => ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
        children: [
          const Center(
              child: Text('TODAY  10:42 AM',
                  style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1))),
          const SizedBox(height: 28),
          const _StaticUserBubble(
              text:
                  'Create an image of a peaceful workspace in warm morning light.'),
          const SizedBox(height: 22),
          const _AssistantHeader(),
          const SizedBox(height: 10),
          const Text(
              'Here’s a calm, sunlit workspace with warm natural textures and a quiet editorial feel.',
              style: TextStyle(
                  fontSize: 15, height: 1.5, color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          const _GeneratedImageCard(),
          const SizedBox(height: 12),
          const _ReactionBar(),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0x80FFFFFF),
                borderRadius: BorderRadius.circular(20)),
            child: const Text(
                'Tip: Ask me to change the mood, palette, composition, or aspect ratio.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
          ),
        ],
      );
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool showImage;
  final bool isStreaming;
  const _MessageBubble(
      {required this.message,
      required this.showImage,
      required this.isStreaming});
  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(left: 54, bottom: 24),
        child: Align(
            alignment: Alignment.centerRight,
            child: _StaticUserBubble(text: message.text)),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _AssistantHeader(),
        const SizedBox(height: 10),
        if (message.text.isEmpty && isStreaming)
          const _Dots()
        else
          SelectableText(message.text,
              style: const TextStyle(fontSize: 15, height: 1.52)),
        if (showImage) ...[
          const SizedBox(height: 14),
          const _GeneratedImageCard(),
        ],
        if (message.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          const _ReactionBar(),
        ],
      ]),
    );
  }
}

class _StaticUserBubble extends StatelessWidget {
  final String text;
  const _StaticUserBubble({required this.text});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: const BoxDecoration(
          color: AppColors.userBubble,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(8),
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24)),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, height: 1.45)),
      );
}

class _AssistantHeader extends StatelessWidget {
  const _AssistantHeader();
  @override
  Widget build(BuildContext context) => const Row(children: [
        CircleAvatar(
            radius: 15,
            backgroundColor: Color(0xFFE0C5AA),
            child: Icon(Icons.auto_awesome_rounded,
                size: 14, color: AppColors.textPrimary)),
        SizedBox(width: 9),
        Text('Rama AI',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        SizedBox(width: 6),
        Icon(Icons.verified_rounded, size: 14, color: AppColors.accentTertiary),
      ]);
}

class _GeneratedImageCard extends StatelessWidget {
  const _GeneratedImageCard();
  @override
  Widget build(BuildContext context) => Container(
        height: 238,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: AppShadows.card),
        clipBehavior: Clip.antiAlias,
        child: Stack(fit: StackFit.expand, children: [
          Image.asset(
            'assets/images/workspace_preview.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const _ImageFallback(),
          ),
          const Positioned(left: 14, top: 14, child: _ImageBadge()),
          Positioned(
            right: 14,
            bottom: 14,
            child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                    color: Color(0xD9FFFFFF), shape: BoxShape.circle),
                child: const Icon(Icons.file_download_outlined, size: 19)),
          ),
        ]),
      );
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE2C4A5), Color(0xFF728B80)])),
        child: Stack(children: [
          Positioned(
              left: 34,
              bottom: 42,
              child: Container(
                  width: 250,
                  height: 78,
                  decoration: BoxDecoration(
                      color: const Color(0xFFD4A878),
                      borderRadius: BorderRadius.circular(8)))),
          Positioned(
              left: 68,
              bottom: 108,
              child: Container(
                  width: 102,
                  height: 70,
                  decoration: BoxDecoration(
                      color: const Color(0xFF262B29),
                      borderRadius: BorderRadius.circular(8)))),
          const Positioned(
              right: 44,
              bottom: 112,
              child: Icon(Icons.local_florist_rounded,
                  color: Color(0xFF365C4D), size: 70)),
          const Positioned(
              right: 28,
              top: 22,
              child: Icon(Icons.wb_sunny_rounded,
                  color: Color(0xFFFFE4A8), size: 54)),
        ]),
      );
}

class _ImageBadge extends StatelessWidget {
  const _ImageBadge();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
            color: const Color(0xD9FFFFFF),
            borderRadius: BorderRadius.circular(999)),
        child: const Text('AI GENERATED',
            style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
      );
}

class _ReactionBar extends StatelessWidget {
  const _ReactionBar();
  @override
  Widget build(BuildContext context) => Row(children: [
        _Reaction(
            icon: Icons.content_copy_rounded,
            onTap: () => HapticFeedback.selectionClick()),
        _Reaction(
            icon: Icons.thumb_up_alt_outlined,
            onTap: () => HapticFeedback.selectionClick()),
        _Reaction(
            icon: Icons.thumb_down_alt_outlined,
            onTap: () => HapticFeedback.selectionClick()),
        _Reaction(
            icon: Icons.ios_share_rounded,
            onTap: () => HapticFeedback.selectionClick()),
        const Spacer(),
        const Text('Just now',
            style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ]);
}

class _Reaction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Reaction({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => IconButton(
      onPressed: onTap,
      constraints: const BoxConstraints.tightFor(width: 38, height: 38),
      padding: EdgeInsets.zero,
      icon: Icon(icon, size: 16, color: AppColors.textSecondary));
}

class _TypingRow extends StatelessWidget {
  const _TypingRow();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.fromLTRB(22, 4, 22, 10),
        child: Row(children: [
          CircleAvatar(
              radius: 13,
              backgroundColor: Color(0xFFE0C5AA),
              child: Icon(Icons.auto_awesome_rounded, size: 12)),
          SizedBox(width: 10),
          _Dots(),
          SizedBox(width: 10),
          Text('Rama is thinking',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted))
        ]),
      );
}

class _Dots extends StatefulWidget {
  const _Dots();
  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> {
  int active = 0;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(360.ms, (_) {
      if (mounted) setState(() => active = (active + 1) % 3);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
          3,
          (i) => AnimatedContainer(
              duration: 180.ms,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                  color: i == active
                      ? AppColors.textPrimary
                      : AppColors.textMuted.withValues(alpha: .45),
                  shape: BoxShape.circle))));
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<PlatformFile> files;
  final bool isTyping;
  final VoidCallback onAttach;
  final VoidCallback onSend;
  final ValueChanged<int> onRemove;
  const _Composer(
      {required this.controller,
      required this.focusNode,
      required this.files,
      required this.isTyping,
      required this.onAttach,
      required this.onSend,
      required this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(16, files.isEmpty ? 10 : 8, 10,
            10 + MediaQuery.of(context).padding.bottom * .15),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppShadows.floating),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (files.isNotEmpty)
            SizedBox(
                height: 36,
                child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: files.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => InputChip(
                        label: Text(files[i].name,
                            style: const TextStyle(fontSize: 10)),
                        onDeleted: () => onRemove(i)))),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            IconButton(
                onPressed: onAttach,
                icon: const Icon(Icons.add_rounded,
                    color: AppColors.textSecondary)),
            Expanded(
                child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                        hintText: 'Ask anything…',
                        hintStyle: TextStyle(color: AppColors.textMuted)))),
            IconButton(
                onPressed: () => HapticFeedback.lightImpact(),
                icon: const Icon(Icons.mic_none_rounded,
                    color: AppColors.textSecondary)),
            Material(
              color: isTyping ? AppColors.textMuted : AppColors.accentPrimary,
              shape: const CircleBorder(),
              child: IconButton(
                  onPressed: isTyping ? null : onSend,
                  color: Colors.white,
                  icon: Icon(isTyping
                      ? Icons.stop_rounded
                      : Icons.arrow_upward_rounded)),
            ),
          ]),
        ]),
      );
}
