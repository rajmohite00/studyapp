import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';

// ── Rank Tier Definition ──────────────────────────────────────────────────────
class RankTier {
  final String name;
  final String emoji;
  final IconData icon;
  final List<Color> gradient;
  final Color glowColor;
  final int minLevel;

  const RankTier({
    required this.name,
    required this.emoji,
    required this.icon,
    required this.gradient,
    required this.glowColor,
    required this.minLevel,
  });

  static RankTier fromLevel(int level) {
    if (level >= 40) return tiers[6]; // Grandmaster
    if (level >= 30) return tiers[5]; // Master
    if (level >= 20) return tiers[4]; // Diamond
    if (level >= 15) return tiers[3]; // Platinum
    if (level >= 10) return tiers[2]; // Gold
    if (level >= 5)  return tiers[1]; // Silver
    return tiers[0];                  // Bronze
  }

  static const List<RankTier> tiers = [
    RankTier(
      name: 'Bronze',
      emoji: '🥉',
      icon: Icons.shield_outlined,
      gradient: [Color(0xFFCD7F32), Color(0xFFB8650A)],
      glowColor: Color(0xFFCD7F32),
      minLevel: 1,
    ),
    RankTier(
      name: 'Silver',
      emoji: '🥈',
      icon: Icons.shield,
      gradient: [Color(0xFFC0C0C0), Color(0xFF9E9E9E)],
      glowColor: Color(0xFFC0C0C0),
      minLevel: 5,
    ),
    RankTier(
      name: 'Gold',
      emoji: '🥇',
      icon: Icons.workspace_premium_rounded,
      gradient: [Color(0xFFFFD700), Color(0xFFF59E0B)],
      glowColor: Color(0xFFFFD700),
      minLevel: 10,
    ),
    RankTier(
      name: 'Platinum',
      emoji: '💎',
      icon: Icons.diamond_rounded,
      gradient: [Color(0xFFE5E4E2), Color(0xFF9CB4CC)],
      glowColor: Color(0xFF9CB4CC),
      minLevel: 15,
    ),
    RankTier(
      name: 'Diamond',
      emoji: '💠',
      icon: Icons.diamond_outlined,
      gradient: [Color(0xFF60A5FA), Color(0xFF818CF8)],
      glowColor: Color(0xFF818CF8),
      minLevel: 20,
    ),
    RankTier(
      name: 'Master',
      emoji: '👑',
      icon: Icons.military_tech_rounded,
      gradient: [Color(0xFFA855F7), Color(0xFFEC4899)],
      glowColor: Color(0xFFA855F7),
      minLevel: 30,
    ),
    RankTier(
      name: 'Grandmaster',
      emoji: '🏆',
      icon: Icons.emoji_events_rounded,
      gradient: [Color(0xFFFF6B6B), Color(0xFFFECA57)],
      glowColor: Color(0xFFFECA57),
      minLevel: 40,
    ),
  ];
}

// ── Animated Rank Badge Widget ────────────────────────────────────────────────
class RankBadge extends StatefulWidget {
  final int level;
  final double size;
  final bool showLabel;
  final bool showGlow;

  const RankBadge({
    super.key,
    required this.level,
    this.size = 64,
    this.showLabel = true,
    this.showGlow = true,
  });

  @override
  State<RankBadge> createState() => _RankBadgeState();
}

class _RankBadgeState extends State<RankBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.8)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier = RankTier.fromLevel(widget.level);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, child) => Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: tier.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: widget.showGlow
                  ? [
                      BoxShadow(
                        color: tier.glowColor.withOpacity(_glowAnim.value),
                        blurRadius: 20,
                        spreadRadius: 4,
                      )
                    ]
                  : [],
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 2.5,
              ),
            ),
            child: child,
          ),
          child: Center(
            child: Icon(
              tier.icon,
              color: Colors.white,
              size: widget.size * 0.45,
              shadows: const [
                Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
          ),
        ),
        if (widget.showLabel) ...[
          const SizedBox(height: 6),
          Text(
            '${tier.emoji} ${tier.name}',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: tier.gradient.first,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Rank Progress Card ────────────────────────────────────────────────────────
class RankProgressCard extends StatelessWidget {
  final int level;
  final int xp;
  final int xpNeeded;
  final int xpProgress;
  final String rankName;

  const RankProgressCard({
    super.key,
    required this.level,
    required this.xp,
    required this.xpNeeded,
    required this.xpProgress,
    required this.rankName,
  });

  @override
  Widget build(BuildContext context) {
    final tier = RankTier.fromLevel(level);
    final nextTierIdx = RankTier.tiers.indexWhere((t) => t.minLevel > level);
    final nextTier = nextTierIdx >= 0 ? RankTier.tiers[nextTierIdx] : null;
    final progress = xpNeeded > 0 ? (xpProgress / xpNeeded).clamp(0.0, 1.0) : 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with badge
          Row(
            children: [
              RankBadge(level: level, size: 56, showLabel: false),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rankName,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        foreground: Paint()
                          ..shader = LinearGradient(
                            colors: tier.gradient,
                          ).createShader(const Rect.fromLTWH(0, 0, 200, 30)),
                      ),
                    ),
                    Text(
                      'Level $level · ${tier.name} Tier',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: tier.gradient),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$xp XP',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // XP progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tier.emoji,
                style: const TextStyle(fontSize: 14),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      builder: (_, val, __) => LinearProgressIndicator(
                        value: val,
                        minHeight: 10,
                        backgroundColor: AppColors.divider.withOpacity(0.4),
                        valueColor: AlwaysStoppedAnimation(tier.gradient.first),
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                nextTier?.emoji ?? '🏆',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            nextTier != null
                ? '$xpProgress / $xpNeeded XP to ${nextTier.name}'
                : 'MAX RANK ACHIEVED! 🎊',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
