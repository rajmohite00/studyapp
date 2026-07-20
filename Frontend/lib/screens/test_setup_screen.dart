import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/test_provider.dart';
import '../providers/auth_provider.dart';
import '../app_theme.dart';

// Fallback subject list when user has no profile subjects set
const _kDefaultSubjects = [
  'Mathematics', 'Biology', 'Chemistry', 'Physics', 'History',
  'English', 'Geography', 'Computer Science', 'Economics', 'Psychology',
  'Java', 'Python', 'JavaScript', 'Data Structures', 'Machine Learning',
];

// All test types stored as backend-safe values directly
const _kTestTypes = [
  (Icons.edit_note_rounded,  'Practice',     'Untimed casual practice',  'full_subject'),
  (Icons.timer_outlined,     'Mock Exam',    'Full timed simulation',    'mock_exam'),
  (Icons.book_outlined,      'Chapter Test', 'Specific topic focus',     'chapter_test'),
  (Icons.refresh_rounded,    'Revision',     'Review past mistakes',     'revision'),
];

class TestSetupScreen extends ConsumerStatefulWidget {
  const TestSetupScreen({super.key});
  @override
  ConsumerState<TestSetupScreen> createState() => _TestSetupState();
}

class _TestSetupState extends ConsumerState<TestSetupScreen> {
  // ── State ────────────────────────────────────────────────────────────────────
  String  _subject    = '';   // resolved in initState
  String  _testType   = 'full_subject';   // backend-safe default  String  _difficulty = 'medium';
  int     _qCount     = 20;
  int     _timer      = 0;
  bool    _generating = false;

  final _customCtrl = TextEditingController();
  bool _showCustomField = false;

  // ── Resolve subject synchronously (never empty) ───────────────────────────
  String _resolveSubject() {
    if (_subject.isNotEmpty) return _subject;
    try {
      final user = ref.read(authStateProvider).user;
      final subs = user?.profile.subjects ?? [];
      return subs.isNotEmpty ? subs.first : _kDefaultSubjects.first;
    } catch (_) {
      return _kDefaultSubjects.first;
    }
  }

  @override
  void initState() {
    super.initState();
    // Try to set subject immediately (synchronous path)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_subject.isEmpty) {
        setState(() => _subject = _resolveSubject());
      }
    });
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  // ── All 4 test types map 1:1 to backend enum ──────────────────────────────
  static const _typeMap = {
    'practice':     'full_subject',    // practice = full subject, untimed
    'full_subject': 'full_subject',
    'mock_exam':    'mock_exam',
    'chapter_test': 'chapter_test',
    'revision':     'revision',
    'topic_wise':   'topic_wise',
  };

  Future<void> _start() async {
    // 1. Resolve final subject (custom field overrides chip selection)
    final custom  = _customCtrl.text.trim();
    final subject = custom.isNotEmpty ? custom : _resolveSubject();

    if (subject.isEmpty) {
      _showErr('Please select a subject first.');
      return;
    }

    // 2. Map UI test type to backend enum value
    final backendType = _typeMap[_testType] ?? 'full_subject';

    setState(() => _generating = true);
    try {
      final test = await ref.read(testServiceProvider).createTest(
        subject:       subject,
        topics:        [],
        testType:      backendType,
        difficulty:    _difficulty,
        questionCount: _qCount,
        timerMinutes:  _timer,
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
      final type = e.runtimeType.toString();
      if (type.contains('DioException') || type.contains('DioError')) {
        final statusCode = (e as dynamic).response?.statusCode as int?;
        final data = (e as dynamic).response?.data;

        // Extract the most useful message from backend error shape
        if (data is Map) {
          final errorObj = data['error'];
          if (errorObj is Map) {
            // Validation details array → show first field error
            final details = errorObj['details'];
            if (details is List && details.isNotEmpty) {
              final first = details.first;
              if (first is Map) {
                return '${first['field'] ?? 'Input'}: ${first['message']}';
              }
            }
            final msg = errorObj['message']?.toString() ?? '';
            if (msg.isNotEmpty) return msg;
          }
          final msg = data['message']?.toString() ?? '';
          if (msg.isNotEmpty) return msg;
        }

        // HTTP status fallbacks
        if (statusCode == 422) return 'Invalid input. Check your subject and selections.';
        if (statusCode == 429) return 'AI is busy right now. Wait 1 minute and retry.';
        if (statusCode == 503) return 'AI service unavailable. Try again shortly.';
        if (statusCode == 500) return 'Server error. Please try again.';
        if (statusCode == 404) return 'Server waking up. Wait 10 seconds and retry.';

        // Connection/timeout errors
        final errMsg = e.toString().toLowerCase();
        if (errMsg.contains('timeout')) {
          return 'Request timed out. Try 10 questions for faster results.';
        }
        if (errMsg.contains('connection')) {
          return 'No internet connection. Check your network.';
        }
      }
    } catch (_) {}
    return 'Something went wrong. Please try again.';
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
    final user = ref.watch(authStateProvider).user;
    final profileSubjects = user?.profile.subjects ?? [];
    // Show profile subjects first, then defaults (deduplicated)
    final allSubjects = [
      ...profileSubjects,
      ..._kDefaultSubjects.where((s) => !profileSubjects.contains(s)),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final titleC = isDark ? const Color(0xFFE8E6F8) : AppColors.textPrimary;
    final subC   = isDark ? const Color(0xFF9B99B0) : AppColors.textSecondary;
    final borderC = isDark ? const Color(0xFF3A3850) : const Color(0xFFE8E6F0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: titleC),
          onPressed: () => context.pop(),
        ),
        title: Text('New Test', style: GoogleFonts.outfit(
            fontSize: 18, fontWeight: FontWeight.w700, color: titleC)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1,
                color: isDark ? const Color(0xFF2E2C42) : const Color(0xFFF0F0F5))),
      ),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── SUBJECT ─────────────────────────────────────
              _Label('Choose Subject', titleC),
              const SizedBox(height: 6),
              // Profile subjects badge if any
              if (profileSubjects.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 13, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text('Your subjects shown first',
                            style: GoogleFonts.outfit(fontSize: 11,
                                color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ]),
                ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  ...allSubjects.map((s) {
                    final isSel = _subject == s && !_showCustomField;
                    final isProfile = profileSubjects.contains(s);
                    return GestureDetector(
                      onTap: () => setState(() {
                        _subject = s;
                        _showCustomField = false;
                        _customCtrl.clear();
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primary : cardBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: isSel
                                  ? AppColors.primary
                                  : isProfile
                                      ? AppColors.primary.withValues(alpha: 0.35)
                                      : borderC),
                          boxShadow: isSel ? [BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.22),
                              blurRadius: 8, offset: const Offset(0, 3))] : [],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (isProfile && !isSel) ...[
                            const Icon(Icons.star_rounded,
                                size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                          ],
                          Text(s, style: GoogleFonts.outfit(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: isSel ? Colors.white : titleC)),
                        ]),
                      ),
                    );
                  }),
                  // "Other / Custom" chip
                  GestureDetector(
                    onTap: () => setState(() {
                      _showCustomField = !_showCustomField;
                      if (!_showCustomField) {
                        _customCtrl.clear();
                        if (_subject.isEmpty) _subject = allSubjects.first;
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: _showCustomField ? AppColors.accentOrange : cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: _showCustomField
                                ? AppColors.accentOrange
                                : borderC),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.add_rounded, size: 14,
                            color: _showCustomField ? Colors.white : subC),
                        const SizedBox(width: 4),
                        Text('Custom', style: GoogleFonts.outfit(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: _showCustomField ? Colors.white : subC)),
                      ]),
                    ),
                  ),
                ],
              ),

              // Custom subject text field (slides in when "Custom" is tapped)
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: _showCustomField
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: _customCtrl.text.isNotEmpty
                                    ? AppColors.primary
                                    : borderC,
                                width: _customCtrl.text.isNotEmpty ? 1.5 : 1),
                            boxShadow: [BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6, offset: const Offset(0, 2))],
                          ),
                          child: Row(children: [
                            Expanded(
                              child: TextField(
                                controller: _customCtrl,
                                autofocus: true,
                                style: GoogleFonts.outfit(
                                    fontSize: 14, color: titleC),
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: 'e.g. Fluid Mechanics, Sanskrit…',
                                  hintStyle: GoogleFonts.outfit(
                                      color: subC, fontSize: 14),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  prefixIcon: Icon(Icons.edit_outlined,
                                      size: 18, color: subC),
                                ),
                                onSubmitted: (v) {
                                  if (v.trim().isNotEmpty) {
                                    setState(() {
                                      _subject = v.trim();
                                    });
                                  }
                                },
                              ),
                            ),
                            if (_customCtrl.text.isNotEmpty)
                              GestureDetector(
                                onTap: () => setState(() {
                                  _subject = _customCtrl.text.trim();
                                  _showCustomField = false;
                                }),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Text('Use', style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                                ),
                              ),
                          ]),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // Show selected custom subject confirmation
              if (_subject.isNotEmpty
                  && !allSubjects.contains(_subject)
                  && !_showCustomField)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.accentOrange.withValues(alpha: 0.4)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 13, color: AppColors.accentOrange),
                        const SizedBox(width: 5),
                        Text(_subject, style: GoogleFonts.outfit(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: AppColors.accentOrange)),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => setState(() {
                            _subject = allSubjects.first;
                            _customCtrl.clear();
                          }),
                          child: const Icon(Icons.close_rounded,
                              size: 14, color: AppColors.accentOrange),
                        ),
                      ]),
                    ),
                  ]),
                ),
              const SizedBox(height: 28),

              // ── TEST TYPE ────────────────────────────────────
              _Label('Test Type', titleC),
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
                        color: sel ? AppColors.primaryLight : cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: sel ? AppColors.primary : borderC,
                            width: sel ? 1.5 : 1),
                        boxShadow: [BoxShadow(
                            color: sel
                                ? AppColors.primary.withValues(alpha: 0.10)
                                : Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(t.$1, size: 22,
                              color: sel ? AppColors.primary : subC),
                          const SizedBox(height: 8),
                          Text(t.$2, style: GoogleFonts.outfit(fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: sel ? AppColors.primary : titleC)),
                          Text(t.$3, style: GoogleFonts.outfit(fontSize: 11,
                              color: subC),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // ── DIFFICULTY ───────────────────────────────────
              _Label('Difficulty', titleC),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderC),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    ('easy',   'Easy',   const Color(0xFF10B981)),
                    ('medium', 'Medium', const Color(0xFFF59E0B)),
                    ('hard',   'Hard',   const Color(0xFFEF4444)),
                  ].map((d) {
                    final sel = _difficulty == d.$1;
                    return Expanded(child: GestureDetector(
                      onTap: () => setState(() => _difficulty = d.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: sel ? d.$3 : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(child: Text(d.$2,
                            style: GoogleFonts.outfit(fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: sel ? Colors.white : subC))),
                      ),
                    ));
                  }).toList(),
                ),
              ),
              const SizedBox(height: 28),

              // ── QUESTIONS ────────────────────────────────────
              _Label('Questions', titleC),
              const SizedBox(height: 12),
              Row(
                children: [10, 20, 30, 40].map((n) {
                  final sel = _qCount == n;
                  final isLast = n == 40;
                  return Expanded(child: Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _qCount = n),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primary : cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: sel ? AppColors.primary : borderC),
                          boxShadow: sel ? [BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.20),
                              blurRadius: 8, offset: const Offset(0, 3))] : [],
                        ),
                        child: Column(children: [
                          Text('$n', style: GoogleFonts.outfit(fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: sel ? Colors.white : titleC)),
                          Text('Qs', style: GoogleFonts.outfit(fontSize: 10,
                              color: sel ? Colors.white70 : subC)),
                        ]),
                      ),
                    ),
                  ));
                }).toList(),
              ),
              const SizedBox(height: 28),

              // ── TIME LIMIT ───────────────────────────────────
              _Label('Time Limit', titleC),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  (0, 'No Limit'), (15, '15 min'),
                  (30, '30 min'), (45, '45 min'), (60, '60 min'),
                ].map((t) {
                  final sel = _timer == t.$1;
                  return GestureDetector(
                    onTap: () => setState(() => _timer = t.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: sel ? AppColors.primary : borderC),
                      ),
                      child: Text(t.$2, style: GoogleFonts.outfit(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : titleC)),
                    ),
                  );
                }).toList(),
              ),
            ]),
          ),
        ),

        // ── START BUTTON ─────────────────────────────────
        Container(
          color: isDark ? AppColors.darkSurface : Colors.white,
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
          child: GestureDetector(
            onTap: _generating ? null : _start,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
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
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                else
                  const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(_generating ? 'Generating…' : 'Start Test',
                    style: GoogleFonts.outfit(fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _generating
                            ? AppColors.textSecondary
                            : Colors.white)),
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
  final Color color;
  const _Label(this.text, this.color);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.outfit(fontSize: 16,
          fontWeight: FontWeight.w700, color: color));
}
