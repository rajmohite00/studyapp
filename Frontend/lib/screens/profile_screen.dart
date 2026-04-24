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
    final isDark = false; // Dark mode removed

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
        title: Text('Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
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
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
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
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              initials,
                              style: GoogleFonts.outfit(fontSize: 30, color: AppColors.textPrimary, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(user.name,
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(user.email,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 14),
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
                    trailing: _NotifSwitch()),
              ],
            ),
            const SizedBox(height: 16),

            // ── Account ────────────────────────────────────────────────
            _SectionCard(
              title: 'Account',
              children: [
                _AnimatedTile(icon: Icons.lock_outline_rounded, title: 'Change Password',
                    onTap: () => context.push('/change-password')),
                _AnimatedTile(
                  icon: Icons.logout_rounded,
                  title: 'Log Out',
                  color: AppColors.accent,
                  onTap: () => _confirmLogout(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Icon
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout_rounded, color: AppColors.accent, size: 34),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              'Log Out? 👋',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Are you sure you want to log out?\nYour progress is saved — don\'t worry!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // Confirm button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await ref.read(authStateProvider.notifier).logout();
                  if (context.mounted) context.go('/welcome');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Yes, Log Me Out',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Cancel button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: BorderSide(color: AppColors.divider, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Stay Logged In',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
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
                  style: GoogleFonts.outfit(
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

// ── Notification toggle (stateful local) ──────────────────────────────────────
class _NotifSwitch extends StatefulWidget {
  const _NotifSwitch();

  @override
  State<_NotifSwitch> createState() => _NotifSwitchState();
}

class _NotifSwitchState extends State<_NotifSwitch> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) => Switch(
        value: _enabled,
        onChanged: (v) {
          setState(() => _enabled = v);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                v ? '🔔 Notifications enabled' : '🔕 Notifications disabled',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: v ? AppColors.accentGreen : AppColors.textSecondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        activeColor: AppColors.primary,
      );
}
