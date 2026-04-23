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
            title: const Text('End Session?'),
            content: const Text('Your progress will be saved.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('End', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
        return confirm ?? false;
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () async {
                        await ref.read(sessionProvider.notifier).endSession();
                        if (context.mounted) context.go('/home');
                      },
                    ),
                    Chip(
                      label: Text(session['subject'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                    IconButton(
                      icon: const Icon(Icons.flag_outlined, color: Colors.white),
                      onPressed: () => ref.read(sessionProvider.notifier).recordInterruption(),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(timeStr, style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        Text(isPaused ? 'PAUSED' : 'STUDYING', style: const TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 3)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Interruptions: ${state.interruptions}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CircleBtn(
                      icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      onTap: () => isPaused
                          ? ref.read(sessionProvider.notifier).resumeSession()
                          : ref.read(sessionProvider.notifier).pauseSession(),
                    ),
                    const SizedBox(width: 24),
                    _CircleBtn(
                      icon: Icons.stop_rounded,
                      color: AppColors.accent,
                      onTap: () async {
                        final sess = await ref.read(sessionProvider.notifier).endSession();
                        if (context.mounted) context.pushReplacement('/session/summary', extra: sess?.toJson() ?? {});
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
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  const _CircleBtn({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(color: color ?? Colors.white.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 36),
        ),
      );
}
