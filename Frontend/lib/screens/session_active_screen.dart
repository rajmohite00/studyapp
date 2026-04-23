import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/session_provider.dart';
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('End Session?', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Your progress will be saved.', style: TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE07A5F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('End'),
              ),
            ],
          ),
        );
        return confirm ?? false;
      },
      child: Scaffold(
        // Use a subtle gradient background instead of flat primary
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3A7BD5), Color(0xFF2ECCB6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // ── Top bar ──────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _TopBtn(
                        icon: Icons.close_rounded,
                        onTap: () async {
                          await ref.read(sessionProvider.notifier).endSession();
                          if (context.mounted) context.go('/home');
                        },
                      ),
                      // Subject chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Text(
                          session['subject'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      _TopBtn(
                        icon: Icons.flag_outlined,
                        onTap: () => ref.read(sessionProvider.notifier).recordInterruption(),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // ── Status label ─────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      isPaused ? 'PAUSED' : 'STUDYING',
                      key: ValueKey(isPaused),
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Timer ring ───────────────────────────
                  Container(
                    width: 230,
                    height: 230,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40, spreadRadius: 0),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        timeStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 54,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Interruptions ────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '⚡ ${state.interruptions} interruption${state.interruptions != 1 ? 's' : ''}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),

                  const Spacer(),

                  // ── Controls ──────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CircleBtn(
                        icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        label: isPaused ? 'Resume' : 'Pause',
                        onTap: () => isPaused
                            ? ref.read(sessionProvider.notifier).resumeSession()
                            : ref.read(sessionProvider.notifier).pauseSession(),
                      ),
                      const SizedBox(width: 28),
                      _CircleBtn(
                        icon: Icons.stop_rounded,
                        label: 'Finish',
                        color: Colors.white.withOpacity(0.25),
                        onTap: () async {
                          final sess = await ref.read(sessionProvider.notifier).endSession();
                          if (context.mounted) {
                            context.pushReplacement('/session/summary', extra: sess?.toJson() ?? {});
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TopBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String label;
  final Color? color;
  const _CircleBtn({required this.icon, required this.onTap, required this.label, this.color});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: color ?? Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
              ),
              child: Icon(icon, color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      );
}
