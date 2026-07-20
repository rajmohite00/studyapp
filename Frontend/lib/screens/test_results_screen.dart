import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/test_provider.dart';
import '../models/test_model.dart';
import '../app_theme.dart';
import '../widgets/shimmer_box.dart';

class TestResultsScreen extends ConsumerStatefulWidget {
  final String testId;
  const TestResultsScreen({super.key, required this.testId});
  @override
  ConsumerState<TestResultsScreen> createState() => _TestResultsState();
}

class _TestResultsState extends ConsumerState<TestResultsScreen> {
  late Future<TestModel> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(testServiceProvider).getTest(widget.testId);
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(analysisProvider.notifier).analyse(widget.testId));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<TestModel>(
    future: _future,
    builder: (ctx, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              const SizedBox(height: 20),
              ShimmerBox(height: 240, borderRadius: BorderRadius.circular(22)),
              const SizedBox(height: 14),
              ShimmerBox(height: 88, borderRadius: BorderRadius.circular(16)),
              const SizedBox(height: 10),
              ShimmerBox(height: 120, borderRadius: BorderRadius.circular(16)),
            ]),
          )),
        );
      }
      if (snap.hasError || snap.data == null) {
        return Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Could not load results',
              style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () => context.go('/home/tests'),
              child: Text('Go Back', style: GoogleFonts.outfit())),
        ])));
      }
      return _ResultsBody(test: snap.data!);
    },
  );
}

// ── Results Body ──────────────────────────────────────────────────────────────
class _ResultsBody extends ConsumerWidget {
  final TestModel test;
  const _ResultsBody({required this.test});

  Color get _gradeColor {
    if (test.percentage >= 80) return const Color(0xFF10B981);
    if (test.percentage >= 60) return AppColors.primary;
    if (test.percentage >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(analysisProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home/tests'),
        ),
        title: Text('Test Result', style: GoogleFonts.outfit(
            fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, color: AppColors.textSecondary),
            onPressed: () => context.push('/tests/report/${test.id}'),
          ),
        ],
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFFF0F0F5))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Score Card ────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: _gradeColor.withValues(alpha: 0.12),
                  blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: Column(children: [
              Text('${test.subject} — ${test.difficulty[0].toUpperCase()}${test.difficulty.substring(1)}',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              // Circular ring
              SizedBox(
                width: 160, height: 160,
                child: Stack(alignment: Alignment.center, children: [
                  CustomPaint(
                    size: const Size(160, 160),
                    painter: _RingPainter(
                        value: test.percentage / 100,
                        trackColor: AppColors.primaryLight,
                        arcColor: _gradeColor,
                        strokeWidth: 14),
                  ),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('${test.percentage}%', style: GoogleFonts.outfit(
                        fontSize: 34, fontWeight: FontWeight.w900, color: _gradeColor)),
                    Text(test.grade, style: GoogleFonts.outfit(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
                  ]),
                ]),
              ),
              const SizedBox(height: 20),
              // Correct / Wrong row
              Row(children: [
                Expanded(child: _ScoreChip(
                    label: 'Correct', value: '${test.correct}',
                    color: const Color(0xFF10B981))),
                const SizedBox(width: 12),
                Expanded(child: _ScoreChip(
                    label: 'Wrong', value: '${test.wrong}',
                    color: const Color(0xFFEF4444))),
                const SizedBox(width: 12),
                Expanded(child: _ScoreChip(
                    label: 'Skipped', value: '${test.skipped}',
                    color: const Color(0xFFF59E0B))),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Stats row ─────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Row(children: [
              _StatCol(icon: Icons.timer_outlined, label: 'Time Taken',
                  value: _fmtTime(test.timeSpentSecs)),
              _VDivider(),
              _StatCol(icon: Icons.gps_fixed_rounded, label: 'Accuracy',
                  value: '${test.accuracy}%'),
              _VDivider(),
              _StatCol(icon: Icons.speed_rounded, label: 'Avg/Q',
                  value: '${test.avgTimePerQuestion}s'),
            ]),
          ),
          const SizedBox(height: 16),

          // ── AI Insight ────────────────────────────────
          if (analysis.isLoading)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: AppColors.primaryLight, borderRadius: BorderRadius.circular(18)),
              child: Row(children: [
                const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                const SizedBox(width: 12),
                Text('Generating AI insights…', style: GoogleFonts.outfit(
                    fontSize: 13, color: AppColors.primary)),
              ]),
            )
          else if (analysis.test?.aiAnalysis != null) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(
                      gradient: AppColors.heroGradient, shape: BoxShape.circle),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('AI Insight', style: GoogleFonts.outfit(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text(
                    analysis.test!.aiAnalysis!.motivationMessage.isNotEmpty
                        ? analysis.test!.aiAnalysis!.motivationMessage
                        : analysis.test!.aiAnalysis!.personalizedFeedback,
                    style: GoogleFonts.outfit(fontSize: 13,
                        color: AppColors.primaryDark, height: 1.5),
                  ),
                ])),
              ]),
            ),
          ],
          const SizedBox(height: 16),

          // ── Strong Topics ─────────────────────────────
          if (analysis.test?.aiAnalysis?.strongTopics.isNotEmpty == true) ...[
            _TopicsSection(
              title: 'Strong Topics',
              icon: Icons.check_circle_outline_rounded,
              iconColor: const Color(0xFF10B981),
              topics: analysis.test!.aiAnalysis!.strongTopics,
              chipColor: const Color(0xFFECFDF5),
              textColor: const Color(0xFF10B981),
            ),
            const SizedBox(height: 16),
          ],

          // ── Weak Topics ───────────────────────────────
          if (analysis.test?.aiAnalysis?.weakTopics.isNotEmpty == true) ...[
            _TopicsSection(
              title: 'Needs Review',
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFEF4444),
              topics: analysis.test!.aiAnalysis!.weakTopics,
              chipColor: const Color(0xFFFFF0F0),
              textColor: const Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
          ],

          // ── Action buttons ────────────────────────────
          GestureDetector(
            onTap: () => context.push('/tests/report/${test.id}'),
            child: Container(
              width: double.infinity, height: 52,
              decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 12, offset: const Offset(0, 4))]),
              child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.description_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('View Full Report', style: GoogleFonts.outfit(
                    fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ])),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => context.push('/tests/setup'),
            child: Container(
              width: double.infinity, height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.40), width: 1.5),
              ),
              child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.replay_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text('Take Another Test', style: GoogleFonts.outfit(
                    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ])),
            ),
          ),
        ]),
      ),
    );
  }

  static String _fmtTime(int secs) {
    if (secs < 60) return '${secs}s';
    final m = secs ~/ 60, s = secs % 60;
    return '${m}m ${s}s';
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────
class _ScoreChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _ScoreChip({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Text(value, style: GoogleFonts.outfit(fontSize: 22,
          fontWeight: FontWeight.w800, color: color)),
      Text(label, style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary)),
    ]),
  );
}

class _StatCol extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _StatCol({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(height: 6),
      Text(value, style: GoogleFonts.outfit(fontSize: 16,
          fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      Text(label, style: GoogleFonts.outfit(fontSize: 11,
          color: AppColors.textSecondary), textAlign: TextAlign.center),
    ]),
  );
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 44, color: const Color(0xFFF0F0F5));
}

class _TopicsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor, chipColor, textColor;
  final List<String> topics;
  const _TopicsSection({required this.title, required this.icon,
      required this.iconColor, required this.chipColor,
      required this.textColor, required this.topics});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Text(title, style: GoogleFonts.outfit(fontSize: 15,
            fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ]),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8,
        children: topics.map((t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: chipColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: textColor.withValues(alpha: 0.25))),
          child: Text(t, style: GoogleFonts.outfit(fontSize: 12,
              fontWeight: FontWeight.w600, color: textColor)),
        )).toList(),
      ),
    ]),
  );
}

// ── Ring Painter ──────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double value;
  final Color trackColor, arcColor;
  final double strokeWidth;
  const _RingPainter({required this.value, required this.trackColor,
      required this.arcColor, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    final arc = Paint()
      ..color = arcColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * value.clamp(0, 1), false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}
