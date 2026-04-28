import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../models/user_model.dart';
import '../providers/gamification_provider.dart';
import '../widgets/animations.dart';
import '../widgets/rank_badge.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(gamificationStateProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (state) {
          return SafeArea(
            child: Column(
              children: [
                // ── HERO HEADER ──
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4F35E1), Color(0xFF864AF9)], // Matching vibrant neon purple
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                              onPressed: () => context.pop(),
                            ),
                            Text(
                              'Rewards & Progress',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    RankBadge(
                                      level: state.level,
                                      size: 64,
                                      showLabel: false,
                                      showGlow: true,
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'LEVEL ${state.level}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.5,
                                            color: Colors.white.withValues(alpha: 0.7),
                                          ),
                                        ),
                                        Text(
                                          state.rank,
                                          style: GoogleFonts.outfit(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            height: 1.1,
                                          ),
                                        ),
                                        Text(
                                          RankTier.fromLevel(state.level).name,
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text('🪙', style: TextStyle(fontSize: 24)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${state.coins}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${state.xp} XP',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${state.xpForNext} XP to next',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            AnimatedProgressBar(
                              value: state.xpNeeded > 0
                                  ? state.xpProgress / state.xpNeeded
                                  : 1.0,
                              color: const Color(0xFF00FFC6), // Neon green
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              height: 12,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // ── RANK PROGRESS CARD ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: RankProgressCard(
                    level: state.level,
                    xp: state.xp,
                    xpNeeded: state.xpNeeded,
                    xpProgress: state.xpProgress,
                    rankName: state.rank,
                  ),
                ),
                // ── PILL TAB BAR ──
                Container(
                  color: Theme.of(context).cardTheme.color,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: const EdgeInsets.all(4),
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                      tabs: const [
                        Tab(text: 'Missions'),
                        Tab(text: 'Store'),
                        Tab(text: 'Achievements'),
                      ],
                    ),
                  ),
                ),
                // ── TAB VIEWS ──
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _MissionsTab(missions: state.dailyMissions),
                      _StoreTab(store: state.rewardStore, coins: state.coins, activeBadgeId: state.activeBadgeId),
                      _AchievementsTab(achievements: state.achievements),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Daily Missions Tab ────────────────────────────────────────────────────────
class _MissionsTab extends StatelessWidget {
  final List<DailyMission> missions;
  const _MissionsTab({required this.missions});

  @override
  Widget build(BuildContext context) {
    if (missions.isEmpty) {
      return const Center(child: Text('No missions today!'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: missions.length,
      itemBuilder: (context, index) {
        final m = missions[index];
        return FadeSlideIn(
          delay: Duration(milliseconds: 100 * index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: m.completed ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF062016) : const Color(0xFFF0FFF4)) : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: m.completed ? const Color(0xFF00E676) : AppColors.divider.withOpacity(0.5), 
                width: m.completed ? 2.5 : 2.0
              ),
              boxShadow: [
                BoxShadow(
                  color: m.completed 
                      ? const Color(0xFF00E676).withValues(alpha: 0.15) 
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        m.label,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: m.completed ? const Color(0xFF00E676).withValues(alpha: 0.15) : const Color(0xFFFF9100).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+${m.xpReward} XP',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          color: m.completed ? const Color(0xFF00B259) : const Color(0xFFFF9100),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AnimatedProgressBar(
                        value: m.progressPct,
                        color: m.completed ? const Color(0xFF00E676) : AppColors.primary,
                        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                        height: 10,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      '${m.progress} / ${m.target}',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: m.completed ? const Color(0xFF00B259) : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Store Tab ────────────────────────────────────────────────────────────────
class _StoreTab extends ConsumerWidget {
  final List<RewardItem> store;
  final int coins;
  final String? activeBadgeId;
  const _StoreTab({required this.store, required this.coins, this.activeBadgeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: store.length,
      itemBuilder: (context, index) {
        final item = store[index];
        final canAfford = item.cost <= coins;

        return FadeSlideIn(
          delay: Duration(milliseconds: 50 * index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: item.unlocked ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF160628) : const Color(0xFFF9F5FF)) : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: item.unlocked ? AppColors.primary : AppColors.divider.withOpacity(0.5),
                width: item.unlocked ? 2.5 : 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: item.unlocked 
                          ? [const Color(0xFF864AF9), const Color(0xFF4F35E1)]
                          : [AppColors.surface, AppColors.surface],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      item.emoji, 
                      style: TextStyle(
                        fontSize: 28,
                        shadows: item.unlocked ? [const Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0,2))] : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (item.unlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF864AF9).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF864AF9), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          item.id == activeBadgeId ? 'Equipped' : 'Owned',
                          style: GoogleFonts.outfit(color: const Color(0xFF864AF9), fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: canAfford
                        ? () async {
                            final error = await ref.read(rewardUnlockProvider.notifier).unlock(item.id);
                            if (error != null && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Reward unlocked! 🎉')),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAfford ? const Color(0xFF00E676) : AppColors.surface,
                      foregroundColor: canAfford ? Colors.white : AppColors.textSecondary,
                      elevation: canAfford ? 4 : 0,
                      shadowColor: const Color(0xFF00E676).withValues(alpha: 0.4),
                      minimumSize: const Size(70, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(canAfford ? '🪙' : '🔒', style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          '${item.cost}',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Achievements Tab ─────────────────────────────────────────────────────────
class _AchievementsTab extends StatelessWidget {
  final List<AchievementItem> achievements;
  const _AchievementsTab({required this.achievements});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final a = achievements[index];
        return FadeSlideIn(
          delay: Duration(milliseconds: 50 * index),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: a.earned 
                  ? const LinearGradient(
                      colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: a.earned ? null : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: a.earned ? const Color(0xFFFFC107) : AppColors.divider.withOpacity(0.5),
                width: a.earned ? 2.5 : 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: a.earned 
                      ? const Color(0xFFFFC107).withValues(alpha: 0.3) 
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: a.earned 
                        ? const LinearGradient(colors: [Color(0xFFFFCA28), Color(0xFFFF8F00)])
                        : null,
                    color: a.earned ? null : Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: a.earned ? [
                      BoxShadow(color: const Color(0xFFFF8F00).withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))
                    ] : null,
                  ),
                  child: Center(
                    child: Text(
                      a.emoji,
                      style: TextStyle(
                        fontSize: 32,
                        color: a.earned ? null : Colors.grey.withValues(alpha: 0.3),
                        shadows: a.earned ? [const Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0,2))] : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  a.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: a.earned ? const Color(0xFFF57F17) : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  a.description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: a.earned ? const Color(0xFFF57F17).withValues(alpha: 0.7) : AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
