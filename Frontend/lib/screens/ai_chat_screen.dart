import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/ai_coach_provider.dart';
import '../providers/voice_agent_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/animations.dart';
import '../app_theme.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final has = _ctrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    setState(() => _hasText = false);
    ref.read(aiCoachProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _sendQuick(String text) {
    _ctrl.text = text;
    _send();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiCoachProvider);
    final voiceState = ref.watch(voiceAgentProvider);
    ref.listen(aiCoachProvider, (_, __) => _scrollToBottom());

    return Scaffold(
      backgroundColor: AppColors.background,
      // ── App Bar ────────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              // Animated AI avatar
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: state.isLoading
                      ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF14B8A6)])
                      : AppColors.heroGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (state.isLoading ? AppColors.accentGreen : AppColors.primary).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'AI Study Coach',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      state.isLoading ? '✦ Thinking...' : '● Online',
                      key: ValueKey(state.isLoading),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: state.isLoading ? AppColors.accentGreen : const Color(0xFF22C55E),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (voiceState.isSpeaking)
            PressButton(
              scaleDown: 0.88,
              onTap: () => ref.read(voiceAgentProvider.notifier).stopSpeaking(),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.volume_off_rounded, size: 16, color: Colors.white),
              ),
            ),
          PressButton(
            scaleDown: 0.88,
            onTap: () => ref.read(aiCoachProvider.notifier).clearChat(),
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(children: [
                const Icon(Icons.refresh_rounded, size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('Clear', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ]),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Messages ──────────────────────────────────────────────────────
          Expanded(
            child: state.messages.isEmpty
                ? const _EmptyChat()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    itemCount: state.messages.length + (state.isLoading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == state.messages.length) return const _TypingBubble();
                      final msg = state.messages[i];
                      return AnimatedChatBubble(
                        isUser: msg.isUser,
                        child: ChatBubble(message: msg),
                      );
                    },
                  ),
          ),

          // ── Error banner ──────────────────────────────────────────────────
          if (state.error != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              color: const Color(0xFFFFF4F0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: GoogleFonts.outfit(color: const Color(0xFFEF4444), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // ── Input bar ─────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              left: 14, right: 14, top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Text field
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: _hasText ? AppColors.primary.withOpacity(0.4) : AppColors.divider,
                        width: _hasText ? 1.5 : 1,
                      ),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: voiceState.isListening ? 'Listening...' : 'Ask your AI coach...',
                        hintStyle: GoogleFonts.outfit(color: voiceState.isListening ? AppColors.primary : AppColors.textLight, fontSize: 14, fontStyle: voiceState.isListening ? FontStyle.italic : null),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      onChanged: (text) {
                        if (voiceState.isListening) {
                           // Disable text entry while listening to avoid conflict
                        }
                      },
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Microphone button
                PressButton(
                  scaleDown: 0.9,
                  onTap: state.isLoading 
                      ? null 
                      : () {
                          final notifier = ref.read(voiceAgentProvider.notifier);
                          if (voiceState.isListening) {
                            notifier.stopListening();
                          } else {
                            notifier.startListening();
                          }
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: voiceState.isListening ? AppColors.heroGradient : null,
                      color: voiceState.isListening ? null : AppColors.background,
                      shape: BoxShape.circle,
                      border: voiceState.isListening ? null : Border.all(color: AppColors.divider),
                      boxShadow: voiceState.isListening
                          ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]
                          : [],
                    ),
                    child: Icon(
                      voiceState.isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: voiceState.isListening ? Colors.white : AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Send button
                PressButton(
                  scaleDown: 0.9,
                  onTap: (state.isLoading || !_hasText) ? null : _send,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: (_hasText && !state.isLoading) ? AppColors.heroGradient : null,
                      color: (_hasText && !state.isLoading) ? null : AppColors.divider,
                      shape: BoxShape.circle,
                      boxShadow: (_hasText && !state.isLoading)
                          ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]
                          : [],
                    ),
                    child: Icon(
                      state.isLoading ? Icons.more_horiz_rounded : Icons.send_rounded,
                      color: (_hasText && !state.isLoading) ? Colors.white : AppColors.textLight,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────
class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) => Center(
        child: FadeSlideIn(
          duration: const Duration(milliseconds: 500),
          beginOffset: const Offset(0, 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing avatar
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Icon(Icons.smart_toy_rounded, size: 44, color: Colors.white),
                ),
                const SizedBox(height: 20),

                Text(
                  'Your AI Study Coach 🤖',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Ask me anything — concepts, quiz me,\nor get a personalised study plan!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 28),

                // Quick action chips
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _QuickChip(emoji: '📚', label: 'Explain a concept'),
                    _QuickChip(emoji: '🧠', label: 'Quiz me'),
                    _QuickChip(emoji: '🎯', label: 'Study tips'),
                    _QuickChip(emoji: '📝', label: 'Summarise notes'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

// ── Quick chip ───────────────────────────────────────────────────────────────
class _QuickChip extends ConsumerWidget {
  final String emoji;
  final String label;
  const _QuickChip({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PressButton(
      scaleDown: 0.94,
      onTap: () => ref.read(aiCoachProvider.notifier).sendMessage('$emoji $label'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Typing indicator bubble ──────────────────────────────────────────────────
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 30, height: 30,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i / 3;
                    final value = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
                    final scale = 0.6 + 0.4 * (value < 0.5 ? value * 2 : (1 - value) * 2);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.3 + scale * 0.7),
                        shape: BoxShape.circle,
                      ),
                      transform: Matrix4.identity()..scale(scale),
                      transformAlignment: Alignment.center,
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      );
}
