import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameCtrl;
  bool _editing = false;
  bool _saved = false;

  static const _avatarGradients = [
    [Color(0xFF7C6FFF), Color(0xFF00D9FF)],
    [Color(0xFF10D9A0), Color(0xFF0099CC)],
    [Color(0xFFFF5670), Color(0xFFFFB830)],
    [Color(0xFF9D4EDD), Color(0xFF7C6FFF)],
    [Color(0xFFFFB830), Color(0xFFFF5670)],
    [Color(0xFF00D9FF), Color(0xFF10D9A0)],
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _nameCtrl = TextEditingController(text: provider.userName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final provider = context.read<AppProvider>();
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    await provider.setUserName(name);
    setState(() {
      _editing = false;
      _saved = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    AppColors.init(provider.isDarkMode);
    final avatarColors = _avatarGradients[provider.avatarIndex % _avatarGradients.length];

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 20),
        ),
        title: Text(
          'My Profile',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.aiBubbleBorder),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ── Avatar picker ─────────────────────────────────────────────
            _buildAvatarSection(provider, avatarColors)
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: -0.1),

            const SizedBox(height: 32),

            // ── Name card ─────────────────────────────────────────────────
            _buildNameCard(provider)
                .animate()
                .fadeIn(delay: 200.ms, duration: 500.ms)
                .slideY(begin: 0.1),

            const SizedBox(height: 20),

            // ── Stats card ─────────────────────────────────────────────────
            _buildStatsCard(provider)
                .animate()
                .fadeIn(delay: 400.ms, duration: 500.ms),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(AppProvider provider, List<Color> colors) {
    return Column(
      children: [
        // Big avatar circle
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colors[0].withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: Text(
              provider.userName.isNotEmpty
                  ? provider.userName[0].toUpperCase()
                  : 'R',
              style: GoogleFonts.inter(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Choose Avatar Color',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 12),

        // Color pickers
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _avatarGradients.asMap().entries.map((e) {
            final i = e.key;
            final grad = e.value;
            final selected = provider.avatarIndex == i;
            return GestureDetector(
              onTap: () => provider.setAvatarIndex(i),
              child: AnimatedContainer(
                duration: 200.ms,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: selected ? 38 : 32,
                height: selected ? 38 : 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: grad,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: selected ? Colors.white : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: selected
                      ? [BoxShadow(color: grad[0].withValues(alpha: 0.5), blurRadius: 8)]
                      : [],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNameCard(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.aiBubbleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.badge_outlined, size: 16, color: AppColors.accentPrimary),
              const SizedBox(width: 8),
              Text(
                'Display Name',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (!_editing)
                GestureDetector(
                  onTap: () => setState(() => _editing = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_rounded,
                            size: 13, color: AppColors.accentPrimary),
                        const SizedBox(width: 4),
                        Text(
                          'Edit',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.accentPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (_editing) ...[
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Enter your name',
                hintStyle: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.accentPrimary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.accentPrimary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.bgCard,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _editing = false);
                      _nameCtrl.text = provider.userName;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.aiBubbleBorder),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _save,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.gradStart, AppColors.accentSecondary],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Save',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Text(
                  provider.userName.isEmpty ? 'Not set' : provider.userName,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: provider.userName.isEmpty
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                  ),
                ),
                if (_saved) ...[
                  const SizedBox(width: 10),
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 18)
                      .animate()
                      .scale(curve: Curves.elasticOut),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCard(AppProvider provider) {
    final total = provider.sessions.length;
    final msgs = provider.sessions.fold(0, (s, e) => s + e.messages.length);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.aiBubbleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Stats',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatItem(
                icon: Icons.chat_bubble_outline_rounded,
                value: '$total',
                label: 'Chats',
              ),
              const SizedBox(width: 12),
              _StatItem(
                icon: Icons.message_outlined,
                value: '$msgs',
                label: 'Messages',
              ),
              const SizedBox(width: 12),
              _StatItem(
                icon: Icons.offline_bolt_rounded,
                value: '100%',
                label: 'Offline',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.aiBubbleBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.accentPrimary),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
