import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../providers/exam_plan_provider.dart';
import '../widgets/animations.dart';

// Provider for subject info — auto-disposes, keyed by subject name
final subjectInfoProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, subject) async {
  final service = ref.read(examPlanServiceProvider);
  return service.getSubjectInfo(subject);
});

class SubjectInfoScreen extends ConsumerWidget {
  final String subject;
  const SubjectInfoScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(subjectInfoProvider(subject));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(subject, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(subjectInfoProvider(subject)),
          ),
        ],
      ),
      body: infoAsync.when(
        loading: () => _buildLoading(subject),
        error: (e, _) => _buildError(context, ref, e.toString()),
        data: (info) => _buildContent(context, info),
      ),
    );
  }

  Widget _buildLoading(String subject) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 56, height: 56,
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
            ),
            const SizedBox(height: 24),
            Text(
              'Generating AI content for\n$subject...',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text('Powered by Groq 🤖', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textLight)),
          ],
        ),
      );

  Widget _buildError(BuildContext context, WidgetRef ref, String err) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.textLight),
              const SizedBox(height: 16),
              Text('Failed to load', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(err, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(subjectInfoProvider(subject)),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ),
        ),
      );

  Widget _buildContent(BuildContext context, Map<String, dynamic> info) {
    final topics = (info['topics'] as List?)?.cast<Map>() ?? [];
    final pyqs = (info['pyqs'] as List?)?.cast<Map>() ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header pill
          FadeSlideIn(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🤖', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text('AI-generated • Powered by Groq', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── TOPICS ─────────────────────────────────────────────────────
          _SectionHeader(icon: Icons.menu_book_rounded, title: 'Key Topics', color: AppColors.primary),
          const SizedBox(height: 12),
          ...topics.asMap().entries.map((e) => FadeSlideIn(
                delay: Duration(milliseconds: 60 * e.key),
                child: _TopicCard(topic: Map<String, dynamic>.from(e.value)),
              )),

          const SizedBox(height: 28),

          // ── PYQs ───────────────────────────────────────────────────────
          _SectionHeader(icon: Icons.history_edu_rounded, title: 'Previous Year Questions', color: const Color(0xFF7C3AED)),
          const SizedBox(height: 12),
          ...pyqs.asMap().entries.map((e) => FadeSlideIn(
                delay: Duration(milliseconds: 60 * e.key),
                child: _PYQCard(pyq: Map<String, dynamic>.from(e.value), index: e.key + 1),
              )),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ],
      );
}

class _TopicCard extends StatelessWidget {
  final Map<String, dynamic> topic;
  const _TopicCard({required this.topic});

  @override
  Widget build(BuildContext context) {
    final weightage = topic['weightage'] as String? ?? 'Medium';
    final weightColor = weightage == 'High'
        ? const Color(0xFF059669)
        : weightage == 'Low'
            ? AppColors.textSecondary
            : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(color: weightColor, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(topic['name'] ?? '', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: weightColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(weightage, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: weightColor)),
                    ),
                  ],
                ),
                if (topic['description'] != null) ...[
                  const SizedBox(height: 4),
                  Text(topic['description'], style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PYQCard extends StatelessWidget {
  final Map<String, dynamic> pyq;
  final int index;
  const _PYQCard({required this.pyq, required this.index});

  @override
  Widget build(BuildContext context) {
    final difficulty = pyq['difficulty'] as String? ?? 'Medium';
    final diffColor = difficulty == 'Easy'
        ? const Color(0xFF059669)
        : difficulty == 'Hard'
            ? const Color(0xFFDC2626)
            : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text('$index', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF7C3AED)))),
              ),
              const SizedBox(width: 8),
              Text('${pyq['year'] ?? ''}', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              const Spacer(),
              // Marks badge
              if (pyq['marks'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                  child: Text('${pyq['marks']} marks', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: diffColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(difficulty, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: diffColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(pyq['question'] ?? '', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textPrimary, height: 1.5)),
        ],
      ),
    );
  }
}
