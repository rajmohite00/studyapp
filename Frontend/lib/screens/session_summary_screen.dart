import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../widgets/animations.dart';

class SessionSummaryScreen extends StatefulWidget {
  final Map<String, dynamic> session;
  const SessionSummaryScreen({super.key, required this.session});

  @override
  State<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends State<SessionSummaryScreen>
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

    // Delay so it fires after screen slide-in
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _badgeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _badgeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subject = widget.session['subject'] ?? '';
    final mins = widget.session['actualDurationMinutes'] ?? 0;
    final focus = (widget.session['focusScore'] ?? 0).toDouble();
    final interruptions = widget.session['interruptions'] ?? 0;
    final focusColor = _focusColor(focus);
    final focusPct = (focus / 100).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            children: [
              // ── Animated badge ────────────────────────────────────────
              ScaleTransition(
                scale: _badgeScale,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: focusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.textPrimary, width: 3),
                    boxShadow: const [BoxShadow(color: AppColors.textPrimary, offset: Offset(4, 4))],
                  ),
                  child: Icon(_focusIcon(focus), color: AppColors.textPrimary, size: 44),
                ),
              ),
              const SizedBox(height: 24),

              // ── Title ─────────────────────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 350),
                child: Text(
                  'Session Complete! 🎉',
                  style: GoogleFonts.syne(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 6),
              FadeSlideIn(
                delay: const Duration(milliseconds: 400),
                child: Text(
                  subject,
                  style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 32),

              // ── Stats card ────────────────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 450),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.textPrimary, width: 3),
                    boxShadow: const [BoxShadow(color: AppColors.textPrimary, offset: Offset(4, 4))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatBox(label: 'Duration', value: '${mins}m', icon: Icons.timer_rounded, color: AppColors.primary),
                      Container(width: 1.5, height: 44, color: AppColors.divider.withOpacity(0.4)),
                      _StatBox(label: 'Focus', value: '${focus.toInt()}', icon: Icons.bolt_rounded, color: AppColors.accentGreen),
                      Container(width: 1.5, height: 44, color: AppColors.divider.withOpacity(0.4)),
                      _StatBox(label: 'Breaks', value: '$interruptions', icon: Icons.notifications_off_outlined, color: AppColors.accentOrange),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Focus progress bar ────────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 500),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.textPrimary, width: 2),
                    boxShadow: const [BoxShadow(color: AppColors.textPrimary, offset: Offset(3, 3))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _focusLabel(focus),
                            style: TextStyle(color: focusColor, fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          Text(
                            '${focus.toInt()}%',
                            style: GoogleFonts.syne(color: focusColor, fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AnimatedProgressBar(value: focusPct, color: focusColor, height: 10),
                      const SizedBox(height: 12),
                      Text(
                        _focusTip(focus, interruptions),
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // ── Actions ───────────────────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 560),
                child: Column(
                  children: [
                    PressButton(
                      onTap: () => context.go('/home'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.textPrimary, width: 3),
                          boxShadow: const [BoxShadow(color: AppColors.textPrimary, offset: Offset(4, 4))],
                        ),
                        child: Text(
                          'Back to Home',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    PressButton(
                      onTap: () => context.pushReplacement('/session/setup'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.textPrimary, width: 2.5),
                          boxShadow: const [BoxShadow(color: AppColors.textPrimary, offset: Offset(3, 3))],
                        ),
                        child: Text(
                          'Start Another Session',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
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
          : Icons.info_rounded;

  String _focusLabel(double f) => f >= 80
      ? 'Excellent Focus! ⭐'
      : f >= 60
          ? 'Good Focus 👍'
          : f >= 40
              ? 'Fair Focus'
              : 'Poor Focus — keep going!';

  String _focusTip(double f, int i) => i == 0
      ? 'Zero interruptions — incredible discipline! Keep it up.'
      : 'You had $i interruption${i != 1 ? 's' : ''}. Try enabling Do Not Disturb next time.';
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.syne(fontSize: 22, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ],
      );
}
