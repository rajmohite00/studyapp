import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../app_theme.dart';
import '../widgets/animations.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5)),
      );
    }

    final initials = user.name
        .split(' ')
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
        .take(2)
        .join();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.syne(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(height: 1.5, color: AppColors.divider.withOpacity(0.3)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
        child: StaggeredList(
          itemDelay: const Duration(milliseconds: 70),
          children: [
            // ── Avatar card ────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.textPrimary, width: 3),
                boxShadow: const [BoxShadow(color: AppColors.textPrimary, offset: Offset(4, 4))],
              ),
              child: Column(
                children: [
                  // Animated avatar
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.6, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutBack,
                    builder: (_, v, child) => Transform.scale(scale: v, child: child),
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.textPrimary, width: 3),
                        boxShadow: const [BoxShadow(color: AppColors.textPrimary, offset: Offset(3, 3))],
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.syne(fontSize: 30, color: AppColors.textPrimary, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(user.name,
                      style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(user.email,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: user.subscription.isPremium ? AppColors.accentOrange : AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.subscription.isPremium ? '⭐  PRO MEMBER' : 'FREE PLAN',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Study Settings ─────────────────────────────────────────
            _SectionCard(
              title: 'Study Settings',
              children: [
                _AnimatedTile(icon: Icons.person_outline_rounded, title: 'Edit Profile',
                    onTap: () => context.push('/profile-setup')),
                _AnimatedTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    trailing: Switch(value: true, onChanged: (_) {}, activeColor: AppColors.primary)),
                _AnimatedTile(
                  icon: isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  title: 'Dark Mode',
                  trailing: Switch(
                    value: isDark,
                    onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                    activeColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Account ────────────────────────────────────────────────
            _SectionCard(
              title: 'Account',
              children: [
                _AnimatedTile(icon: Icons.lock_outline_rounded, title: 'Change Password', onTap: () {}),
                _AnimatedTile(icon: Icons.star_outline_rounded, title: 'Upgrade to Pro',
                    color: AppColors.accentOrange, onTap: () {}),
                _AnimatedTile(
                  icon: Icons.logout_rounded,
                  title: 'Log Out',
                  color: AppColors.accent,
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
          border: Border.all(color: AppColors.textPrimary, width: 2.5),
          boxShadow: const [BoxShadow(color: AppColors.textPrimary, offset: Offset(3, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Text(title,
                  style: GoogleFonts.syne(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.0)),
            ),
            Container(height: 1.5, color: AppColors.textPrimary.withOpacity(0.08)),
            ...children,
          ],
        ),
      );
}

class _AnimatedTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final Color? color;
  final VoidCallback? onTap;
  const _AnimatedTile({required this.icon, required this.title, this.trailing, this.color, this.onTap});

  @override
  State<_AnimatedTile> createState() => _AnimatedTileState();
}

class _AnimatedTileState extends State<_AnimatedTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _pressed ? AppColors.primary.withOpacity(0.06) : Colors.transparent,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (widget.color ?? AppColors.primary).withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon, color: widget.color ?? AppColors.primary, size: 18),
            ),
            title: Text(widget.title,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: widget.color ?? AppColors.textPrimary,
                    fontSize: 14)),
            trailing: widget.trailing ??
                Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            minLeadingWidth: 0,
          ),
        ),
      );
}
