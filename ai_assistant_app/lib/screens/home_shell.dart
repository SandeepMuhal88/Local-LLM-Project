import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../app_provider.dart';
import '../theme/app_theme.dart';
import '../models/chat_session.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    AppColors.init(provider.isDarkMode);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bgBase,
      drawer: _AppDrawer(scaffoldKey: _scaffoldKey),
      body: ChatScreen(scaffoldKey: _scaffoldKey),
    );
  }
}

// ─── Sidebar Drawer ───────────────────────────────────────────────────────────
class _AppDrawer extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const _AppDrawer({required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    AppColors.init(provider.isDarkMode);

    return Drawer(
      width: 290,
      backgroundColor: AppColors.drawerBg,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          _DrawerHeader(userName: provider.userName, avatarIndex: provider.avatarIndex),

          // ── New Chat button ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _NewChatButton(
              onTap: () async {
                await provider.createNewSession();
                scaffoldKey.currentState?.closeDrawer();
              },
            ),
          ),

          const SizedBox(height: 4),

          // ── History label ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.history_rounded, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  'RECENT CHATS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),

          // ── Chat list ────────────────────────────────────────────────────
          Expanded(
            child: provider.sessions.isEmpty
                ? Center(
                    child: Text(
                      'No chats yet',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    itemCount: provider.sessions.length,
                    itemBuilder: (ctx, i) {
                      final session = provider.sessions[i];
                      final isActive = provider.currentSession?.id == session.id;
                      return _ChatHistoryTile(
                        session: session,
                        isActive: isActive,
                        onTap: () {
                          provider.selectSession(session);
                          scaffoldKey.currentState?.closeDrawer();
                        },
                        onDelete: () => provider.deleteSession(session.id),
                      ).animate().fadeIn(
                            delay: Duration(milliseconds: i * 40),
                            duration: 300.ms,
                          );
                    },
                  ),
          ),

          // ── Bottom nav ────────────────────────────────────────────────────
          _DrawerFooter(scaffoldKey: scaffoldKey),
        ],
      ),
    );
  }
}

// ─── Drawer Header ────────────────────────────────────────────────────────────
class _DrawerHeader extends StatelessWidget {
  final String userName;
  final int avatarIndex;
  const _DrawerHeader({required this.userName, required this.avatarIndex});

  static const _avatarColors = [
    [Color(0xFF7C6FFF), Color(0xFF00D9FF)],
    [Color(0xFF10D9A0), Color(0xFF0099CC)],
    [Color(0xFFFF5670), Color(0xFFFFB830)],
    [Color(0xFF9D4EDD), Color(0xFF7C6FFF)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _avatarColors[avatarIndex % _avatarColors.length];
    final top = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 20, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.drawerSurface,
        border: Border(bottom: BorderSide(color: AppColors.aiBubbleBorder)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'R',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => LinearGradient(
                    colors: colors,
                  ).createShader(b),
                  child: Text(
                    'Rama AI',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  userName.isEmpty ? 'User' : userName,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── New Chat Button ──────────────────────────────────────────────────────────
class _NewChatButton extends StatefulWidget {
  final VoidCallback onTap;
  const _NewChatButton({required this.onTap});

  @override
  State<_NewChatButton> createState() => _NewChatButtonState();
}

class _NewChatButtonState extends State<_NewChatButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: 150.ms,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: _hovered
                ? LinearGradient(
                    colors: [AppColors.gradStart, AppColors.accentSecondary],
                  )
                : null,
            color: _hovered ? null : AppColors.drawerSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered ? Colors.transparent : AppColors.aiBubbleBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_rounded,
                size: 18,
                color: _hovered ? Colors.white : AppColors.accentPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'New Chat',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _hovered ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Chat History Tile ────────────────────────────────────────────────────────
class _ChatHistoryTile extends StatefulWidget {
  final ChatSession session;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ChatHistoryTile({
    required this.session,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_ChatHistoryTile> createState() => _ChatHistoryTileState();
}

class _ChatHistoryTileState extends State<_ChatHistoryTile> {
  bool _hovered = false;

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) return 'Today';
    if (now.difference(dt).inDays == 1) return 'Yesterday';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: 150.ms,
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.accentPrimary.withValues(alpha: 0.12)
                : _hovered
                    ? AppColors.drawerSurface
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isActive
                  ? AppColors.accentPrimary.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 15,
                color: widget.isActive
                    ? AppColors.accentPrimary
                    : AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: widget.isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: widget.isActive
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _formatDate(widget.session.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (_hovered || widget.isActive)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 15,
                      color: AppColors.error.withValues(alpha: 0.7),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Drawer Footer ────────────────────────────────────────────────────────────
class _DrawerFooter extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const _DrawerFooter({required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.drawerSurface,
        border: Border(top: BorderSide(color: AppColors.aiBubbleBorder)),
      ),
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _FooterBtn(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            onTap: () {
              scaffoldKey.currentState?.closeDrawer();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          _FooterBtn(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () {
              scaffoldKey.currentState?.closeDrawer();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FooterBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FooterBtn({required this.icon, required this.label, required this.onTap});

  @override
  State<_FooterBtn> createState() => _FooterBtnState();
}

class _FooterBtnState extends State<_FooterBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: 150.ms,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.accentPrimary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: _hovered ? AppColors.accentPrimary : AppColors.textMuted,
              ),
              const SizedBox(height: 3),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: _hovered ? AppColors.accentPrimary : AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
