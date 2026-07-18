import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/test_provider.dart';
import '../app_theme.dart';

// ── Preset subjects ────────────────────────────────────────────────────────────
const _kSubjects = [
  'Java', 'DBMS', 'Operating System', 'Computer Networks',
  'Python', 'C++', 'JavaScript', 'React', 'Flutter', 'Node.js',
  'Data Structures', 'Algorithms', 'SQL', 'Machine Learning',
  'Mathematics', 'Physics', 'Chemistry', 'Biology', 'History', 'Geography',
];

class TestSetupScreen extends ConsumerStatefulWidget {
  const TestSetupScreen({super.key});
  @override
  ConsumerState<TestSetupScreen> createState() => _TestSetupState();
}

class _TestSetupState extends ConsumerState<TestSetupScreen> {
  int _step = 0; // 0=subject, 1=type, 2=options

  // Step 1
  String? _subject;
  final _customSubjectCtrl = TextEditingController();

  // Step 2
  String _testType = 'full_subject'; // full_subject | topic_wise
  final List<String> _topics = [];
  final _topicCtrl = TextEditingController();

  // Step 3
  String _difficulty = 'mixed';
  int _questionCount = 20;
  int _timerMinutes = 0;

  bool _isGenerating = false;

  @override
  void dispose() {
    _customSubjectCtrl.dispose();
    _topicCtrl.dispose();
    super.dispose();
  }

  void _addTopic() {
    final v = _topicCtrl.text.trim();
    if (v.isEmpty || _topics.contains(v)) return;
    setState(() {
      _topics.add(v);
      _topicCtrl.clear();
    });
  }

  Future<void> _generate() async {
    if (_subject == null || _subject!.isEmpty) return;
    if (_testType == 'topic_wise' && _topics.isEmpty) {
      _showSnack('Please add at least one topic.');
      return;
    }
    setState(() => _isGenerating = true);
    try {
      final test = await ref.read(testServiceProvider).createTest(
            subject: _subject!,
            topics: _testType == 'topic_wise' ? _topics : [],
            testType: _testType,
            difficulty: _difficulty,
            questionCount: _questionCount,
            timerMinutes: _timerMinutes,
          );
      if (!mounted) return;
      ref.invalidate(activeDraftProvider);
      context.go('/tests/active/${test.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      String msg = 'Failed to generate. Please try again.';
      try {
        if (e.runtimeType.toString().contains('DioException')) {
          // ignore: avoid_dynamic_calls
          final data = (e as dynamic).response?.data;
          if (data is Map && data['error'] != null) {
            final err = data['error'];
            if (err is Map) {
              final details = err['details'];
              if (details is List && details.isNotEmpty) {
                msg = details.map((d) => '${d['field']}: ${d['message']}').join(', ');
              } else {
                msg = err['message']?.toString() ?? msg;
              }
            }
          }
          final status = (e as dynamic).response?.statusCode;
          if (msg == 'Failed to generate. Please try again.') {
            if (status == 422) msg = 'Validation error. Try again.';
            else if (status == 404) msg = 'Server not ready. Wait and retry.';
            else if (status == 429) msg = 'AI rate limit. Wait 1 min.';
            else if (status == 500) msg = 'Server error. Please retry.';
            else if (e.toString().contains('ReceiveTimeout')) msg = 'AI timeout. Try fewer questions.';
          }
        }
      } catch (_) {}
      _showSnack(msg);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.textPrimary),
          onPressed: () =>
              _step > 0 ? setState(() => _step--) : context.pop(),
        ),
        title: Text(
          _step == 0
              ? 'Choose Subject'
              : _step == 1
                  ? 'Test Type'
                  : 'Test Options',
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / 3,
            backgroundColor: AppColors.divider,
            color: AppColors.primary,
            minHeight: 3,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _step == 0
                ? _SubjectStep(
                    selected: _subject,
                    customCtrl: _customSubjectCtrl,
                    onSelect: (s) => setState(() => _subject = s),
                  )
                : _step == 1
                    ? _TypeStep(
                        testType: _testType,
                        topics: _topics,
                        topicCtrl: _topicCtrl,
                        onTypeChange: (t) =>
                            setState(() => _testType = t),
                        onAddTopic: _addTopic,
                        onRemoveTopic: (t) =>
                            setState(() => _topics.remove(t)),
                      )
                    : _OptionsStep(
                        difficulty: _difficulty,
                        questionCount: _questionCount,
                        timerMinutes: _timerMinutes,
                        onDifficultyChange: (d) =>
                            setState(() => _difficulty = d),
                        onCountChange: (c) =>
                            setState(() => _questionCount = c),
                        onTimerChange: (t) =>
                            setState(() => _timerMinutes = t),
                      ),
          ),
          _BottomBar(
            step: _step,
            isGenerating: _isGenerating,
            canProceed: _step == 0
                ? (_subject != null && _subject!.isNotEmpty)
                : true,
            onNext: () {
              if (_step == 0 && (_subject == null || _subject!.isEmpty)) {
                _showSnack('Please select a subject first.');
                return;
              }
              if (_step < 2) {
                setState(() => _step++);
              } else {
                _generate();
              }
            },
          ),
        ],
      ),
    );
  }
}

// ── Step 1: Subject ───────────────────────────────────────────────────────────
class _SubjectStep extends StatelessWidget {
  final String? selected;
  final TextEditingController customCtrl;
  final ValueChanged<String> onSelect;

  const _SubjectStep(
      {required this.selected,
      required this.customCtrl,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What do you want to be tested on?',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kSubjects.map((s) {
              final isSel = selected == s;
              return GestureDetector(
                onTap: () => onSelect(s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isSel ? AppColors.primary : AppColors.divider),
                  ),
                  child: Text(s,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSel ? Colors.white : AppColors.textPrimary)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Or type a custom subject:',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: customCtrl,
                decoration: const InputDecoration(
                    hintText: 'e.g. Thermodynamics, React Hooks...'),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) onSelect(v.trim());
                },
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                final v = customCtrl.text.trim();
                if (v.isNotEmpty) {
                  onSelect(v);
                  customCtrl.clear();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ]),
          if (selected != null && !_kSubjects.contains(selected)) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20)),
              child: Text('✓ $selected',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Step 2: Type ──────────────────────────────────────────────────────────────
class _TypeStep extends StatelessWidget {
  final String testType;
  final List<String> topics;
  final TextEditingController topicCtrl;
  final ValueChanged<String> onTypeChange;
  final VoidCallback onAddTopic;
  final ValueChanged<String> onRemoveTopic;

  const _TypeStep({
    required this.testType,
    required this.topics,
    required this.topicCtrl,
    required this.onTypeChange,
    required this.onAddTopic,
    required this.onRemoveTopic,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('What type of test do you want?',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        _TypeCard(
          selected: testType == 'full_subject',
          title: 'Entire Subject Test',
          subtitle: 'Questions from all topics in the subject',
          icon: Icons.library_books_outlined,
          onTap: () => onTypeChange('full_subject'),
        ),
        const SizedBox(height: 10),
        _TypeCard(
          selected: testType == 'topic_wise',
          title: 'Topic Wise Test',
          subtitle: 'Questions from specific topics you choose',
          icon: Icons.topic_outlined,
          onTap: () => onTypeChange('topic_wise'),
        ),
        if (testType == 'topic_wise') ...[
          const SizedBox(height: 20),
          const Text('Enter topics:',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: topicCtrl,
                decoration: const InputDecoration(
                    hintText: 'e.g. OOP, Normalization, React Hooks'),
                onSubmitted: (_) => onAddTopic(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onAddTopic,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          if (topics.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topics
                  .map((t) => Chip(
                        label: Text(t,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.primary)),
                        backgroundColor: AppColors.primaryLight,
                        deleteIconColor: AppColors.primary,
                        side: BorderSide.none,
                        onDeleted: () => onRemoveTopic(t),
                      ))
                  .toList(),
            ),
        ],
      ]),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final bool selected;
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _TypeCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
              width: selected ? 2 : 1),
        ),
        child: Row(children: [
          Icon(icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary)),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
          if (selected)
            const Icon(Icons.check_circle_rounded,
                color: AppColors.primary, size: 20),
        ]),
      ),
    );
  }
}

// ── Step 3: Options ───────────────────────────────────────────────────────────
class _OptionsStep extends StatelessWidget {
  final String difficulty;
  final int questionCount;
  final int timerMinutes;
  final ValueChanged<String> onDifficultyChange;
  final ValueChanged<int> onCountChange;
  final ValueChanged<int> onTimerChange;

  const _OptionsStep({
    required this.difficulty,
    required this.questionCount,
    required this.timerMinutes,
    required this.onDifficultyChange,
    required this.onCountChange,
    required this.onTimerChange,
  });

  @override
  Widget build(BuildContext context) {
    final difficulties = [
      ('easy', 'Easy'),
      ('medium', 'Medium'),
      ('hard', 'Hard'),
      ('mixed', 'Mixed'),
    ];
    final counts = [10, 20, 30];
    final timers = [
      (0, 'No Timer'),
      (15, '15 min'),
      (30, '30 min'),
      (45, '45 min'),
      (60, '60 min'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _OptionSection(
          title: 'Difficulty',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: difficulties.map((d) {
              final isSel = difficulty == d.$1;
              final clr = d.$1 == 'easy'
                  ? AppColors.accentGreen
                  : d.$1 == 'medium'
                      ? AppColors.accentOrange
                      : d.$1 == 'hard'
                          ? AppColors.accent
                          : AppColors.primary;
              return GestureDetector(
                onTap: () => onDifficultyChange(d.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSel ? clr : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isSel ? clr : AppColors.divider),
                  ),
                  child: Text(d.$2,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSel ? Colors.white : AppColors.textPrimary)),
                ),
              );
            }).toList(),
          ),
        ),
        _OptionSection(
          title: 'Number of Questions',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: counts.map((c) {
              final isSel = questionCount == c;
              return GestureDetector(
                onTap: () => onCountChange(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 70,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color:
                            isSel ? AppColors.primary : AppColors.divider),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$c',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: isSel
                                  ? Colors.white
                                  : AppColors.textPrimary)),
                      Text('Qs',
                          style: TextStyle(
                              fontSize: 10,
                              color: isSel
                                  ? Colors.white70
                                  : AppColors.textSecondary)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        _OptionSection(
          title: 'Timer',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: timers.map((t) {
              final isSel = timerMinutes == t.$1;
              return GestureDetector(
                onTap: () => onTimerChange(t.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isSel ? AppColors.primary : AppColors.divider),
                  ),
                  child: Text(t.$2,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSel ? Colors.white : AppColors.textPrimary)),
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }
}

class _OptionSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _OptionSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// ── Bottom Bar ────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final int step;
  final bool isGenerating;
  final bool canProceed;
  final VoidCallback onNext;

  const _BottomBar({
    required this.step,
    required this.isGenerating,
    required this.canProceed,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = step == 2;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: GestureDetector(
        onTap: (isGenerating || !canProceed) ? null : onNext,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: (isGenerating || !canProceed)
                ? AppColors.divider
                : AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: isGenerating
                ? const Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white)),
                    SizedBox(width: 10),
                    Text('Generating questions...',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                  ])
                : Text(
                    isLast ? 'Generate Test ✨' : 'Next →',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: canProceed
                            ? Colors.white
                            : AppColors.textSecondary),
                  ),
          ),
        ),
      ),
    );
  }
}
