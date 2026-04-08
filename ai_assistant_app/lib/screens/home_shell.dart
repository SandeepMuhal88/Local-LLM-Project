import 'dart:ui';
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
class _AppDrawer extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const _AppDrawer({required this.scaffoldKey});

  @override
  State<_AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<_AppDrawer> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    AppColors.init(provider.isDarkMode);

    return Drawer(
      width: 300,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.drawerBg,
          border: Border(
            right: BorderSide(color: AppColors.glassBorder, width: 1),
          ),
        ),
        child: Column(
          children: [
            // ── Header with glassmorphism ──────────────────────────────────
            _DrawerHeader(
              userName: provider.userName,
              avatarIndex: provider.avatarIndex,
              shimmerController: _shimmerController,
            ),

            // ── Model Selector ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: _ModelSelector(),
            ),

            // ── New Chat button ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: _NewChatButton(
                onTap: () async {
                  await provider.createNewSession();
                  widget.scaffoldKey.currentState?.closeDrawer();
                },
              ),
            ),

            const SizedBox(height: 8),
            _DrawerDivider(),

            // ── Quick Actions ──────────────────────────────────────────────
            _SectionLabel(label: 'QUICK ACTIONS', icon: Icons.bolt_rounded),
            _QuickActionRow(scaffoldKey: widget.scaffoldKey),

            _DrawerDivider(),

            // ── History label ──────────────────────────────────────────────
            _SectionLabel(label: 'RECENT CHATS', icon: Icons.history_rounded),

            // ── Chat list ─────────────────────────────────────────────────
            Expanded(
              child: provider.sessions.isEmpty
                  ? _EmptyHistoryPlaceholder()
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
                            widget.scaffoldKey.currentState?.closeDrawer();
                          },
                          onDelete: () => provider.deleteSession(session.id),
                        ).animate().fadeIn(
                              delay: Duration(milliseconds: i * 40),
                              duration: 300.ms,
                            );
                      },
                    ),
            ),

            // ── Bottom nav ─────────────────────────────────────────────────
            _DrawerFooter(scaffoldKey: widget.scaffoldKey),
          ],
        ),
      ),
    );
  }
}

// ─── Model Selector ───────────────────────────────────────────────────────────
class _ModelSelector extends StatefulWidget {
  @override
  State<_ModelSelector> createState() => _ModelSelectorState();
}

class _ModelSelectorState extends State<_ModelSelector> {
  String _selected = 'Rama AI · Fast';

  final List<Map<String, dynamic>> _models = [
    {
      'name': 'Rama AI · Fast',
      'subtitle': 'Optimized for speed',
      'icon': Icons.flash_on_rounded,
      'color': Color(0xFFF59E0B),
    },
    {
      'name': 'Rama AI · Pro',
      'subtitle': 'Most capable',
      'icon': Icons.stars_rounded,
      'color': Color(0xFF8B5CF6),
    },
    {
      'name': 'Rama AI · Vision',
      'subtitle': 'See & understand images',
      'icon': Icons.visibility_rounded,
      'color': Color(0xFF06B6D4),
    },
    {
      'name': 'Rama AI · Code',
      'subtitle': 'Specialized for coding',
      'icon': Icons.code_rounded,
      'color': Color(0xFF10B981),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final currentModel = _models.firstWhere((m) => m['name'] == _selected);

    return GestureDetector(
      onTap: () => _showModelPicker(context),
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accentPrimary.withValues(alpha: 0.12),
              AppColors.accentSecondary.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (currentModel['color'] as Color).withValues(alpha: 0.2),
              ),
              child: Icon(
                currentModel['icon'] as IconData,
                color: currentModel['color'] as Color,
                size: 17,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selected,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    currentModel['subtitle'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.expand_more_rounded, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  void _showModelPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModelPickerSheet(
        models: _models,
        selected: _selected,
        onSelect: (name) => setState(() => _selected = name),
      ),
    );
  }
}

class _ModelPickerSheet extends StatelessWidget {
  final List<Map<String, dynamic>> models;
  final String selected;
  final void Function(String) onSelect;

  const _ModelPickerSheet({
    required this.models,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgSurface.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.glassBorder),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ShaderMask(
                    shaderCallback: (b) => LinearGradient(
                      colors: [AppColors.gradStart, AppColors.gradEnd],
                    ).createShader(b),
                    child: Text(
                      'Choose Model',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Icon(Icons.close_rounded, color: AppColors.textMuted, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Select the AI model that best fits your needs',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ...models.map((m) => _ModelTile(
                    model: m,
                    isSelected: m['name'] == selected,
                    onTap: () {
                      onSelect(m['name'] as String);
                      Navigator.pop(context);
                    },
                  )),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModelTile extends StatefulWidget {
  final Map<String, dynamic> model;
  final bool isSelected;
  final VoidCallback onTap;
  const _ModelTile({required this.model, required this.isSelected, required this.onTap});

  @override
  State<_ModelTile> createState() => _ModelTileState();
}

class _ModelTileState extends State<_ModelTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.model['color'] as Color;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: 150.ms,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? color.withValues(alpha: 0.12)
                : _hovered
                    ? AppColors.bgCard
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected ? color.withValues(alpha: 0.4) : AppColors.glassBorder,
              width: widget.isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.2),
                ),
                child: Icon(widget.model['icon'] as IconData, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.model['name'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      widget.model['subtitle'] as String,
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (widget.isSelected)
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quick Actions Row ────────────────────────────────────────────────────────
class _QuickActionRow extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const _QuickActionRow({required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          _QuickAction(
            icon: Icons.image_search_rounded,
            label: 'Vision',
            color: AppColors.accentTertiary,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          _QuickAction(
            icon: Icons.mic_rounded,
            label: 'Voice',
            color: AppColors.accentSecondary,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          _QuickAction(
            icon: Icons.extension_rounded,
            label: 'Tools',
            color: AppColors.accentGold,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: 150.ms,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.15)
                  : widget.color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hovered
                    ? widget.color.withValues(alpha: 0.4)
                    : widget.color.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 18, color: widget.color),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: widget.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Drawer Header ────────────────────────────────────────────────────────────
class _DrawerHeader extends StatelessWidget {
  final String userName;
  final int avatarIndex;
  final AnimationController shimmerController;

  const _DrawerHeader({
    required this.userName,
    required this.avatarIndex,
    required this.shimmerController,
  });

  static const _avatarGradients = [
    [Color(0xFF4A90D9), Color(0xFF8B5CF6)],
    [Color(0xFF10B981), Color(0xFF06B6D4)],
    [Color(0xFFEF4444), Color(0xFFF59E0B)],
    [Color(0xFF8B5CF6), Color(0xFFEC4899)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _avatarGradients[avatarIndex % _avatarGradients.length];
    final top = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 20, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.drawerSurface,
            AppColors.drawerBg,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Animated avatar with glow
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors[0].withValues(alpha: 0.5),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'R',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                        border: Border.all(color: AppColors.drawerBg, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Name + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedBuilder(
                      animation: shimmerController,
                      builder: (_, child) {
                        return ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              AppColors.gradStart,
                              AppColors.gradMid,
                              AppColors.gradEnd,
                              AppColors.gradStart,
                            ],
                            stops: [
                              0.0,
                              shimmerController.value * 0.8,
                              shimmerController.value,
                              1.0,
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'Rama AI',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        );
                      },
                    ),
                    Text(
                      userName.isEmpty ? 'Welcome back!' : 'Hello, $userName',
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
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Drawer Divider ───────────────────────────────────────────────────────────
class _DrawerDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Divider(color: AppColors.glassBorder, height: 1, thickness: 1),
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
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: _hovered
                ? LinearGradient(
                    colors: [AppColors.gradStart, AppColors.gradEnd],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: _hovered ? null : AppColors.drawerSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? Colors.transparent : AppColors.glassBorder,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.gradStart.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: -4,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                size: 18,
                color: _hovered ? Colors.white : AppColors.accentPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'New Conversation',
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

// ─── Empty History ────────────────────────────────────────────────────────────
class _EmptyHistoryPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 36, color: AppColors.textMuted)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(begin: 0.3, end: 0.7, duration: 2.seconds),
          const SizedBox(height: 12),
          Text(
            'No conversations yet',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            'Start a new chat above',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
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
                  ? AppColors.accentPrimary.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isActive
                      ? AppColors.accentPrimary.withValues(alpha: 0.2)
                      : AppColors.bgCard,
                ),
                child: Icon(
                  Icons.chat_rounded,
                  size: 14,
                  color: widget.isActive
                      ? AppColors.accentPrimary
                      : AppColors.textMuted,
                ),
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
                        fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
                        color: widget.isActive ? AppColors.textPrimary : AppColors.textSecondary,
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
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 14,
                      color: AppColors.error.withValues(alpha: 0.8),
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
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 10,
        bottom: 10 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: _FooterBtn(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              onTap: () {
                scaffoldKey.currentState?.closeDrawer();
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, a, __) => const ProfileScreen(),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _FooterBtn(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () {
                scaffoldKey.currentState?.closeDrawer();
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, a, __) => const SettingsScreen(),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _FooterBtn(
              icon: Icons.help_outline_rounded,
              label: 'Help',
              onTap: () {},
            ),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
                  fontSize: 10,
                  color: _hovered ? AppColors.accentPrimary : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
