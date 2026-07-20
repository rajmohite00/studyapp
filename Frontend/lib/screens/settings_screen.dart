import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../app_theme.dart';

// ── Extra prefs providers ─────────────────────────────────────────────────────
final _notifProvider = StateNotifierProvider<_BoolPref, bool>(
    (_) => _BoolPref('pref_notifications', true));
final _soundProvider = StateNotifierProvider<_BoolPref, bool>(
    (_) => _BoolPref('pref_sound', true));
final _streakReminderProvider = StateNotifierProvider<_BoolPref, bool>(
    (_) => _BoolPref('pref_streak_reminder', true));
final _analyticsProvider = StateNotifierProvider<_BoolPref, bool>(
    (_) => _BoolPref('pref_analytics', true));

class _BoolPref extends StateNotifier<bool> {
  final String key;
  _BoolPref(this.key, bool defaultVal) : super(defaultVal) { _load(defaultVal); }
  Future<void> _load(bool d) async {
    final p = await SharedPreferences.getInstance();
    state = p.getBool(key) ?? d;
  }
  Future<void> toggle() async {
    state = !state;
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, state);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark   = ref.watch(themeProvider) == ThemeMode.dark;
    final notif    = ref.watch(_notifProvider);
    final sound    = ref.watch(_soundProvider);
    final streak   = ref.watch(_streakReminderProvider);
    final analytics = ref.watch(_analyticsProvider);
    final user     = ref.watch(authStateProvider).user;

    // Adaptive colours
    final bg      = Theme.of(context).scaffoldBackgroundColor;
    final cardBg  = isDark ? AppColors.darkCard : Colors.white;
    final titleC  = isDark ? const Color(0xFFE8E6F8) : AppColors.textPrimary;
    final subC    = isDark ? const Color(0xFF9B99B0) : AppColors.textSecondary;
    final divC    = isDark ? const Color(0xFF2E2C42) : const Color(0xFFF3F3F7);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: isDark ? const Color(0xFFE8E6F8) : AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Settings', style: GoogleFonts.outfit(
            fontSize: 18, fontWeight: FontWeight.w700, color: titleC)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: divC)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 48),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Appearance ───────────────────────────────────
          _SectionLabel('Appearance', titleC),
          const SizedBox(height: 10),
          _SettingsCard(isDark: isDark, cardBg: cardBg, divColor: divC, items: [
            _SwitchTile(
              icon: Icons.dark_mode_outlined,
              label: 'Dark Mode',
              subtitle: 'Easy on the eyes at night',
              value: isDark,
              color: const Color(0xFF8B5CF6),
              cardBg: cardBg,
              titleColor: titleC,
              subColor: subC,
              onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
            ),
          ]),
          const SizedBox(height: 22),

          // ── Notifications ─────────────────────────────────
          _SectionLabel('Notifications', titleC),
          const SizedBox(height: 10),
          _SettingsCard(isDark: isDark, cardBg: cardBg, divColor: divC, items: [
            _SwitchTile(
              icon: Icons.notifications_outlined,
              label: 'Push Notifications',
              subtitle: 'Reminders and updates',
              value: notif,
              color: const Color(0xFF0EA5E9),
              cardBg: cardBg, titleColor: titleC, subColor: subC,
              onChanged: (_) => ref.read(_notifProvider.notifier).toggle(),
            ),
            _SwitchTile(
              icon: Icons.volume_up_outlined,
              label: 'Sound Effects',
              subtitle: 'Sounds during tests & streaks',
              value: sound,
              color: const Color(0xFF10B981),
              cardBg: cardBg, titleColor: titleC, subColor: subC,
              onChanged: (_) => ref.read(_soundProvider.notifier).toggle(),
            ),
            _SwitchTile(
              icon: Icons.local_fire_department_outlined,
              label: 'Streak Reminders',
              subtitle: 'Daily reminder to keep streak',
              value: streak,
              color: const Color(0xFFF59E0B),
              cardBg: cardBg, titleColor: titleC, subColor: subC,
              onChanged: (_) => ref.read(_streakReminderProvider.notifier).toggle(),
            ),
          ]),
          const SizedBox(height: 22),

          // ── Account ───────────────────────────────────────
          _SectionLabel('Account', titleC),
          const SizedBox(height: 10),
          _SettingsCard(isDark: isDark, cardBg: cardBg, divColor: divC, items: [
            _NavTile(
              icon: Icons.person_outline_rounded,
              label: 'Edit Profile',
              subtitle: user?.name ?? '',
              color: AppColors.primary,
              cardBg: cardBg, titleColor: titleC, subColor: subC,
              onTap: () => context.push('/profile-setup'),
            ),
            _NavTile(
              icon: Icons.lock_outline_rounded,
              label: 'Change Password',
              subtitle: 'Update your password',
              color: AppColors.primary,
              cardBg: cardBg, titleColor: titleC, subColor: subC,
              onTap: () => context.push('/change-password'),
            ),
          ]),
          const SizedBox(height: 22),

          // ── Study Preferences ─────────────────────────────
          _SectionLabel('Study Preferences', titleC),
          const SizedBox(height: 10),
          _SettingsCard(isDark: isDark, cardBg: cardBg, divColor: divC, items: [
            _SwitchTile(
              icon: Icons.analytics_outlined,
              label: 'Performance Analytics',
              subtitle: 'Track detailed study stats',
              value: analytics,
              color: const Color(0xFFEF4444),
              cardBg: cardBg, titleColor: titleC, subColor: subC,
              onChanged: (_) => ref.read(_analyticsProvider.notifier).toggle(),
            ),
            _NavTile(
              icon: Icons.school_outlined,
              label: 'Study Goals',
              subtitle: 'Set daily study targets',
              color: const Color(0xFF10B981),
              cardBg: cardBg, titleColor: titleC, subColor: subC,
              onTap: () => context.push('/profile-setup'),
            ),
          ]),
          const SizedBox(height: 22),

          // ── Support ───────────────────────────────────────
          _SectionLabel('Support', titleC),
          const SizedBox(height: 10),
          _SettingsCard(isDark: isDark, cardBg: cardBg, divColor: divC, items: [
            _NavTile(
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              subtitle: 'FAQs and contact us',
              color: const Color(0xFF0EA5E9),
              cardBg: cardBg, titleColor: titleC, subColor: subC,
              onTap: () {},
            ),
            _NavTile(
              icon: Icons.security_outlined,
              label: 'Privacy Policy',
              subtitle: 'How we use your data',
              color: const Color(0xFF8B5CF6),
              cardBg: cardBg, titleColor: titleC, subColor: subC,
              onTap: () {},
            ),
            _NavTile(
              icon: Icons.info_outline_rounded,
              label: 'About App',
              subtitle: 'StudyCoach AI  v1.0.0',
              color: AppColors.textSecondary,
              cardBg: cardBg, titleColor: titleC, subColor: subC,
              onTap: () => _showAbout(context, isDark, titleC, subC),
            ),
          ]),
          const SizedBox(height: 22),

          // ── Danger zone ───────────────────────────────────
          _SectionLabel('Data', titleC),
          const SizedBox(height: 10),
          _SettingsCard(isDark: isDark, cardBg: cardBg, divColor: divC, items: [
            _NavTile(
              icon: Icons.cleaning_services_outlined,
              label: 'Clear Cache',
              subtitle: 'Free up local storage',
              color: const Color(0xFFF59E0B),
              cardBg: cardBg, titleColor: titleC, subColor: subC,
              onTap: () => _clearCache(context),
            ),
          ]),
          const SizedBox(height: 28),

          // ── Sign out ──────────────────────────────────────
          GestureDetector(
            onTap: () => _confirmLogout(context, ref),
            child: Container(
              width: double.infinity, height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.30)),
              ),
              child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.logout_rounded,
                    color: Color(0xFFEF4444), size: 20),
                const SizedBox(width: 10),
                Text('Sign Out', style: GoogleFonts.outfit(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: const Color(0xFFEF4444))),
              ])),
            ),
          ),
        ]),
      ),
    );
  }

  void _clearCache(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_cache');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cache cleared',
            style: GoogleFonts.outfit(fontSize: 13)),
        backgroundColor: AppColors.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      ),
    );
  }

  void _showAbout(BuildContext ctx, bool isDark, Color titleC, Color subC) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('StudyCoach AI', style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800, color: titleC)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 14),
          Text('Version 1.0.0', style: GoogleFonts.outfit(
              color: subC, fontSize: 13)),
          const SizedBox(height: 6),
          Text('Your AI-powered study companion. Built with Flutter.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: subC, fontSize: 12, height: 1.5)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.outfit(
                color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext ctx, WidgetRef ref) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out?', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        content: Text('You\'ll need to sign in again.',
            style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textPrimary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authStateProvider.notifier).logout();
              if (ctx.mounted) ctx.go('/welcome');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444), elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Sign Out',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(text.toUpperCase(), style: GoogleFonts.outfit(
        fontSize: 11, fontWeight: FontWeight.w700,
        color: color.withValues(alpha: 0.55), letterSpacing: 1.0)),
  );
}

// ── Card wrapper ──────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final List<Widget> items;
  final bool isDark;
  final Color cardBg, divColor;
  const _SettingsCard({required this.items, required this.isDark,
      required this.cardBg, required this.divColor});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(18),
      boxShadow: isDark ? [] : [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10, offset: const Offset(0, 3))],
      border: isDark ? Border.all(color: const Color(0xFF2E2C42)) : null,
    ),
    child: Column(
      children: items.asMap().entries.map((e) {
        final isLast = e.key == items.length - 1;
        return Column(children: [
          e.value,
          if (!isLast) Divider(height: 1, indent: 64, color: divColor),
        ]);
      }).toList(),
    ),
  );
}

// ── Toggle tile ───────────────────────────────────────────────────────────────
class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final bool value;
  final Color color, cardBg, titleColor, subColor;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({required this.icon, required this.label,
      required this.subtitle, required this.value, required this.color,
      required this.cardBg, required this.titleColor, required this.subColor,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    child: Row(children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11)),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 14,
            fontWeight: FontWeight.w600, color: titleColor)),
        Text(subtitle, style: GoogleFonts.outfit(fontSize: 11, color: subColor)),
      ])),
      Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    ]),
  );
}

// ── Navigation tile ───────────────────────────────────────────────────────────
class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color, cardBg, titleColor, subColor;
  final VoidCallback onTap;
  const _NavTile({required this.icon, required this.label,
      required this.subtitle, required this.color, required this.cardBg,
      required this.titleColor, required this.subColor, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 14,
              fontWeight: FontWeight.w600, color: titleColor)),
          Text(subtitle, style: GoogleFonts.outfit(fontSize: 11, color: subColor)),
        ])),
        Icon(Icons.chevron_right_rounded, size: 18,
            color: subColor.withValues(alpha: 0.6)),
      ]),
    ),
  );
}
