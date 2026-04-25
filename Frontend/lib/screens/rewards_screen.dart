import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../models/user_model.dart';
import '../providers/gamification_provider.dart';
import '../widgets/animations.dart';

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
      backgroundColor: AppColors.background,
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (state) {
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.heroGradient,
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 48, 24, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Level ${state.level}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        state.rank,
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Text('🪙', style: TextStyle(fontSize: 18)),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${state.coins}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${state.xp} XP',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '${state.xpForNext} XP to next',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              AnimatedProgressBar(
                                value: state.xpNeeded > 0
                                    ? state.xpProgress / state.xpNeeded
                                    : 1.0,
                                color: AppColors.accent,
                                height: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: Container(
                      color: AppColors.background,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.primary,
                        indicatorWeight: 3,
                        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15),
                        tabs: const [
                          Tab(text: 'Daily Missions'),
                          Tab(text: 'Reward Store'),
                          Tab(text: 'Achievements'),
                        ],
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _MissionsTab(missions: state.dailyMissions),
                _StoreTab(store: state.rewardStore, coins: state.coins),
                _AchievementsTab(achievements: state.achievements),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider, width: 2),
              boxShadow: [
                if (m.completed)
                  BoxShadow(color: AppColors.accentGreen.withValues(alpha: 0.1), blurRadius: 10)
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
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${m.xpReward} XP',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentOrange,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AnimatedProgressBar(
                        value: m.progressPct,
                        color: m.completed ? AppColors.accentGreen : AppColors.primary,
                        height: 8,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${m.progress} / ${m.target}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: m.completed ? AppColors.accentGreen : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (m.completed)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Completed! 🎉',
                      style: GoogleFonts.outfit(
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
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

// ── Store Tab ────────────────────────────────────────────────────────────────
class _StoreTab extends ConsumerWidget {
  final List<RewardItem> store;
  final int coins;
  const _StoreTab({required this.store, required this.coins});

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
              color: item.unlocked ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: item.unlocked ? AppColors.primary : AppColors.divider,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(item.emoji, style: const TextStyle(fontSize: 24)),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (item.unlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Unlocked',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
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
                      backgroundColor: canAfford ? AppColors.accent : AppColors.divider,
                      foregroundColor: canAfford ? Colors.white : AppColors.textSecondary,
                      elevation: 0,
                      minimumSize: const Size(70, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          '${item.cost}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
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
              color: a.earned ? Colors.white : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: a.earned ? AppColors.accentOrange : AppColors.divider,
                width: 2,
              ),
              boxShadow: [
                if (a.earned)
                  BoxShadow(
                    color: AppColors.accentOrange.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: a.earned ? AppColors.accentOrange.withValues(alpha: 0.1) : AppColors.divider,
                  ),
                  child: Center(
                    child: Text(
                      a.emoji,
                      style: TextStyle(
                        fontSize: 32,
                        color: a.earned ? null : Colors.grey.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  a.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: a.earned ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  a.description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: a.earned ? AppColors.textSecondary : AppColors.textLight,
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
