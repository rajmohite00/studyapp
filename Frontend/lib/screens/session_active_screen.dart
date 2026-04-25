import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/session_provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/gamification_provider.dart';
import '../app_theme.dart';

class SessionActiveScreen extends ConsumerWidget {
  final Map<String, dynamic> session;
  const SessionActiveScreen({super.key, required this.session});

  Future<void> _finishAndRefresh(WidgetRef ref, BuildContext context, {bool goHome = false}) async {
    final sess = await ref.read(sessionProvider.notifier).endSession();
    if (!context.mounted) return;
    
    // Navigate immediately
    if (goHome) {
      context.go('/home');
    } else {
      context.pushReplacement('/session/summary', extra: sess?.toJson() ?? {});
    }

    // REFRESH INSTANTLY
    ref.invalidate(dashboardProvider);
    ref.invalidate(gamificationStateProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionProvider);
    final elapsed = state.elapsed;
    final isPaused = state.status == SessionStatus.paused;
    final sessionData = session;

    // Planned duration from session data
    final plannedMins = (sessionData['plannedDurationMinutes'] ?? 25) as int;
    final plannedDuration = Duration(minutes: plannedMins);

    // Overtime detection
    final isOvertime = elapsed > plannedDuration;
    final overtime = isOvertime ? elapsed - plannedDuration : Duration.zero;

    // Format main timer
    String _fmt(Duration d) {
      final h = d.inHours;
      final m = (d.inMinutes % 60).toString().padLeft(2, '0');
      final s = (d.inSeconds % 60).toString().padLeft(2, '0');
      return h > 0 ? '$h:$m:$s' : '$m:$s';
    }

    final timeStr = _fmt(elapsed);
    final overtimeStr = '+${_fmt(overtime)}';

    return WillPopScope(
      onWillPop: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('End Session?', style: TextStyle(fontWeight: FontWeight.w900)),
            content: const Text('Your progress will be saved.', style: TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE07A5F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('End', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        );
        if (confirm == true) await _finishAndRefresh(ref, context, goHome: true);
        return false; // we handle navigation manually
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isOvertime
                  ? [const Color(0xFF059669), const Color(0xFF10B981), const Color(0xFF34D399)] // green for overtime
                  : [const Color(0xFF2563EB), const Color(0xFF0EA5E9), const Color(0xFF2ECCB6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // ── TOP BAR ───────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _RoundBtn(
                        icon: Icons.close_rounded,
                        onTap: () => _finishAndRefresh(ref, context, goHome: true),
                      ),
                      // Subject badge
                      Flexible(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                          ),
                          child: Text(
                            session['subject'] ?? '',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      _RoundBtn(
                        icon: Icons.flag_outlined,
                        onTap: () => ref.read(sessionProvider.notifier).recordInterruption(),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Overtime badge (shown when past planned time)
                  if (isOvertime) ...[
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Container(
                        key: const ValueKey('overtime'),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                        ),
                        child: Text(
                          '🌟 OVERTIME  $overtimeStr',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    // Status label
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        isPaused ? '⏸  PAUSED' : '▶  STUDYING',
                        key: ValueKey(isPaused),
                        style: const TextStyle(color: Colors.white60, fontSize: 11, letterSpacing: 4, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── TIMER RING ────────────────────────────
                  Container(
                    width: 240, height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: isOvertime ? 0.18 : 0.12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2.5),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 40)],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timeStr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          if (!isOvertime) ...[
                            const SizedBox(height: 4),
                            Text(
                              'of ${plannedMins}m planned',
                              style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Interruptions badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      '⚡  ${state.interruptions} interruption${state.interruptions != 1 ? 's' : ''}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),

                  const Spacer(),

                  // ── CONTROLS ──────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LabeledBtn(
                        icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        label: isPaused ? 'Resume' : 'Pause',
                        onTap: () => isPaused
                            ? ref.read(sessionProvider.notifier).resumeSession()
                            : ref.read(sessionProvider.notifier).pauseSession(),
                      ),
                      const SizedBox(width: 32),
                      _LabeledBtn(
                        icon: Icons.stop_rounded,
                        label: 'Finish',
                        color: Colors.white.withValues(alpha: 0.3),
                        onTap: () => _finishAndRefresh(ref, context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundBtn({required this.icon, required this.onTap});
  @override
  State<_RoundBtn> createState() => _RoundBtnState();
}

class _RoundBtnState extends State<_RoundBtn> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
    _scale = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) {
          HapticFeedback.lightImpact();
          _ctrl.forward();
        },
        onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Icon(widget.icon, color: Colors.white, size: 20),
          ),
        ),
      );
}

class _LabeledBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String label;
  final Color? color;
  const _LabeledBtn({required this.icon, required this.onTap, required this.label, this.color});
  @override
  State<_LabeledBtn> createState() => _LabeledBtnState();
}

class _LabeledBtnState extends State<_LabeledBtn> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) {
          HapticFeedback.mediumImpact();
          _ctrl.forward();
        },
        onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: Column(
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: widget.color ?? Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                  boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.1), blurRadius: 16, spreadRadius: 2)],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 38),
              ),
              const SizedBox(height: 8),
              Text(widget.label, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}
