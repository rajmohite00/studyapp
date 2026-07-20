import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/test_provider.dart';
import '../app_theme.dart';

const _kSubjects = [
  'Mathematics','Biology','Chemistry','Physics','History',
  'English','Geography','Computer Science','Economics','Psychology',
  'Java','Python','JavaScript','Data Structures','Machine Learning',
];

const _kTestTypes = [
  (Icons.edit_note_rounded,    'Practice',     'Untimed casual practice',   'practice'),
  (Icons.timer_outlined,       'Mock Exam',    'Full timed simulation',      'mock_exam'),
  (Icons.book_outlined,        'Chapter Test', 'Specific topic focus',       'chapter_test'),
  (Icons.refresh_rounded,      'Revision',     'Review past mistakes',       'revision'),
];

class TestSetupScreen extends ConsumerStatefulWidget {
  const TestSetupScreen({super.key});
  @override
  ConsumerState<TestSetupScreen> createState() => _TestSetupState();
}

class _TestSetupState extends ConsumerState<TestSetupScreen> {
  String _subject    = 'Mathematics';
  String _testType   = 'practice';
  String _difficulty = 'medium';
  int    _qCount     = 20;
  int    _timer      = 30;
  bool   _generating = false;

  Future<void> _start() async {
    setState(() => _generating = true);
    try {
      final test = await ref.read(testServiceProvider).createTest(
        subject: _subject,
        topics: [],
        testType: _testType == 'practice' ? 'full_subject' : _testType,
        difficulty: _difficulty,
        questionCount: _qCount,
        timerMinutes: _timer,
      );
      if (!mounted) return;
      ref.invalidate(activeDraftProvider);
      context.go('/tests/active/${test.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _generating = false);
      _showErr(_parseErr(e));
    }
  }

  String _parseErr(dynamic e) {
    try {
      if (e.runtimeType.toString().contains('DioException')) {
        final data = (e as dynamic).response?.data;
        if (data is Map && data['error'] is Map) {
          return data['error']['message']?.toString() ?? 'Failed to generate test.';
        }
        final code = (e as dynamic).response?.statusCode;
        if (code == 429) return 'AI rate limit. Wait 1 minute and retry.';
        if (code == 500) return 'Server error. Please retry.';
      }
    } catch (_) {}
    return 'Failed to generate test. Try again.';
  }

  void _showErr(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit(fontSize: 13)),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('New Test', style: GoogleFonts.outfit(
            fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFFF0F0F5))),
      ),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Subject ─────────────────────────────────
              _Label('Choose Subject'),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8,
                children: _kSubjects.map((s) {
                  final sel = _subject == s;
                  return GestureDetector(
                    onTap: () => setState(() => _subject = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: sel ? AppColors.primary : const Color(0xFFE8E6F0)),
                        boxShadow: sel ? [BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.22),
                            blurRadius: 8, offset: const Offset(0, 3))] : [],
                      ),
                      child: Text(s, style: GoogleFonts.outfit(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : AppColors.textPrimary)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // ── Test Type ────────────────────────────────
              _Label('Test Type'),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12, mainAxisSpacing: 12,
                childAspectRatio: 1.55,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _kTestTypes.map((t) {
                  final sel = _testType == t.$4;
                  return GestureDetector(
                    onTap: () => setState(() => _testType = t.$4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primaryLight : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: sel ? AppColors.primary : const Color(0xFFE8E6F0),
                            width: sel ? 1.5 : 1),
                        boxShadow: [BoxShadow(
                            color: sel ? AppColors.primary.withValues(alpha: 0.10)
                                : Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(t.$1, size: 22,
                            color: sel ? AppColors.primary : AppColors.textSecondary),
                        const SizedBox(height: 8),
                        Text(t.$2, style: GoogleFonts.outfit(fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: sel ? AppColors.primary : AppColors.textPrimary)),
                        Text(t.$3, style: GoogleFonts.outfit(fontSize: 11,
                            color: AppColors.textSecondary),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // ── Difficulty ───────────────────────────────
              _Label('Difficulty'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8E6F0)),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(children: ['easy','medium','hard'].map((d) {
                  final sel = _difficulty == d;
                  final colors = {'easy': const Color(0xFF10B981),
                    'medium': const Color(0xFFF59E0B), 'hard': const Color(0xFFEF4444)};
                  final c = colors[d]!;
                  return Expanded(child: GestureDetector(
                    onTap: () => setState(() => _difficulty = d),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: sel ? c : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(child: Text(
                        d[0].toUpperCase() + d.substring(1),
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : AppColors.textSecondary),
                      )),
                    ),
                  ));
                }).toList()),
              ),
              const SizedBox(height: 28),

              // ── Questions ────────────────────────────────
              _Label('Questions'),
              const SizedBox(height: 12),
              Row(children: [10, 20, 30, 40].map((n) {
                final sel = _qCount == n;
                return Expanded(child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _qCount = n),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: sel ? AppColors.primary : const Color(0xFFE8E6F0)),
                      ),
                      child: Column(children: [
                        Text('$n', style: GoogleFonts.outfit(fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: sel ? Colors.white : AppColors.textPrimary)),
                        Text('Qs', style: GoogleFonts.outfit(fontSize: 10,
                            color: sel ? Colors.white70 : AppColors.textSecondary)),
                      ]),
                    ),
                  ),
                ));
              }).toList()),
              const SizedBox(height: 28),

              // ── Time Limit ───────────────────────────────
              _Label('Time Limit'),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8,
                children: [(0,'No Limit'),(15,'15 min'),(30,'30 min'),(45,'45 min'),(60,'60 min')]
                    .map((t) {
                  final sel = _timer == t.$1;
                  return GestureDetector(
                    onTap: () => setState(() => _timer = t.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: sel ? AppColors.primary : const Color(0xFFE8E6F0)),
                      ),
                      child: Text(t.$2, style: GoogleFonts.outfit(fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : AppColors.textPrimary)),
                    ),
                  );
                }).toList(),
              ),
            ]),
          ),
        ),

        // ── Start Button ─────────────────────────────────
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
          child: GestureDetector(
            onTap: _generating ? null : _start,
            child: Container(
              width: double.infinity, height: 54,
              decoration: BoxDecoration(
                gradient: _generating ? null : AppColors.heroGradient,
                color: _generating ? AppColors.divider : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _generating ? [] : [BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.30),
                    blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (_generating)
                  const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                else
                  const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(_generating ? 'Generating…' : 'Start Test',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700,
                        color: _generating ? AppColors.textSecondary : Colors.white)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary));
}
