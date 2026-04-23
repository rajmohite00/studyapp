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

    if (user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(user.name.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 36, color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(user.email, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: user.subscription.isPremium ? AppColors.accentOrange.withOpacity(0.1) : AppColors.divider, borderRadius: BorderRadius.circular(12)),
              child: Text(user.subscription.isPremium ? 'PRO MEMBER' : 'FREE PLAN', style: TextStyle(color: user.subscription.isPremium ? AppColors.accentOrange : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 36),
            _SectionTitle('Study Settings'),
            _MenuTile(icon: Icons.person_outline, title: 'Edit Profile', onTap: () => context.push('/profile-setup')),
            _MenuTile(icon: Icons.notifications_outlined, title: 'Notifications', trailing: Switch(value: true, onChanged: (v) {}, activeColor: AppColors.primary)),
            _MenuTile(icon: isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined, title: 'Dark Mode', trailing: Switch(value: isDark, onChanged: (v) => ref.read(themeModeProvider.notifier).toggle(), activeColor: AppColors.primary)),
            const SizedBox(height: 24),
            _SectionTitle('Account'),
            _MenuTile(icon: Icons.lock_outline, title: 'Change Password', onTap: () {}),
            _MenuTile(icon: Icons.star_outline, title: 'Upgrade to Pro', color: AppColors.accentOrange, onTap: () {}),
            _MenuTile(icon: Icons.logout, title: 'Log Out', color: Colors.red, onTap: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/welcome');
            }),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 8),
        child: Align(alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
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
          decoration: BoxDecoration(color: (color ?? AppColors.textPrimary).withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color ?? AppColors.textPrimary, size: 20),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: color)),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: AppColors.textLight),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      );
}
