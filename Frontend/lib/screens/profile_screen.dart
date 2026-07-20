import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/test_provider.dart';
import '../app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final statsAsync = ref.watch(testStatsProvider);

    if (user == null) {
      return const Scaffold(backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    final initials = user.name.split(' ')
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase()).take(2).join();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text('Profile', style: GoogleFonts.outfit(
            fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFFF0F0F5))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        child: Column(children: [
          // ── Avatar & name ────────────────────────────
          Stack(children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Center(child: Text(initials, style: GoogleFonts.outfit(
                  fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white))),
            ),
            Positioned(
              bottom: 0, right: 0,
              child: GestureDetector(
                onTap: () => context.push('/profile-setup'),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF0EEF8), width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: const Icon(Icons.edit_rounded,
                      size: 14, color: AppColors.primary),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Text(user.name, style: GoogleFonts.outfit(
              fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(user.email, style: GoogleFonts.outfit(
              fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          // Tags
          Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
            if (user.profile.grade.isNotEmpty)
              _Tag(label: user.profile.grade, filled: false),
            if (user.profile.targetExam.isNotEmpty)
              _Tag(label: user.profile.targetExam, filled: true),
          ]),
          const SizedBox(height: 24),

          // ── Stats ─────────────────────────────────────
          statsAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (stats) => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Row(children: [
                Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(children: [
                    Text('${stats.totalTests * 2}h',
                        style: GoogleFonts.outfit(fontSize: 22,
                            fontWeight: FontWeight.w800, color: AppColors.primary)),
                    Text('Hours Studied', style: GoogleFonts.outfit(
                        fontSize: 12, color: AppColors.textSecondary)),
                  ]),
                )),
                Container(width: 1, height: 44, color: const Color(0xFFF0EEF8)),
                Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(children: [
                    Text('${stats.totalTests}', style: GoogleFonts.outfit(
                        fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    Text('Tests Taken', style: GoogleFonts.outfit(
                        fontSize: 12, color: AppColors.textSecondary)),
                  ]),
                )),
                Container(width: 1, height: 44, color: const Color(0xFFF0EEF8)),
                Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(children: [
                    Text('${stats.avgScore}%', style: GoogleFonts.outfit(
                        fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    Text('Avg Score', style: GoogleFonts.outfit(
                        fontSize: 12, color: AppColors.textSecondary)),
                  ]),
                )),
              ]),
            ),
          ),
          const SizedBox(height: 24),

          // ── Menu ──────────────────────────────────────
          _MenuCard(items: [
            _MI(icon: Icons.person_outline_rounded,    label: 'Account',
                onTap: () => context.push('/profile-setup')),
            _MI(icon: Icons.notifications_outlined,    label: 'Notifications',
                onTap: () => context.push('/settings')),
            _MI(icon: Icons.settings_outlined,         label: 'Settings',
                onTap: () => context.push('/settings')),
            _MI(icon: Icons.help_outline_rounded,      label: 'Help & Support',
                onTap: () {}),
            _MI(icon: Icons.security_outlined,         label: 'Privacy Policy',
                onTap: () {}),
            _MI(icon: Icons.info_outline_rounded,      label: 'About',
                onTap: () {}),
          ]),
          const SizedBox(height: 24),

          // ── Logout ────────────────────────────────────
          GestureDetector(
            onTap: () => _confirmLogout(context, ref),
            child: Container(
              width: double.infinity, height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.30), width: 1.5),
              ),
              child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
                const SizedBox(width: 10),
                Text('Log Out', style: GoogleFonts.outfit(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: const Color(0xFFEF4444))),
              ])),
            ),
          ),
          const SizedBox(height: 12),
          Text('StudyCoach AI  v1.0.0', style: GoogleFonts.outfit(
              fontSize: 11, color: AppColors.textLight)),
        ]),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log Out?', style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800, fontSize: 18)),
        content: Text('You\'ll need to sign in again to access your account.',
            style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.divider),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text('Cancel', style: GoogleFonts.outfit(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/welcome');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text('Log Out', style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final String label;
  final bool filled;
  const _Tag({required this.label, required this.filled});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: filled ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: filled ? AppColors.primary : const Color(0xFFE8E6F0)),
    ),
    child: Text(label, style: GoogleFonts.outfit(fontSize: 12,
        fontWeight: FontWeight.w600,
        color: filled ? Colors.white : AppColors.textSecondary)),
  );
}

class _MenuCard extends StatelessWidget {
  final List<_MI> items;
  const _MenuCard({required this.items});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: Column(
      children: items.asMap().entries.map((e) {
        final isLast = e.key == items.length - 1;
        return Column(children: [
          InkWell(
            onTap: e.value.onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                      color: AppColors.primaryLight, borderRadius: BorderRadius.circular(11)),
                  child: Icon(e.value.icon, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(e.value.label, style: GoogleFonts.outfit(
                    fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
                const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textLight),
              ]),
            ),
          ),
          if (!isLast) const Divider(height: 1, indent: 68, color: Color(0xFFF5F5FA)),
        ]);
      }).toList(),
    ),
  );
}

class _MI {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MI({required this.icon, required this.label, required this.onTap});
}
