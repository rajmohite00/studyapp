import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/test_provider.dart';
import '../providers/auth_provider.dart';
import '../app_theme.dart';

const _kDefaultSubjects = [
  'Mathematics', 'Biology', 'Chemistry', 'Physics', 'History',
  'English', 'Geography', 'Computer Science', 'Economics', 'Psychology',
  'Java', 'Python', 'JavaScript', 'Data Structures', 'Machine Learning',
];

class TestSetupScreen extends ConsumerStatefulWidget {
  const TestSetupScreen({super.key});
  @override
  ConsumerState<TestSetupScreen> createState() => _TestSetupState();
}

class _TestSetupState extends ConsumerState<TestSetupScreen> {
  // ── All state fields properly declared ───────────────────────────────────
  String _subject    = '';
  String _testType   = 'full_subject';  // full_subject | topic_wise
  String _difficulty = 'medium';        // easy | medium | hard | mixed
  int    _qCount     = 20;
  int    _timer      = 0;
  bool   _generating = false;

  // Subject
  final _customSubjectCtrl = TextEditingController();
  bool  _showCustomSubject = false;

  // Chapter/topic input (shown only when Chapter Test is selected)
  final _topicCtrl = TextEditingController();
  final List<String> _topics = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _subject.isNotEmpty) return;
      final user = ref.read(authStateProvider).user;
      final subs = user?.profile.subjects ?? [];
      setState(() => _subject = subs.isNotEmpty ? subs.first : _kDefaultSubjects.first);
    });
  }

  @override
  void dispose() {
    _customSubjectCtrl.dispose();
    _topicCtrl.dispose();
    super.dispose();
  }

  // ── Resolve subject — never empty ────────────────────────────────────────
  String get _resolvedSubject {
    final custom = _customSubjectCtrl.text.trim();
    if (custom.isNotEmpty) return custom;
    if (_subject.isNotEmpty) return _subject;
    final user = ref.read(authStateProvider).user;
    final subs = user?.profile.subjects ?? [];
    return subs.isNotEmpty ? subs.first : _kDefaultSubjects.first;
  }

  void _addTopic() {
    final v = _topicCtrl.text.trim();
    if (v.isEmpty || _topics.contains(v)) return;
    setState(() { _topics.add(v); _topicCtrl.clear(); });
  }

  Future<void> _start() async {
    final subject = _resolvedSubject;
    if (subject.isEmpty) { _err('Please select a subject.'); return; }
    if (_testType == 'topic_wise' && _topics.isEmpty) {
      _err('Please add at least one chapter/topic.'); return;
    }

    setState(() => _generating = true);
    try {
      final test = await ref.read(testServiceProvider).createTest(
        subject:       subject,
        topics:        _testType == 'topic_wise' ? _topics : [],
        testType:      _testType,
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
      _err(_parseErr(e));
    }
  }

  String _parseErr(dynamic e) {
    try {
      if (e.runtimeType.toString().contains('DioException') ||
          e.runtimeType.toString().contains('DioError')) {
        final code = (e as dynamic).response?.statusCode as int?;
        final data = (e as dynamic).response?.data;
        if (data is Map) {
          final err = data['error'];
          if (err is Map) {
            final details = err['details'];
            if (details is List && details.isNotEmpty && details.first is Map) {
              final f = details.first as Map;
              return '${f['field'] ?? ''}: ${f['message'] ?? ''}';
            }
            final msg = (err['message'] ?? '').toString();
            if (msg.isNotEmpty) return msg;
          }
        }
        if (code == 429) return 'AI is busy. Wait 1 minute then retry.';
        if (code == 503) return 'AI temporarily unavailable. Try again shortly.';
        if (code == 500) return 'Server error. Please retry.';
        if (code == 422) return 'Invalid input. Check your subject name.';
        final s = e.toString().toLowerCase();
        if (s.contains('timeout')) return 'Timed out. Try fewer questions (10).';
        if (s.contains('connect')) return 'No internet. Check your connection.';
      }
    } catch (_) {}
    return 'Something went wrong. Please try again.';
  }

  void _err(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: GoogleFonts.outfit(fontSize: 13, color: Colors.white)),
    backgroundColor: const Color(0xFFEF4444),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
    duration: const Duration(seconds: 4),
  ));

  @override
  Widget build(BuildContext context) {
    final user            = ref.watch(authStateProvider).user;
    final profileSubjects = user?.profile.subjects ?? [];
    final allSubjects     = [
      ...profileSubjects,
      ..._kDefaultSubjects.where((s) => !profileSubjects.contains(s)),
    ];

    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = Theme.of(context).scaffoldBackgroundColor;
    final card    = isDark ? AppColors.darkCard   : Colors.white;
    final titleC  = isDark ? const Color(0xFFE8E6F8) : AppColors.textPrimary;
    final subC    = isDark ? const Color(0xFF9B99B0) : AppColors.textSecondary;
    final borderC = isDark ? const Color(0xFF3A3850) : const Color(0xFFE8E6F0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0, surfaceTintColor: Colors.transparent,
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
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── SUBJECT ────────────────────────────────────────
            _SectionTitle('Choose Subject', titleC),
            const SizedBox(height: 10),
            if (profileSubjects.isNotEmpty)
              _ProfileBadge(),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              // Preset chips
              ...allSubjects.map((s) {
                final sel      = _subject == s && !_showCustomSubject;
                final isPro    = profileSubjects.contains(s);
                return _Chip(
                  label: s,
                  selected: sel,
                  borderColor: isPro && !sel
                      ? AppColors.primary.withValues(alpha: 0.35)
                      : borderC,
                  prefix: isPro && !sel
                      ? const Icon(Icons.star_rounded, size: 11, color: AppColors.primary)
                      : null,
                  card: card,
                  onTap: () => setState(() {
                    _subject = s;
                    _showCustomSubject = false;
                    _customSubjectCtrl.clear();
                  }),
                );
              }),
              // Custom chip
              _Chip(
                label: '+ Custom',
                selected: _showCustomSubject,
                selectedColor: AppColors.accentOrange,
                borderColor: borderC,
                card: card,
                onTap: () => setState(() {
                  _showCustomSubject = !_showCustomSubject;
                  if (!_showCustomSubject) _customSubjectCtrl.clear();
                }),
              ),
            ]),

            // Custom subject input
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: _showCustomSubject
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _TextInputRow(
                        ctrl: _customSubjectCtrl,
                        hint: 'e.g. Fluid Mechanics, Sanskrit…',
                        buttonLabel: 'Set',
                        card: card,
                        titleC: titleC,
                        subC: subC,
                        borderC: borderC,
                        onSubmit: (v) {
                          if (v.trim().isEmpty) return;
                          setState(() {
                            _subject = v.trim();
                            _showCustomSubject = false;
                          });
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Show confirmed custom subject
            if (_subject.isNotEmpty &&
                !allSubjects.contains(_subject) &&
                !_showCustomSubject)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _ConfirmedChip(
                  label: _subject,
                  onClear: () => setState(() {
                    _subject = allSubjects.isNotEmpty
                        ? allSubjects.first
                        : _kDefaultSubjects.first;
                    _customSubjectCtrl.clear();
                  }),
                ),
              ),
            const SizedBox(height: 28),

            // ── TEST TYPE ───────────────────────────────────────
            _SectionTitle('Test Type', titleC),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _TypeCard(
                icon: Icons.edit_note_rounded,
                title: 'Full Subject',
                subtitle: 'Questions from the whole subject',
                selected: _testType == 'full_subject',
                card: card, titleC: titleC, subC: subC, borderC: borderC,
                onTap: () => setState(() { _testType = 'full_subject'; _topics.clear(); }),
              )),
              const SizedBox(width: 12),
              Expanded(child: _TypeCard(
                icon: Icons.book_outlined,
                title: 'Chapter Test',
                subtitle: 'Focus on specific chapters/topics',
                selected: _testType == 'topic_wise',
                card: card, titleC: titleC, subC: subC, borderC: borderC,
                onTap: () => setState(() => _testType = 'topic_wise'),
              )),
            ]),

            // Chapter/topic input — shown only for Chapter Test
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: _testType == 'topic_wise'
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Add Chapters / Topics',
                              style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: titleC)),
                          const SizedBox(height: 8),
                          _TextInputRow(
                            ctrl: _topicCtrl,
                            hint: 'e.g. Photosynthesis, Recursion…',
                            buttonLabel: 'Add',
                            card: card,
                            titleC: titleC,
                            subC: subC,
                            borderC: borderC,
                            onSubmit: (_) => _addTopic(),
                            onButtonTap: _addTopic,
                          ),
                          if (_topics.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(spacing: 8, runSpacing: 8,
                              children: _topics.map((t) => Chip(
                                label: Text(t,
                                    style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600)),
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.08),
                                deleteIconColor: AppColors.primary,
                                side: BorderSide(
                                    color: AppColors.primary.withValues(alpha: 0.25)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                onDeleted: () =>
                                    setState(() => _topics.remove(t)),
                              )).toList(),
                            ),
                          ],
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 28),

            // ── DIFFICULTY ──────────────────────────────────────
            _SectionTitle('Difficulty', titleC),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderC)),
              padding: const EdgeInsets.all(4),
              child: Row(children: [
                ('easy',   'Easy',   const Color(0xFF10B981)),
                ('medium', 'Medium', const Color(0xFFF59E0B)),
                ('hard',   'Hard',   const Color(0xFFEF4444)),
                ('mixed',  'Mixed',  AppColors.primary),
              ].map((d) {
                final sel = _difficulty == d.$1;
                return Expanded(child: GestureDetector(
                  onTap: () => setState(() => _difficulty = d.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                        color: sel ? d.$3 : Colors.transparent,
                        borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text(d.$2,
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : subC))),
                  ),
                ));
              }).toList()),
            ),
            const SizedBox(height: 28),

            // ── QUESTIONS ───────────────────────────────────────
            _SectionTitle('Number of Questions', titleC),
            const SizedBox(height: 12),
            Row(children: [10, 20, 30, 40].map((n) {
              final sel    = _qCount == n;
              final isLast = n == 40;
              return Expanded(child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : 8),
                child: GestureDetector(
                  onTap: () => setState(() => _qCount = n),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel ? AppColors.primary : borderC),
                      boxShadow: sel ? [BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.20),
                          blurRadius: 8, offset: const Offset(0, 3))] : [],
                    ),
                    child: Column(children: [
                      Text('$n', style: GoogleFonts.outfit(
                          fontSize: 18, fontWeight: FontWeight.w800,
                          color: sel ? Colors.white : titleC)),
                      Text('Qs', style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: sel ? Colors.white70 : subC)),
                    ]),
                  ),
                ),
              ));
            }).toList()),
            const SizedBox(height: 28),

            // ── TIME LIMIT ──────────────────────────────────────
            _SectionTitle('Time Limit', titleC),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              (0,  'No Limit'),
              (15, '15 min'),
              (30, '30 min'),
              (45, '45 min'),
              (60, '60 min'),
            ].map((t) {
              final sel = _timer == t.$1;
              return GestureDetector(
                onTap: () => setState(() => _timer = t.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: sel ? AppColors.primary : borderC),
                  ),
                  child: Text(t.$2, style: GoogleFonts.outfit(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : titleC)),
                ),
              );
            }).toList()),
          ]),
        )),

        // ── START BUTTON ──────────────────────────────────────
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
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 14, offset: const Offset(0, 5))],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (_generating)
                  const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                else
                  const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(_generating ? 'Generating questions…' : 'Start Test',
                    style: GoogleFonts.outfit(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: _generating ? AppColors.textSecondary : Colors.white)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Small reusable widgets ────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionTitle(this.text, this.color);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.outfit(fontSize: 15,
          fontWeight: FontWeight.w700, color: color));
}

class _ProfileBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.star_rounded, size: 12, color: AppColors.primary),
      const SizedBox(width: 4),
      Text('Your subjects shown first',
          style: GoogleFonts.outfit(
              fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? selectedColor;
  final Color borderColor, card;
  final Widget? prefix;
  final VoidCallback onTap;
  const _Chip({
    required this.label, required this.selected,
    this.selectedColor, required this.borderColor,
    required this.card, this.prefix, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selColor = selectedColor ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? selColor : card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? selColor : borderColor),
          boxShadow: selected ? [BoxShadow(
              color: selColor.withValues(alpha: 0.20),
              blurRadius: 6, offset: const Offset(0, 2))] : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (prefix != null) ...[prefix!, const SizedBox(width: 4)],
          Text(label, style: GoogleFonts.outfit(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: selected ? Colors.white
                  : (prefix != null ? AppColors.primary : AppColors.textPrimary))),
        ]),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool selected;
  final Color card, titleC, subC, borderC;
  final VoidCallback onTap;
  const _TypeCard({
    required this.icon, required this.title, required this.subtitle,
    required this.selected, required this.card, required this.titleC,
    required this.subC, required this.borderC, required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryLight : card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: selected ? AppColors.primary : borderC,
            width: selected ? 1.5 : 1),
        boxShadow: [BoxShadow(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 22, color: selected ? AppColors.primary : subC),
        const SizedBox(height: 10),
        Text(title, style: GoogleFonts.outfit(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: selected ? AppColors.primary : titleC)),
        const SizedBox(height: 2),
        Text(subtitle, style: GoogleFonts.outfit(
            fontSize: 11, color: subC),
            maxLines: 2, overflow: TextOverflow.ellipsis),
      ]),
    ),
  );
}

class _TextInputRow extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint, buttonLabel;
  final Color card, titleC, subC, borderC;
  final ValueChanged<String> onSubmit;
  final VoidCallback? onButtonTap;
  const _TextInputRow({
    required this.ctrl, required this.hint, required this.buttonLabel,
    required this.card, required this.titleC, required this.subC,
    required this.borderC, required this.onSubmit, this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderC),
        ),
        child: TextField(
          controller: ctrl,
          style: GoogleFonts.outfit(fontSize: 14, color: titleC),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: subC, fontSize: 13),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          onSubmitted: onSubmit,
        ),
      ),
    ),
    const SizedBox(width: 8),
    GestureDetector(
      onTap: onButtonTap ?? () => onSubmit(ctrl.text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
        child: Text(buttonLabel, style: GoogleFonts.outfit(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    ),
  ]);
}

class _ConfirmedChip extends StatelessWidget {
  final String label;
  final VoidCallback onClear;
  const _ConfirmedChip({required this.label, required this.onClear});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.accentGreen.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.35)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.check_circle_rounded, size: 13, color: AppColors.accentGreen),
      const SizedBox(width: 6),
      Text(label, style: GoogleFonts.outfit(
          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accentGreen)),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: onClear,
        child: const Icon(Icons.close_rounded, size: 14, color: AppColors.accentGreen),
      ),
    ]),
  );
}
