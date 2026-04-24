import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/session_provider.dart';
import '../providers/analytics_provider.dart';
import '../app_theme.dart';

class SessionActiveScreen extends ConsumerWidget {
  final Map<String, dynamic> session;
  const SessionActiveScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionProvider);
    final elapsed = state.elapsed;
    final isPaused = state.status == SessionStatus.paused;

    final h = elapsed.inHours;
    final m = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final timeStr = h > 0 ? '$h:$m:$s' : '$m:$s';

    return WillPopScope(
      onWillPop: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.textPrimary, width: 2),
            ),
            title: const Text('End Session?', style: TextStyle(fontWeight: FontWeight.w900)),
            content: const Text('Your progress will be saved.', style: TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE07A5F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppColors.textPrimary, width: 1.5),
                  ),
                ),
                child: const Text('End', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        );
        return confirm ?? false;
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF0EA5E9), Color(0xFF2ECCB6)],
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
                  // ── TOP BAR ──────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _RoundBtn(icon: Icons.close_rounded, onTap: () async {
                        await ref.read(sessionProvider.notifier).endSession();
                        // Invalidate all analytics so home/analytics screens refresh
                        ref.invalidate(dashboardProvider);
                        ref.invalidate(subjectBreakdownProvider);
                        ref.invalidate(streakProvider);
                        ref.invalidate(heatmapProvider);
                        ref.invalidate(weeklyReportProvider);
                        if (context.mounted) context.go('/home');
                      }),
                      // Subject badge
                      Flexible(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                          ),
                          child: Text(
                            session['subject'] ?? '',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      _RoundBtn(icon: Icons.flag_outlined, onTap: () => ref.read(sessionProvider.notifier).recordInterruption()),
                    ],
                  ),

                  const Spacer(),

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

                  // ── TIMER RING ───────────────────────────
                  Container(
                    width: 240, height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.12),
                      border: Border.all(color: Colors.white.withOpacity(0.25), width: 2.5),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 40)],
                    ),
                    child: Center(
                      child: Text(
                        timeStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Interruptions badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      '⚡  ${state.interruptions} interruption${state.interruptions != 1 ? 's' : ''}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),

                  const Spacer(),

                  // ── CONTROLS ─────────────────────────────
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
                        color: Colors.white.withOpacity(0.3),
                        onTap: () async {
                          final sess = await ref.read(sessionProvider.notifier).endSession();
                          // Invalidate all analytics so home/analytics screens refresh
                          ref.invalidate(dashboardProvider);
                          ref.invalidate(subjectBreakdownProvider);
                          ref.invalidate(streakProvider);
                          ref.invalidate(heatmapProvider);
                          ref.invalidate(weeklyReportProvider);
                          if (context.mounted) context.pushReplacement('/session/summary', extra: sess?.toJson() ?? {});
                        },
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

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );
}

class _LabeledBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String label;
  final Color? color;
  const _LabeledBtn({required this.icon, required this.onTap, required this.label, this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: color ?? Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
              ),
              child: Icon(icon, color: Colors.white, size: 38),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
