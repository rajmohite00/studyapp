import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/ai_coach_provider.dart';
import '../models/chat_message_model.dart';
import '../widgets/animations.dart';
import '../app_theme.dart';

class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});
  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _hasText = false;

  static const _prompts = [
    (Icons.science_outlined,    'Explain Quantum Physics',  'Break down core concepts'),
    (Icons.menu_book_outlined,  'Summarize Chapter 4',      'Key takeaways & definitions'),
    (Icons.quiz_outlined,       'Quiz me on Biology',       'Test my knowledge'),
    (Icons.edit_note_outlined,  'Create study notes',       'Summarize any topic'),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final has = _ctrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final msg = (text ?? _ctrl.text).trim();
    if (msg.isEmpty) return;
    _ctrl.clear();
    setState(() => _hasText = false);
    ref.read(aiCoachProvider.notifier).sendMessage(msg);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiCoachProvider);
    ref.listen(aiCoachProvider, (_, __) => _scrollToBottom());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, state),
      body: Column(children: [
        Expanded(
          child: state.messages.isEmpty
              ? _buildWelcome()
              : _buildChat(state),
        ),
        if (state.error != null) _ErrorBanner(msg: state.error!),
        _InputBar(
          ctrl: _ctrl,
          hasText: _hasText,
          isLoading: state.isLoading,
          onSend: () => _send(),
        ),
      ]),
    );
  }

  AppBar _buildAppBar(BuildContext context, AiCoachState state) => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    centerTitle: true,
    title: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 32, height: 32,
        decoration: const BoxDecoration(
            gradient: AppColors.heroGradient, shape: BoxShape.circle),
        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
      ),
      const SizedBox(width: 8),
      Text('AI Tutor', style: GoogleFonts.outfit(
          fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    ]),
    actions: [
      if (state.messages.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: AppColors.textSecondary, size: 22),
          onPressed: () => ref.read(aiCoachProvider.notifier).clearChat(),
          tooltip: 'Clear chat',
        ),
    ],
    bottom: const PreferredSize(preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFF0F0F5))),
  );

  Widget _buildWelcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(children: [
        // Glowing avatar
        Container(
          width: 76, height: 76,
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 22, offset: const Offset(0, 8))],
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 18),
        Text('How can I help you study?',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800,
                color: AppColors.textPrimary, letterSpacing: -0.3),
            textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text('Ask anything — concepts, quizzes, summaries',
            style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center),
        const SizedBox(height: 28),
        ..._prompts.map((p) => _PromptCard(
          icon: p.$1, title: p.$2, subtitle: p.$3,
          onTap: () => _send(p.$2),
        )),
      ]),
    );
  }

  Widget _buildChat(AiCoachState state) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: state.messages.length + (state.isLoading ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == state.messages.length) return const TypingIndicator();
        return _ChatBubble(msg: state.messages[i]);
      },
    );
  }
}

// ── Prompt suggestion card ────────────────────────────────────────────────────
class _PromptCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _PromptCard({required this.icon, required this.title,
      required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE8F4)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.outfit(fontSize: 14,
              fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text(subtitle, style: GoogleFonts.outfit(fontSize: 12,
              color: AppColors.textSecondary)),
        ])),
        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textLight),
      ]),
    ),
  );
}

// ── Chat Bubble ───────────────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final ChatMessage msg;
  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: isUser ? 56 : 0,
        right: isUser ? 0 : 56,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 30, height: 30,
              decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Text(msg.content,
                  style: GoogleFonts.outfit(fontSize: 14, height: 1.55,
                      color: isUser ? Colors.white : AppColors.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error Banner ──────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String msg;
  const _ErrorBanner({required this.msg});
  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFFFF4F4),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(children: [
      const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(msg,
          style: GoogleFonts.outfit(color: const Color(0xFFEF4444), fontSize: 12))),
    ]),
  );
}

// ── Input Bar ─────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool hasText, isLoading;
  final VoidCallback onSend;
  const _InputBar({required this.ctrl, required this.hasText,
      required this.isLoading, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 120),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: hasText
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : const Color(0xFFE8E6F0),
                  width: hasText ? 1.5 : 1),
            ),
            child: TextField(
              controller: ctrl,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Ask anything...',
                hintStyle: GoogleFonts.outfit(color: AppColors.textLight, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: (isLoading || !hasText) ? null : onSend,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: (hasText && !isLoading) ? AppColors.heroGradient : null,
              color: (hasText && !isLoading) ? null : AppColors.divider,
              shape: BoxShape.circle,
              boxShadow: (hasText && !isLoading)
                  ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 12, offset: const Offset(0, 4))]
                  : [],
            ),
            child: Icon(
              isLoading ? Icons.more_horiz_rounded : Icons.send_rounded,
              color: (hasText && !isLoading) ? Colors.white : AppColors.textLight,
              size: 20,
            ),
          ),
        ),
      ]),
    );
  }
}
