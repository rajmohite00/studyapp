import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
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

  // Suggestions shown on the welcome screen
  static const _suggestions = [
    (Icons.layers_outlined, 'Explain Stack in DSA'),
    (Icons.code_outlined, 'Explain OOP concepts'),
    (Icons.quiz_outlined, 'Generate 10 MCQs on DBMS'),
    (Icons.note_outlined, 'Create notes on OS'),
    (Icons.psychology_outlined, 'Explain recursion simply'),
    (Icons.science_outlined, 'Summarize my topic'),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    final msg = text.trim();
    _ctrl.clear();
    ref.read(aiCoachProvider.notifier).sendMessage(msg);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Chat?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        content: const Text('This will erase the current conversation.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(aiCoachProvider.notifier).clearChat();
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiCoachProvider);
    final user = ref.watch(authStateProvider).user;
    final firstName = user?.name.split(' ').first ?? 'there';
    final hasMessages = aiState.messages.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('AI Tutor',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            Text(
              hasMessages ? 'Online' : 'Ask me anything',
              style: TextStyle(
                  fontSize: 11,
                  color: hasMessages
                      ? AppColors.accentGreen
                      : AppColors.textSecondary,
                  fontWeight: hasMessages ? FontWeight.w600 : FontWeight.w400),
            ),
          ]),
        ]),
        actions: [
          if (hasMessages)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.textSecondary, size: 22),
              onPressed: _confirmClear,
              tooltip: 'Clear chat',
            ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: Column(children: [
        // ── Chat / Welcome ──────────────────────────────
        Expanded(
          child: hasMessages
              ? _buildChatList(aiState)
              : _buildWelcome(firstName),
        ),
        // ── Input ───────────────────────────────────────
        _buildInputBar(aiState.isLoading),
      ]),
    );
  }

  // ── Welcome ────────────────────────────────────────────────────────────────
  Widget _buildWelcome(String firstName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(children: [
        // Avatar
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 6))
            ],
          ),
          child: const Icon(Icons.auto_awesome_rounded,
              color: Colors.white, size: 30),
        ),
        const SizedBox(height: 16),
        Text('Hi $firstName! 👋',
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        const Text("I'm your AI study companion.\nWhat would you like to learn today?",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5)),
        const SizedBox(height: 28),

        // Suggestion grid 2-col
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _suggestions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2),
          itemBuilder: (ctx, i) {
            final s = _suggestions[i];
            return GestureDetector(
              onTap: () => _send(s.$2),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8E8EE)),
                ),
                child: Row(children: [
                  Icon(s.$1, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(s.$2,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                            height: 1.3)),
                  ),
                ]),
              ),
            );
          },
        ),
      ]),
    );
  }

  // ── Chat list ──────────────────────────────────────────────────────────────
  Widget _buildChatList(AiCoachState aiState) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: aiState.messages.length +
          (aiState.isLoading ? 1 : 0) +
          (aiState.error != null ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i < aiState.messages.length) {
          return _Bubble(msg: aiState.messages[i]);
        }
        if (aiState.isLoading) return const _TypingBubble();
        if (aiState.error != null) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFE53E3E).withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFE53E3E), size: 16),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(aiState.error!,
                      style: const TextStyle(
                          color: Color(0xFFE53E3E), fontSize: 13))),
            ]),
          );
        }
        return const SizedBox();
      },
    );
  }

  // ── Input bar ──────────────────────────────────────────────────────────────
  Widget _buildInputBar(bool isLoading) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            textInputAction: TextInputAction.send,
            onSubmitted: _send,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(
              hintText: 'Ask anything...',
              hintStyle: const TextStyle(
                  color: AppColors.textLight, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF5F5F8),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 11),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: isLoading ? null : () => _send(_ctrl.text),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isLoading ? AppColors.textLight : AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(11),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded,
                    color: Colors.white, size: 18),
          ),
        ),
      ]),
    );
  }
}

// ── Bubble ─────────────────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final ChatMessage msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: const Color(0xFFEEEEEE)),
                boxShadow: isUser
                    ? []
                    : [
                        const BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 4,
                            offset: Offset(0, 2))
                      ],
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: isUser
                        ? Colors.white
                        : AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Typing bubble ──────────────────────────────────────────────────────────────
class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: const TypingIndicator(),
          ),
        ],
      ),
    );
  }
}
