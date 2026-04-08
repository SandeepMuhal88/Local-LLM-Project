import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    AppColors.init(provider.isDarkMode);

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
          'Settings',
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),

          // ── Appearance section ───────────────────────────────────────────
          _SectionHeader(title: 'APPEARANCE')
              .animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 10),

          _SettingCard(
            child: _ThemeTile(provider: provider),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms)
              .slideX(begin: 0.05, end: 0),

          const SizedBox(height: 24),

          // ── About section ────────────────────────────────────────────────
          _SectionHeader(title: 'ABOUT')
              .animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 10),

          _SettingCard(
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.auto_awesome,
                  label: 'App Name',
                  value: 'Rama AI',
                ),
                _Divider(),
                _InfoTile(
                  icon: Icons.tag_rounded,
                  label: 'Version',
                  value: '1.0.0',
                ),
                _Divider(),
                _InfoTile(
                  icon: Icons.offline_bolt_rounded,
                  label: 'Mode',
                  value: 'Fully Offline',
                  valueColor: AppColors.success,
                ),
                _Divider(),
                _InfoTile(
                  icon: Icons.storage_rounded,
                  label: 'Data Storage',
                  value: 'Local Device Only',
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms)
              .slideX(begin: 0.05, end: 0),

          const SizedBox(height: 24),

          // ── Danger zone ─────────────────────────────────────────────────
          _SectionHeader(title: 'DATA')
              .animate().fadeIn(delay: 400.ms, duration: 400.ms),

          const SizedBox(height: 10),

          _SettingCard(
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.delete_sweep_rounded,
                  label: 'Clear All Chat History',
                  color: AppColors.error,
                  onTap: () => _confirmClearChats(context, provider),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 400.ms)
              .slideX(begin: 0.05, end: 0),

          const SizedBox(height: 40),

          // Branding footer
          Center(
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (b) => LinearGradient(
                    colors: [AppColors.gradStart, AppColors.accentSecondary],
                  ).createShader(b),
                  child: Text(
                    'Rama AI',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Built with ❤️ — runs 100% offline',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 600.ms, duration: 500.ms),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _confirmClearChats(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear All Chats?',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will permanently delete all your chat history. This cannot be undone.',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              final ids = provider.sessions.map((s) => s.id).toList();
              for (final id in ids) {
                await provider.deleteSession(id);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(
              'Delete All',
              style: GoogleFonts.inter(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ─── Setting Card ─────────────────────────────────────────────────────────────
class _SettingCard extends StatelessWidget {
  final Widget child;
  const _SettingCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.aiBubbleBorder),
      ),
      child: child,
    );
  }
}

// ─── Theme Toggle Tile ────────────────────────────────────────────────────────
class _ThemeTile extends StatelessWidget {
  final AppProvider provider;
  const _ThemeTile({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: provider.isDarkMode
                  ? const Color(0xFF1E3A5F)
                  : const Color(0xFFFFE4B5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                provider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                size: 20,
                color: provider.isDarkMode
                    ? AppColors.accentSecondary
                    : const Color(0xFFD97706),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.isDarkMode ? 'Dark Mode' : 'Light Mode',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  provider.isDarkMode
                      ? 'Easy on the eyes at night'
                      : 'Clean and bright look',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Toggle
          GestureDetector(
            onTap: () => provider.toggleTheme(),
            child: AnimatedContainer(
              duration: 250.ms,
              width: 52,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: provider.isDarkMode
                    ? LinearGradient(
                        colors: [AppColors.accentPrimary, AppColors.accentSecondary],
                      )
                    : null,
                color: provider.isDarkMode ? null : AppColors.textMuted,
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: AnimatedAlign(
                  duration: 250.ms,
                  alignment: provider.isDarkMode
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Tile ────────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoTile({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.accentPrimary),
          const SizedBox(width: 14),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimary),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: valueColor ?? AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Tile ──────────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, size: 20, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ─── Divider ─────────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      color: AppColors.aiBubbleBorder,
    );
  }
}
