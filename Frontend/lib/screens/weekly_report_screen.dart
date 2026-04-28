import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
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
  bool _sharing = false;
  final _screenshotController = ScreenshotController();

  // ── Social Share ──────────────────────────────────────────────────────────
  Future<void> _shareAsImage(Map<String, dynamic> data, String userName) async {
    setState(() => _sharing = true);
    try {
      final Uint8List? image = await _screenshotController.capture(pixelRatio: 3.0);
      if (image == null) throw Exception('Screenshot capture returned null');

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/StudyCoach_Report_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(image);

      final totalMins = (data['totalStudyMinutes'] ?? 0) as int;
      final avgFocus = data['avgFocusScore'] ?? 0;
      final totalSessions = data['totalSessions'] ?? 0;

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '📊 My Weekly Study Report',
        text: '🎓 Check out my weekly progress!\n\n'
            '📚 Study Time: ${totalMins ~/ 60}h ${totalMins % 60}m\n'
            '🎯 Avg Focus: $avgFocus%\n'
            '⚡ Sessions: $totalSessions\n\n'
            'Powered by AI Study Coach',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.accent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

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
                              style: const pw.TextStyle(fontSize: 14, color: PdfColor(1, 1, 1, 0.7))),
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
                              style: const pw.TextStyle(fontSize: 11, color: PdfColor(1, 1, 1, 0.7))),
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
                          '$avgFocus%', '🎯', green, const PdfColor.fromInt(0xFFD1FAE5)),
                      pw.SizedBox(width: 12),
                      _pdfStatCard('Total Sessions',
                          '$totalSessions', '⚡', amber, const PdfColor.fromInt(0xFFFEF3C7)),
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
                                    style: const pw.TextStyle(fontSize: 11, color: slateGrey)),
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
                                  style: const pw.TextStyle(fontSize: 12, color: darkSlate, lineSpacing: 2)),
                            ),
                          ],
                        ),
                      ),
                    )),
                    pw.SizedBox(height: 28),
                  ],

                  // ── Footer ──────────────────────────────
                  pw.Divider(color: const PdfColor.fromInt(0xFFE2E8F0)),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Generated by StudyCoach · $now',
                          style: const pw.TextStyle(fontSize: 10, color: slateGrey)),
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
                  style: const pw.TextStyle(
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
                  color: const PdfColor.fromInt(0xFF0F172A))),
          pw.SizedBox(height: 4),
          pw.Container(
              width: 36, height: 3,
              decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF2563EB),
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
            const Icon(Icons.error_outline_rounded, color: AppColors.accent, size: 48),
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
                // ── Shareable Header Card (captured by screenshot) ──────────
                FadeSlideIn(
                  child: Screenshot(
                    controller: _screenshotController,
                    child: _ShareableReportCard(
                      userName: userName,
                      totalMins: totalMins,
                      avgFocus: avgFocus,
                      totalSessions: totalSessions,
                      subjectBreakdown: subjectBreakdown,
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
                  const FadeSlideIn(
                    delay: Duration(milliseconds: 140),
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
                        border: Border.all(color: AppColors.textPrimary, width: 3),
                        boxShadow: const [BoxShadow(color: AppColors.textPrimary, offset: Offset(4, 4))],
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
                                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
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
                  const FadeSlideIn(
                    delay: Duration(milliseconds: 200),
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
                        border: Border.all(color: AppColors.textPrimary, width: 2.5),
                        boxShadow: const [BoxShadow(color: AppColors.textPrimary, offset: Offset(3, 3))],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(gradient: AppColors.heroGradient, shape: BoxShape.circle),
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

                // ── Action buttons ────────────────────────────────────────
                FadeSlideIn(
                  delay: const Duration(milliseconds: 300),
                  child: Row(
                    children: [
                      // Download PDF
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _generating ? null : () => _downloadPdf(data, userName),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: AppColors.textPrimary, width: 2.5)),
                            ),
                            icon: _generating
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : const Icon(Icons.download_rounded, size: 20),
                            label: Text(
                              _generating ? 'Generating...' : 'PDF',
                              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Share as Image
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _sharing ? null : () => _shareAsImage(data, userName),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C896),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: AppColors.textPrimary, width: 2.5)),
                            ),
                            icon: _sharing
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : const Icon(Icons.share_rounded, size: 20),
                            label: Text(
                              _sharing ? 'Sharing...' : 'Share',
                              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ],
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
            border: Border.all(color: AppColors.textPrimary, width: 2.5),
            boxShadow: const [BoxShadow(color: AppColors.textPrimary, offset: Offset(3, 3))],
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

// ── Shareable Report Card ─────────────────────────────────────────────────────
/// A self-contained, visually rich card optimised to be captured as a
/// social-media image (screenshot). Uses a fixed width + intrinsic height so
/// the screenshot captures exactly the card at 3× resolution.
class _ShareableReportCard extends StatelessWidget {
  final String userName;
  final int totalMins;
  final int avgFocus;
  final int totalSessions;
  final Map<String, int> subjectBreakdown;

  const _ShareableReportCard({
    required this.userName,
    required this.totalMins,
    required this.avgFocus,
    required this.totalSessions,
    required this.subjectBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    final weekOf = DateFormat('MMM d').format(DateTime.now().subtract(const Duration(days: 7)));
    final weekEnd = DateFormat('MMM d, yyyy').format(DateTime.now());

    // Pick up to 3 subjects for the mini-bars
    final topSubjects = subjectBreakdown.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final displaySubjects = topSubjects.take(3).toList();

    const subjectColors = [
      Color(0xFF00FFC6),
      Color(0xFFFFCA57),
      Color(0xFFFF6B6B),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF4F35E1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // ── Decorative circles ─────────────────────────────────────────
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -30, left: -30,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF864AF9).withOpacity(0.12),
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📊 Weekly Report',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.6),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userName,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Text(
                        '$weekOf – $weekEnd',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Stat pills ───────────────────────────────────────────
                Row(
                  children: [
                    _ShareStat(
                      emoji: '📚',
                      value: '${totalMins ~/ 60}h ${totalMins % 60}m',
                      label: 'Study Time',
                      accentColor: const Color(0xFF00FFC6),
                    ),
                    const SizedBox(width: 10),
                    _ShareStat(
                      emoji: '🎯',
                      value: '$avgFocus%',
                      label: 'Avg Focus',
                      accentColor: const Color(0xFFFFCA57),
                    ),
                    const SizedBox(width: 10),
                    _ShareStat(
                      emoji: '⚡',
                      value: '$totalSessions',
                      label: 'Sessions',
                      accentColor: const Color(0xFFFF6B6B),
                    ),
                  ],
                ),

                // ── Subject mini-bars ────────────────────────────────────
                if (displaySubjects.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'TOP SUBJECTS',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.5),
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...displaySubjects.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final e = entry.value;
                    final pct = totalMins > 0
                        ? (e.value / totalMins).clamp(0.0, 1.0)
                        : 0.0;
                    final color = subjectColors[idx % subjectColors.length];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withOpacity(0.85),
                                  )),
                              Text('${e.value ~/ 60}h ${e.value % 60}m',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.5),
                                  )),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 5,
                              backgroundColor: Colors.white.withOpacity(0.08),
                              valueColor: AlwaysStoppedAnimation(color),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 20),

                // ── Branding footer ──────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF00FFC6), Color(0xFF4F35E1)],
                            ),
                          ),
                          child: const Center(
                            child: Text('🎓', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI Study Coach',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00FFC6), Color(0xFF00C896)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Keep grinding! 🔥',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Share Stat Tile ───────────────────────────────────────────────────────────
class _ShareStat extends StatelessWidget {
  final String emoji, value, label;
  final Color accentColor;

  const _ShareStat({
    required this.emoji,
    required this.value,
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withOpacity(0.35), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 6),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ),
      );
}

