import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../providers/analytics_provider.dart';
import '../providers/auth_provider.dart';
import '../app_theme.dart';
import '../widgets/animations.dart';

class WeeklyReportScreen extends ConsumerStatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  ConsumerState<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends ConsumerState<WeeklyReportScreen> {
  bool _generating = false;

  Future<void> _downloadPdf(Map<String, dynamic> data, String userName) async {
    setState(() => _generating = true);
    try {
      final pdf = pw.Document();
      final totalMins = (data['totalStudyMinutes'] ?? 0) as int;
      final avgFocus = data['avgFocusScore'] ?? 0;
      final totalSessions = data['totalSessions'] ?? 0;
      final suggestions = List<String>.from(data['aiSuggestions'] ?? []);
      final subjectBreakdown = <String, int>{
        for (final item in (data['subjectBreakdown'] as List? ?? []))
          (item['subject'] ?? 'Other'): ((item['minutes'] ?? 0) as num).toInt()
      };
      final weekOf = DateFormat('MMM d, yyyy').format(DateTime.now().subtract(const Duration(days: 7)));
      final now = DateFormat('MMM d, yyyy').format(DateTime.now());

      // ── Colors ─────────────────────────────────────────────
      const navyBlue = PdfColor.fromInt(0xFF1E3A8A);
      const royalBlue = PdfColor.fromInt(0xFF2563EB);
      const lightBlue = PdfColor.fromInt(0xFFDBEAFE);
      const slateGrey = PdfColor.fromInt(0xFF64748B);
      const darkSlate = PdfColor.fromInt(0xFF0F172A);
      const white = PdfColors.white;
      const green = PdfColor.fromInt(0xFF10B981);
      const amber = PdfColor.fromInt(0xFFF59E0B);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(0),
          build: (pw.Context ctx) => [
            // ── Header banner ──────────────────────────────
            pw.Container(
              color: navyBlue,
              padding: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('StudyCoach',
                              style: pw.TextStyle(
                                  fontSize: 28,
                                  fontWeight: pw.FontWeight.bold,
                                  color: white)),
                          pw.SizedBox(height: 4),
                          pw.Text('Weekly Progress Report',
                              style: pw.TextStyle(fontSize: 14, color: const PdfColor(1, 1, 1, 0.7))),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(userName,
                              style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                  color: white)),
                          pw.SizedBox(height: 4),
                          pw.Text('$weekOf – $now',
                              style: pw.TextStyle(fontSize: 11, color: const PdfColor(1, 1, 1, 0.7))),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(40, 32, 40, 0),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // ── Stat cards row ──────────────────────
                  pw.Row(
                    children: [
                      _pdfStatCard('Total Study Time',
                          '${totalMins ~/ 60}h ${totalMins % 60}m', '📚', royalBlue, lightBlue),
                      pw.SizedBox(width: 12),
                      _pdfStatCard('Avg Focus Score',
                          '$avgFocus%', '🎯', green, PdfColor.fromInt(0xFFD1FAE5)),
                      pw.SizedBox(width: 12),
                      _pdfStatCard('Total Sessions',
                          '$totalSessions', '⚡', amber, PdfColor.fromInt(0xFFFEF3C7)),
                    ],
                  ),
                  pw.SizedBox(height: 28),

                  // ── Subject breakdown ───────────────────
                  if (subjectBreakdown.isNotEmpty) ...[
                    _pdfSectionTitle('Subject Breakdown', slateGrey),
                    pw.SizedBox(height: 12),
                    ...subjectBreakdown.entries.map((e) {
                      final mins = e.value;
                      final pct = totalMins > 0 ? (mins / totalMins).clamp(0.0, 1.0) : 0.0;
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 10),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(e.key,
                                    style: pw.TextStyle(
                                        fontSize: 12,
                                        fontWeight: pw.FontWeight.bold,
                                        color: darkSlate)),
                                pw.Text('${mins ~/ 60}h ${mins % 60}m',
                                    style: pw.TextStyle(fontSize: 11, color: slateGrey)),
                              ],
                            ),
                            pw.SizedBox(height: 4),
                            pw.Stack(children: [
                              pw.Container(
                                  width: 515,
                                  height: 8,
                                  decoration: pw.BoxDecoration(
                                      color: lightBlue,
                                      borderRadius: pw.BorderRadius.circular(4))),
                              pw.Container(
                                  width: 515 * pct,
                                  height: 8,
                                  decoration: pw.BoxDecoration(
                                      color: royalBlue,
                                      borderRadius: pw.BorderRadius.circular(4))),
                            ]),
                          ],
                        ),
                      );
                    }),
                    pw.SizedBox(height: 28),
                  ],

                  // ── AI Suggestions ──────────────────────
                  if (suggestions.isNotEmpty) ...[
                    _pdfSectionTitle('AI Coach Suggestions', slateGrey),
                    pw.SizedBox(height: 12),
                    ...suggestions.asMap().entries.map((e) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 10),
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(14),
                        decoration: pw.BoxDecoration(
                          color: lightBlue,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('${e.key + 1}.',
                                style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                    color: royalBlue)),
                            pw.SizedBox(width: 8),
                            pw.Expanded(
                              child: pw.Text(e.value,
                                  style: pw.TextStyle(fontSize: 12, color: darkSlate, lineSpacing: 2)),
                            ),
                          ],
                        ),
                      ),
                    )),
                    pw.SizedBox(height: 28),
                  ],

                  // ── Footer ──────────────────────────────
                  pw.Divider(color: PdfColor.fromInt(0xFFE2E8F0)),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Generated by StudyCoach · $now',
                          style: pw.TextStyle(fontSize: 10, color: slateGrey)),
                      pw.Text('Keep studying! 🎓',
                          style: pw.TextStyle(
                              fontSize: 10,
                              color: royalBlue,
                              fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      // Save and open
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/StudyCoach_WeeklyReport_$now.pdf');
      await file.writeAsBytes(await pdf.save());
      await OpenFilex.open(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ PDF saved!', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.accentGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.accent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  pw.Widget _pdfStatCard(String label, String value, String emoji,
      PdfColor accent, PdfColor bg) =>
      pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
              color: bg, borderRadius: pw.BorderRadius.circular(10)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(emoji, style: const pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 6),
              pw.Text(value,
                  style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: accent)),
              pw.SizedBox(height: 2),
              pw.Text(label,
                  style: pw.TextStyle(
                      fontSize: 10, color: PdfColor.fromInt(0xFF64748B))),
            ],
          ),
        ),
      );

  pw.Widget _pdfSectionTitle(String title, PdfColor color) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF0F172A))),
          pw.SizedBox(height: 4),
          pw.Container(
              width: 36, height: 3,
              decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF2563EB),
                  borderRadius: pw.BorderRadius.circular(2))),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(weeklyReportProvider);
    final user = ref.watch(authStateProvider).user;
    final userName = user?.name ?? 'Student';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text('Weekly Report',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5)),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline_rounded, color: AppColors.accent, size: 48),
            const SizedBox(height: 12),
            Text('Failed to load report', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text('$e', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
          ]),
        ),
        data: (data) {
          final totalMins = (data['totalStudyMinutes'] ?? 0) as int;
          final avgFocus = data['avgFocusScore'] ?? 0;
          final totalSessions = data['totalSessions'] ?? 0;
          final suggestions = List<String>.from(data['aiSuggestions'] ?? []);
          final subjectBreakdown = <String, int>{
            for (final item in (data['subjectBreakdown'] as List? ?? []))
              (item['subject'] ?? 'Other'): ((item['minutes'] ?? 0) as num).toInt()
          };

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header card ─────────────────────────────────────────
                FadeSlideIn(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hi, $userName! 👋',
                            style: GoogleFonts.outfit(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text('Here\'s your weekly summary',
                            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('MMM d').format(DateTime.now().subtract(const Duration(days: 7)))} – ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Stat row ─────────────────────────────────────────────
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: Row(
                    children: [
                      _StatCard(label: 'Study Time', value: '${totalMins ~/ 60}h ${totalMins % 60}m', emoji: '📚', color: AppColors.primary),
                      const SizedBox(width: 12),
                      _StatCard(label: 'Avg Focus', value: '$avgFocus%', emoji: '🎯', color: AppColors.accentGreen),
                      const SizedBox(width: 12),
                      _StatCard(label: 'Sessions', value: '$totalSessions', emoji: '⚡', color: AppColors.accentOrange),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Subject breakdown ─────────────────────────────────────
                if (subjectBreakdown.isNotEmpty) ...[
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 140),
                    child: _SectionTitle(title: 'Subject Breakdown'),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 160),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                      child: Column(
                        children: subjectBreakdown.entries.map((e) {
                          final mins = e.value;
                          final pct = totalMins > 0 ? (mins / totalMins).clamp(0.0, 1.0) : 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(e.key, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                                    Text('${mins ~/ 60}h ${mins % 60}m', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 7,
                                    backgroundColor: AppColors.primaryLight,
                                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── AI Suggestions ────────────────────────────────────────
                if (suggestions.isNotEmpty) ...[
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: _SectionTitle(title: 'AI Coach Suggestions'),
                  ),
                  const SizedBox(height: 12),
                  ...suggestions.asMap().entries.map((e) => FadeSlideIn(
                    delay: Duration(milliseconds: 220 + e.key * 40),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primaryLight, width: 1.5),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(gradient: AppColors.heroGradient, shape: BoxShape.circle),
                            child: const Icon(Icons.tips_and_updates_rounded, color: Colors.white, size: 14),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(e.value, style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textPrimary, height: 1.5))),
                        ],
                      ),
                    ),
                  )),
                  const SizedBox(height: 28),
                ],

                // ── Download PDF button ────────────────────────────────────
                FadeSlideIn(
                  delay: const Duration(milliseconds: 300),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _generating ? null : () => _downloadPdf(data, userName),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        shadowColor: AppColors.primary.withOpacity(0.4),
                      ),
                      icon: _generating
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Icon(Icons.download_rounded, size: 22),
                      label: Text(
                        _generating ? 'Generating PDF...' : 'Download PDF Report',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value, emoji;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 6),
              Text(value, style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w900, color: color)),
              const SizedBox(height: 2),
              Text(label, style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ]);
}
