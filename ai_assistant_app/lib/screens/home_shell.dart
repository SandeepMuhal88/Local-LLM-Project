import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app_provider.dart';
import '../models/chat_session.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _quickController = TextEditingController();

  @override
  void dispose() {
    _quickController.dispose();
    super.dispose();
  }

  Future<void> _openChat({String? prompt, bool fresh = false}) async {
    final provider = context.read<AppProvider>();
    if (fresh || provider.currentSession == null) {
      await provider.createNewSession();
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          initialPrompt: prompt,
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _submitQuick() {
    final value = _quickController.text.trim();
    if (value.isEmpty) return;
    _quickController.clear();
    _openChat(prompt: value, fresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final sessions = provider.sessions.take(3).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 136),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _TopBar(
                          userName: provider.userName,
                          onProfile: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const ProfileScreen())),
                        ),
                        const SizedBox(height: 40),
                        const Text('What can I help\nyou create today?',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Text('Ask Anything',
                            style: Theme.of(context).textTheme.displayLarge),
                        const SizedBox(height: 28),
                        _SearchBar(onTap: () => _openChat(fresh: true)),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: _FeatureCard(
                                eyebrow: 'WRITE',
                                title: 'AI Text\nWriter',
                                icon: Icons.edit_note_rounded,
                                color: const Color(0xFFE0C5AA),
                                onTap: () => _openChat(
                                    prompt:
                                        'Help me write something remarkable.',
                                    fresh: true),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _FeatureCard(
                                eyebrow: 'IMAGINE',
                                title: 'AI Image\nGenerator',
                                icon: Icons.auto_awesome_rounded,
                                color: const Color(0xFFB8CCC5),
                                onTap: () => _openChat(
                                    prompt: 'Create an image concept for me.',
                                    fresh: true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recent Activities',
                                style: Theme.of(context).textTheme.titleLarge),
                            TextButton(
                                onPressed: () =>
                                    _showHistory(context, provider),
                                child: const Text('See all',
                                    style: TextStyle(
                                        color: AppColors.textSecondary))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (sessions.isEmpty)
                          _EmptyRecent(onTap: () => _openChat(fresh: true))
                        else
                          ...sessions.asMap().entries.map((entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _RecentTile(
                                  session: entry.value,
                                  index: entry.key,
                                  onTap: () async {
                                    await provider.selectSession(entry.value);
                                    _openChat();
                                  },
                                ),
                              )),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      extendBody: true,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child:
            _QuickInput(controller: _quickController, onSubmit: _submitQuick),
      ),
    );
  }

  void _showHistory(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgBase,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Conversation history',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),
              ...provider.sessions.take(5).map((session) => _RecentTile(
                    session: session,
                    index: 0,
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await provider.selectSession(session);
                      _openChat();
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String userName;
  final VoidCallback onProfile;
  const _TopBar({required this.userName, required this.onProfile});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          GestureDetector(
            onTap: onProfile,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2927),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: AppShadows.card,
              ),
              alignment: Alignment.center,
              child: Text(
                userName.isEmpty
                    ? 'R'
                    : userName.characters.first.toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Good morning',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            Text(userName == 'Friend' ? 'Welcome back' : userName,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ]),
          const Spacer(),
          _HeaderButton(
            icon: Icons.notifications_none_rounded,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('You’re all caught up.'))),
            badge: true,
          ),
          const SizedBox(width: 8),
          _HeaderButton(
              icon: Icons.grid_view_rounded, onTap: () => _showTools(context)),
        ],
      );

  void _showTools(BuildContext context) => showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.bgBase,
        showDragHandle: true,
        builder: (_) => const SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Tool(icon: Icons.document_scanner_outlined, label: 'Scan'),
                  _Tool(icon: Icons.translate_rounded, label: 'Translate'),
                  _Tool(icon: Icons.code_rounded, label: 'Code'),
                  _Tool(icon: Icons.lightbulb_outline_rounded, label: 'Ideas'),
                ]),
          ),
        ),
      );
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;
  const _HeaderButton(
      {required this.icon, required this.onTap, this.badge = false});

  @override
  Widget build(BuildContext context) => Stack(children: [
        Material(
          color: const Color(0x80FFFFFF),
          shape: const CircleBorder(),
          child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child:
                  SizedBox(width: 44, height: 44, child: Icon(icon, size: 21))),
        ),
        if (badge)
          Positioned(
              right: 9,
              top: 8,
              child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: AppColors.error, shape: BoxShape.circle))),
      ]);
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBar({required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppShadows.card),
            child: const Row(children: [
              Icon(Icons.search_rounded, size: 23),
              SizedBox(width: 14),
              Expanded(
                  child: Text('Ask or search anything',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 15))),
              Icon(Icons.tune_rounded,
                  color: AppColors.textSecondary, size: 20),
            ]),
          ),
        ),
      );
}

class _FeatureCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _FeatureCard(
      {required this.eyebrow,
      required this.title,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: color,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: 196,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(eyebrow,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.3)),
                          Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                  color: Color(0x66FFFFFF),
                                  shape: BoxShape.circle),
                              child: Icon(icon, size: 19)),
                        ]),
                    const Spacer(),
                    Text(title,
                        style: const TextStyle(
                            fontSize: 23,
                            height: 1.05,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.7)),
                    const SizedBox(height: 14),
                    const Row(children: [
                      Text('Start creating',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 15)
                    ]),
                  ]),
            ),
          ),
        ),
      ).animate().fadeIn(duration: 500.ms).slideY(begin: .08);
}

class _RecentTile extends StatelessWidget {
  final ChatSession session;
  final int index;
  final VoidCallback onTap;
  const _RecentTile(
      {required this.session, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const colors = [Color(0xFFF1DDD0), Color(0xFFD9E5E1), Color(0xFFE7DFCF)];
    const icons = [
      Icons.draw_outlined,
      Icons.travel_explore_rounded,
      Icons.lightbulb_outline_rounded
    ];
    return Material(
      color: AppColors.bgSurface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    borderRadius: BorderRadius.circular(16)),
                child: Icon(icons[index % icons.length], size: 21)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(DateFormat('MMM d  •  h:mm a').format(session.createdAt),
                      style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ])),
            const Icon(Icons.arrow_outward_rounded,
                size: 19, color: AppColors.textMuted),
          ]),
        ),
      ),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyRecent({required this.onTap});
  @override
  Widget build(BuildContext context) =>
      _RecentTile(session: ChatSession.create(), index: 0, onTap: onTap);
}

class _QuickInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  const _QuickInput({required this.controller, required this.onSubmit});
  @override
  Widget build(BuildContext context) => Container(
        height: 72,
        padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
        decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppShadows.floating),
        child: Row(children: [
          Expanded(
              child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSubmit(),
                  decoration: const InputDecoration(
                      hintText: 'Message Rama AI',
                      hintStyle: TextStyle(color: AppColors.textMuted)))),
          IconButton(
              onPressed: () => HapticFeedback.lightImpact(),
              icon: const Icon(Icons.mic_none_rounded,
                  color: AppColors.textSecondary)),
          Material(
              color: AppColors.accentPrimary,
              shape: const CircleBorder(),
              child: IconButton(
                  onPressed: onSubmit,
                  color: Colors.white,
                  icon: const Icon(Icons.arrow_upward_rounded))),
        ]),
      );
}

class _Tool extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Tool({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Icon(icon)),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
      ]);
}
