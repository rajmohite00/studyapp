import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/ai_coach_provider.dart';
import '../widgets/chat_bubble.dart';
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiCoachProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.06),
        surfaceTintColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('AI Coach', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.quiz_outlined, size: 20),
            onPressed: () {
              context.push('/ai/quiz', extra: {'subject': 'General', 'questions': []});
            },
            tooltip: 'Generate Quiz',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () => ref.read(aiCoachProvider.notifier).clearChat(),
            tooltip: 'New Chat',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Divider
          Container(height: 1, color: AppColors.divider),
          Expanded(
            child: state.messages.isEmpty
                ? _EmptyChat()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: state.messages.length + (state.isLoading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == state.messages.length) return const TypingIndicator();
                      return ChatBubble(message: state.messages[i]);
                    },
                  ),
          ),
          if (state.error != null)
            Container(
              color: const Color(0xFFFFF0F0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFE07A5F), size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.error!, style: const TextStyle(color: Color(0xFFE07A5F), fontSize: 12))),
                ],
              ),
            ),
          // ── Input bar ─────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -3))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.divider),
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
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: state.isLoading ? AppColors.divider : AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: state.isLoading ? [] : [
                      BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      state.isLoading ? Icons.hourglass_empty_rounded : Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: state.isLoading ? null : _send,
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
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy_rounded, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              const Text(
                'Your AI Study Coach',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ask me anything about your subjects,\nget study tips, or generate a quiz.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              // Quick start chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: const [
                  _QuickChip(label: '📚 Explain a concept'),
                  _QuickChip(label: '📝 Quiz me'),
                  _QuickChip(label: '🎯 Study tips'),
                ],
              ),
            ],
          ),
        ),
      );
}

class _QuickChip extends StatelessWidget {
  final String label;
  const _QuickChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
      );
}
