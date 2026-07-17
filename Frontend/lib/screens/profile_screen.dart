import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final initials = user.name
        .split(' ')
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
        .take(2)
        .join();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Profile',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Avatar card ────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 26,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(user.name,
                      style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(user.email,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Account Settings ───────────────────────────────────────
            _SectionCard(
              title: 'Account',
              children: [
                _Tile(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit Profile',
                  onTap: () => context.push('/profile-setup'),
                ),
                _Tile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change Password',
                  onTap: () => context.push('/change-password'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Sign out ───────────────────────────────────────────────
            _SectionCard(
              title: 'Session',
              children: [
                _Tile(
                  icon: Icons.logout_rounded,
                  title: 'Log Out',
                  color: AppColors.accent,
                  onTap: () => _confirmLogout(context, ref),
                ),
              ],
            ),

            if (user.profile.targetExam.isNotEmpty || user.profile.subjects.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Study Info',
                children: [
                  if (user.profile.targetExam.isNotEmpty)
                    _InfoTile(label: 'Target Exam', value: user.profile.targetExam),
                  if (user.profile.subjects.isNotEmpty)
                    _InfoTile(label: 'Subjects', value: user.profile.subjects.join(', ')),
                  if (user.profile.grade.isNotEmpty)
                    _InfoTile(label: 'Grade', value: user.profile.grade),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log Out?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/welcome');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Log Out'),
          ),
        ],
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8)),
            ),
            Container(height: 1, color: AppColors.divider),
            ...children,
          ],
        ),
      );
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final VoidCallback? onTap;
  const _Tile({required this.icon, required this.title, this.color, this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: color ?? AppColors.primary, size: 20),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: color ?? AppColors.textPrimary)),
        trailing: color == null
            ? const Icon(Icons.chevron_right_rounded,
                color: AppColors.textLight, size: 18)
            : null,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      );
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        subtitle: Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      );
}
