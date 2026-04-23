import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    if (user == null) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    final initials = user.name.split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase()).take(2).join();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
        child: Column(
          children: [
            // ── Avatar / identity card ─────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accentGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(user.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: user.subscription.isPremium
                          ? AppColors.accentOrange.withOpacity(0.1)
                          : AppColors.divider,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.subscription.isPremium ? '⭐ PRO MEMBER' : 'FREE PLAN',
                      style: TextStyle(
                        color: user.subscription.isPremium ? AppColors.accentOrange : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Study Settings ─────────────────────────
            _SectionCard(
              title: 'Study Settings',
              children: [
                _MenuTile(icon: Icons.person_outline_rounded, title: 'Edit Profile', onTap: () => context.push('/profile-setup')),
                _MenuTile(icon: Icons.notifications_outlined, title: 'Notifications', trailing: Switch(value: true, onChanged: (v) {}, activeColor: AppColors.primary)),
                _MenuTile(
                  icon: isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  title: 'Dark Mode',
                  trailing: Switch(value: isDark, onChanged: (v) => ref.read(themeModeProvider.notifier).toggle(), activeColor: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Account ────────────────────────────────
            _SectionCard(
              title: 'Account',
              children: [
                _MenuTile(icon: Icons.lock_outline_rounded, title: 'Change Password', onTap: () {}),
                _MenuTile(icon: Icons.star_outline_rounded, title: 'Upgrade to Pro', color: AppColors.accentOrange, onTap: () {}),
                _MenuTile(
                  icon: Icons.logout_rounded,
                  title: 'Log Out',
                  color: const Color(0xFFE07A5F),
                  onTap: () async {
                    await ref.read(authStateProvider.notifier).logout();
                    if (context.mounted) context.go('/welcome');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5)),
            ),
            const Divider(height: 1, color: AppColors.divider),
            ...children,
          ],
        ),
      );
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final Color? color;
  final VoidCallback? onTap;

  const _MenuTile({required this.icon, required this.title, this.trailing, this.color, this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? AppColors.primary).withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color ?? AppColors.primary, size: 18),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color ?? AppColors.textPrimary, fontSize: 14)),
        trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        minLeadingWidth: 0,
      );
}
