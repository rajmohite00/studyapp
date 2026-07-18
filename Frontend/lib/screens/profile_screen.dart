import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F7FA),
        body: Center(
            child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2)),
      );
    }

    final initials = user.name
        .split(' ')
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
        .take(2)
        .join();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Profile',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Avatar + name card ─────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8E8EE)),
              ),
              child: Column(children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary,
                  child: Text(initials,
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
                const SizedBox(height: 14),
                Text(user.name,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(user.email,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary)),
                if (user.profile.grade.isNotEmpty ||
                    user.profile.targetExam.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      if (user.profile.grade.isNotEmpty)
                        _InfoChip(user.profile.grade),
                      if (user.profile.targetExam.isNotEmpty)
                        _InfoChip(user.profile.targetExam),
                      if (user.profile.subjects.isNotEmpty)
                        _InfoChip(
                            '${user.profile.subjects.length} Subjects'),
                    ],
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 20),

            // ── Account section ────────────────────────────
            _SectionHeader('Account'),
            const SizedBox(height: 8),
            _MenuGroup(items: [
              _Item(
                icon: Icons.person_outline_rounded,
                label: 'Edit Profile',
                onTap: () => context.push('/profile-setup'),
              ),
              _Item(
                icon: Icons.lock_outline_rounded,
                label: 'Change Password',
                onTap: () => context.push('/change-password'),
              ),
            ]),
            const SizedBox(height: 20),

            // ── App section ────────────────────────────────
            _SectionHeader('App'),
            const SizedBox(height: 8),
            _MenuGroup(items: [
              _Item(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () {},
              ),
              _Item(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                onTap: () {},
              ),
              _Item(
                icon: Icons.shield_outlined,
                label: 'Privacy Policy',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 28),

            // ── Logout ─────────────────────────────────────
            GestureDetector(
              onTap: () => _logout(context, ref),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFE53E3E).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded,
                        color: Color(0xFFE53E3E), size: 18),
                    SizedBox(width: 8),
                    Text('Log Out',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE53E3E))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // App version
            const Text('StudyCoach v1.0.0',
                style: TextStyle(
                    fontSize: 11, color: AppColors.textLight)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out?',
            style:
                TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        content: const Text('You will need to log in again to access your account.'),
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
              backgroundColor: const Color(0xFFE53E3E),
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Log Out',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip(this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary)),
      );
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.8)),
      );
}

class _MenuGroup extends StatelessWidget {
  final List<_Item> items;
  const _MenuGroup({required this.items});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E8EE)),
        ),
        child: Column(
          children: items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            return Column(children: [
              _MenuTile(item: e.value),
              if (!isLast)
                const Divider(
                    height: 1, indent: 52, color: Color(0xFFF0F0F0)),
            ]);
          }).toList(),
        ),
      );
}

class _Item {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Item({required this.icon, required this.label, required this.onTap});
}

class _MenuTile extends StatelessWidget {
  final _Item item;
  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon,
                  size: 17, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(item.label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textLight, size: 18),
          ]),
        ),
      );
}
