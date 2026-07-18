import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/test_provider.dart';
import '../models/test_model.dart';
import '../app_theme.dart';
import '../widgets/shimmer_box.dart';

class TestHistoryScreen extends ConsumerStatefulWidget {
  const TestHistoryScreen({super.key});

  @override
  ConsumerState<TestHistoryScreen> createState() =>
      _TestHistoryScreenState();
}

class _TestHistoryScreenState extends ConsumerState<TestHistoryScreen> {
  String _searchQuery = '';
  String? _filterDifficulty;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(testHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Test History',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded,
                color: AppColors.textSecondary),
            onPressed: () => context.push('/tests/analytics'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search + Filter ──────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(children: [
              TextField(
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Search by subject...',
                  prefixIcon: Icon(Icons.search_rounded,
                      color: AppColors.textLight, size: 18),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                        label: 'All',
                        selected: _filterDifficulty == null,
                        onTap: () =>
                            setState(() => _filterDifficulty = null)),
                    const SizedBox(width: 6),
                    _FilterChip(
                        label: 'Easy',
                        selected: _filterDifficulty == 'easy',
                        color: AppColors.accentGreen,
                        onTap: () =>
                            setState(() => _filterDifficulty = 'easy')),
                    const SizedBox(width: 6),
                    _FilterChip(
                        label: 'Medium',
                        selected: _filterDifficulty == 'medium',
                        color: AppColors.accentOrange,
                        onTap: () =>
                            setState(() => _filterDifficulty = 'medium')),
                    const SizedBox(width: 6),
                    _FilterChip(
                        label: 'Hard',
                        selected: _filterDifficulty == 'hard',
                        color: AppColors.accent,
                        onTap: () =>
                            setState(() => _filterDifficulty = 'hard')),
                    const SizedBox(width: 6),
                    _FilterChip(
                        label: 'Mixed',
                        selected: _filterDifficulty == 'mixed',
                        onTap: () =>
                            setState(() => _filterDifficulty = 'mixed')),
                  ],
                ),
              ),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // ── List ─────────────────────────────────────────
          Expanded(
            child: historyAsync.when(
              loading: () => ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  ShimmerCard(height: 72),
                  ShimmerCard(height: 72),
                  ShimmerCard(height: 72),
                  ShimmerCard(height: 72),
                  ShimmerCard(height: 72),
                ],
              ),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(
                          color: AppColors.textSecondary))),
              data: (tests) {
                var filtered = tests.where((t) {
                  final matchSearch = _searchQuery.isEmpty ||
                      t.subject.toLowerCase().contains(_searchQuery);
                  final matchDiff = _filterDifficulty == null ||
                      t.difficulty == _filterDifficulty;
                  return matchSearch && matchDiff;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded,
                            size: 48, color: AppColors.textLight),
                        SizedBox(height: 12),
                        Text('No tests found',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _HistoryItem(
                    test: filtered[i],
                    onTap: () =>
                        context.push('/tests/report/${filtered[i].id}'),
                    onDelete: () async {
                      await ref
                          .read(testServiceProvider)
                          .deleteTest(filtered[i].id);
                      ref.invalidate(testHistoryProvider);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label,
      required this.selected,
      this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? c : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? c : AppColors.divider),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final TestModel test;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _HistoryItem(
      {required this.test,
      required this.onTap,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final clr = test.percentage >= 70
        ? AppColors.accentGreen
        : test.percentage >= 50
            ? AppColors.accentOrange
            : Colors.red.shade400;

    return Dismissible(
      key: Key(test.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(14)),
        child:
            const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                title: const Text('Delete Test?',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                content: const Text(
                    'This will permanently delete this test record.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8)),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete')),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: clr.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(test.grade,
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: clr)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(test.subject,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    '${_capitalize(test.difficulty)} · ${test.questionCount} Qs · ${_fmtDate(test.submittedAt)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text('${test.correct}/${test.totalQuestions}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: clr)),
                    const SizedBox(width: 8),
                    Container(
                        width: 1,
                        height: 10,
                        color: AppColors.divider),
                    const SizedBox(width: 8),
                    Text(test.passed ? 'Passed' : 'Failed',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: test.passed
                                ? AppColors.accentGreen
                                : Colors.red.shade400)),
                  ]),
                ],
              ),
            ),
            Text('${test.percentage}%',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: clr)),
          ]),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}
