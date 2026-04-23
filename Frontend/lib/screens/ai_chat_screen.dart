import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_coach_provider.dart';
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

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    ref.read(aiCoachProvider.notifier).sendMessage(text);
    _scrollToBottom();
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

    // auto-scroll when new messages arrive
    ref.listen(aiCoachProvider, (_, __) => _scrollToBottom());

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(height: 1.5, color: AppColors.divider.withOpacity(0.3)),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: state.isLoading
                    ? AppColors.accentGreen.withOpacity(0.15)
                    : AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.smart_toy_rounded,
                color: state.isLoading ? AppColors.accentGreen : AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Coach', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 11,
                    color: state.isLoading ? AppColors.accentGreen : AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                  child: Text(state.isLoading ? 'Thinking...' : 'Ready to help'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PressButton(
            onTap: () => ref.read(aiCoachProvider.notifier).clearChat(),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider.withOpacity(0.4)),
              ),
              child: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: state.messages.isEmpty
                ? const _EmptyChat()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: state.messages.length + (state.isLoading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == state.messages.length) return const TypingIndicator();
                      final msg = state.messages[i];
                      return AnimatedChatBubble(
                        isUser: msg.isUser,
                        child: ChatBubble(message: msg),
                      );
                    },
                  ),
          ),
          if (state.error != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              color: const Color(0xFFFFF0F0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFE07A5F), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: Color(0xFFE07A5F), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          // ── Input bar ─────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 10,
              bottom: MediaQuery.of(context).padding.bottom + 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.divider.withOpacity(0.25), width: 1.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.divider.withOpacity(0.5),
                      ),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                        hintText: 'Ask me anything...',
                        hintStyle: TextStyle(color: AppColors.textLight, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                      ),
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      onSubmitted: (_) => _send(),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                PressButton(
                  onTap: state.isLoading ? null : _send,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: state.isLoading ? AppColors.textLight : AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.textPrimary, width: 2),
                      boxShadow: state.isLoading
                          ? []
                          : const [BoxShadow(color: AppColors.textPrimary, offset: Offset(2, 2))],
                    ),
                    child: Icon(
                      state.isLoading ? Icons.hourglass_empty_rounded : Icons.send_rounded,
                      color: AppColors.textPrimary,
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

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) => Center(
        child: FadeSlideIn(
          duration: const Duration(milliseconds: 500),
          beginOffset: const Offset(0, 0.1),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.textPrimary, width: 3),
                    boxShadow: const [BoxShadow(color: AppColors.textPrimary, offset: Offset(4, 4))],
                  ),
                  child: const Icon(Icons.smart_toy_rounded, size: 48, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Your AI Study Coach',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ask me anything about your subjects,\nget study tips, or generate a quiz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _QuickChip(label: '📚 Explain a concept'),
                    _QuickChip(label: '📝 Quiz me'),
                    _QuickChip(label: '🎯 Study tips'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _QuickChip extends StatelessWidget {
  final String label;
  const _QuickChip({required this.label});

  @override
  Widget build(BuildContext context) => PressButton(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.textPrimary, width: 2),
            boxShadow: const [BoxShadow(color: AppColors.textPrimary, offset: Offset(2, 2))],
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          ),
        ),
      );
}
