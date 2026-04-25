import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../widgets/animations.dart';
import '../providers/analytics_provider.dart';

class SessionSummaryScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> session;
  const SessionSummaryScreen({super.key, required this.session});

  @override
  ConsumerState<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends ConsumerState<SessionSummaryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _badgeCtrl;
  late final Animation<double> _badgeScale;

  @override
  void initState() {
    super.initState();
    _badgeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _badgeScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.95), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _badgeCtrl, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _badgeCtrl.forward();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLevelUp();
    });
  }

  @override
  void dispose() {
    _badgeCtrl.dispose();
    super.dispose();
  }

  void _checkLevelUp() {
    if (!mounted) return;
    final gResult = widget.session['gamificationResult'];
    if (gResult != null && gResult['leveledUp'] == true) {
      final newLevel = gResult['newLevel'];
      final newRank = gResult['newRank'];
      showDialog(
        context: context,
        builder: (c) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: AppColors.accentOrange.withValues(alpha: 0.3), blurRadius: 40, spreadRadius: 10),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 60)),
                const SizedBox(height: 16),
                Text(
                  'LEVEL UP!',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accentOrange,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You are now Level $newLevel',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Rank: $newRank',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(c).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Awesome!', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // XP calculation mirrors backend gamificationService
  int _calcXP(int mins, int streak) {
    int xp = mins * 10;
    if (streak > 0) xp += 50 * streak.clamp(1, 10);
    return xp;
  }

  @override
  Widget build(BuildContext context) {
    final subject = widget.session['subject'] ?? '';
    final mins = (widget.session['actualDurationMinutes'] ?? 0) as int;
    final secs = (widget.session['durationSeconds'] ?? 0) as int;
    final plannedMins = (widget.session['plannedDurationMinutes'] ?? 0) as int;
    final focus = ((widget.session['focusScore'] ?? 0) as num).toDouble();
    final interruptions = (widget.session['interruptions'] ?? 0) as int;
    final focusColor = _focusColor(focus);
    final focusPct = (focus / 100).clamp(0.0, 1.0);

    // Overtime calculation
    final extraMins = plannedMins > 0 ? (mins - plannedMins) : 0;
    final hasOvertime = extraMins > 0;

    // Live streak + XP from provider (already invalidated in session_active_screen)
    final dashAsync = ref.watch(dashboardProvider);
    final streak = dashAsync.valueOrNull?.streak?.current ?? 0;

    final gResult = widget.session['gamificationResult'];
    final xpEarned = gResult != null ? (gResult['xpEarned'] as int) : _calcXP(mins, streak);
    final coinsEarned = (xpEarned / 10).floor();

    // Format time nicely: show sec if < 1 min
    final timeDisplay = mins > 0 ? '${mins}m' : '${secs}s';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            children: [
              // ── Animated badge ─────────────────────────────────────────
              ScaleTransition(
                scale: _badgeScale,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [focusColor.withValues(alpha: 0.8), focusColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: focusColor.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: Icon(_focusIcon(focus), color: Colors.white, size: 48),
                ),
              ),
              const SizedBox(height: 20),

              // ── Title ──────────────────────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 350),
                child: Text(
                  'Session Complete! 🎉',
                  style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              FadeSlideIn(
                delay: const Duration(milliseconds: 400),
                child: Text(
                  subject,
                  style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 24),

              // ── Overtime banner ────────────────────────────────────────
              if (hasOvertime)
                FadeSlideIn(
                  delay: const Duration(milliseconds: 420),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF10B981)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: const Color(0xFF059669).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You studied $extraMins min extra!',
                                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                              Text(
                                'Incredible dedication — keep pushing! 🚀',
                                style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Stats card ─────────────────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 450),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatBox(label: 'Duration', value: timeDisplay, icon: Icons.timer_rounded, color: AppColors.primary),
                      Container(width: 1, height: 48, color: AppColors.divider),
                      _StatBox(label: 'Focus', value: '${focus.toInt()}%', icon: Icons.bolt_rounded, color: focusColor),
                      Container(width: 1, height: 48, color: AppColors.divider),
                      _StatBox(label: 'Breaks', value: '$interruptions', icon: Icons.pause_circle_outline_rounded, color: AppColors.accentOrange),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── XP + Streak reward card ─────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 490),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.accentTeal.withValues(alpha: 0.08)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _RewardChip(icon: '⚡', label: '+$xpEarned XP', color: const Color(0xFFF59E0B)),
                      Container(width: 1, height: 36, color: AppColors.divider),
                      _RewardChip(
                        icon: '🔥',
                        label: streak > 0 ? '$streak day streak!' : 'Keep it up!',
                        color: AppColors.accentOrange,
                      ),
                      Container(width: 1, height: 36, color: AppColors.divider),
                      _RewardChip(
                        icon: '🪙',
                        label: '+$coinsEarned coins',
                        color: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Focus bar ──────────────────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 530),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _focusLabel(focus),
                            style: GoogleFonts.outfit(color: focusColor, fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          Text(
                            '${focus.toInt()}%',
                            style: GoogleFonts.outfit(color: focusColor, fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AnimatedProgressBar(value: focusPct, color: focusColor, height: 10),
                      const SizedBox(height: 10),
                      Text(
                        _focusTip(focus, interruptions),
                        style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Actions ────────────────────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 580),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => context.go('/home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Text('Back to Home', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => context.pushReplacement('/session/setup'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Start Another Session', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _focusColor(double f) => f >= 80
      ? AppColors.accentGreen
      : f >= 60
          ? AppColors.primary
          : f >= 40
              ? AppColors.accentOrange
              : AppColors.accent;

  IconData _focusIcon(double f) => f >= 80
      ? Icons.star_rounded
      : f >= 60
          ? Icons.thumb_up_rounded
          : f >= 40
              ? Icons.sentiment_neutral_rounded
              : Icons.info_rounded;

  String _focusLabel(double f) => f >= 80
      ? 'Excellent Focus! ⭐'
      : f >= 60
          ? 'Good Focus 👍'
          : f >= 40
              ? 'Fair Focus'
              : 'Poor Focus — keep going!';

  String _focusTip(double f, int i) {
    if (i == 0) return 'Zero interruptions — incredible discipline! Keep it up.';
    if (i <= 2) return 'You had $i interruption${i != 1 ? 's' : ''}. Great effort — try Do Not Disturb next time.';
    return 'You had $i interruptions. A quiet space and phone-free sessions will boost your score significantly!';
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.3)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ],
      );
}

class _RewardChip extends StatelessWidget {
  final String icon, label;
  final Color color;
  const _RewardChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      );
}
