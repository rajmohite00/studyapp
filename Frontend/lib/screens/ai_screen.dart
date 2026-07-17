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
  bool _showWelcome = true;

  static const _quickChips = [
    'Explain Stack in Data Structures',
    'Summarize this PDF',
    'Create Notes on DBMS',
    'Generate 20 MCQs',
    'Explain OOP in Java',
  ];

  static const _chipIcons = [
    Icons.layers_outlined,
    Icons.picture_as_pdf_outlined,
    Icons.note_outlined,
    Icons.quiz_outlined,
    Icons.code_outlined,
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    _ctrl.clear();
    setState(() => _showWelcome = false);
    ref.read(aiCoachProvider.notifier).sendMessage(text.trim());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiCoachProvider);
    final user = ref.watch(authStateProvider).user;
    final firstName = user?.name.split(' ').first ?? 'there';

    // Once messages arrive, switch off welcome
    if (aiState.messages.isNotEmpty && _showWelcome) {
      _showWelcome = false;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('AI Study Assistant',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.read(aiCoachProvider.notifier).clearChat(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Chat / Welcome area ─────────────────────────
          Expanded(
            child: _showWelcome
                ? _WelcomeView(
                    firstName: firstName,
                    chips: _quickChips,
                    icons: _chipIcons,
                    onChip: _send,
                  )
                : _ChatView(
                    messages: aiState.messages,
                    isLoading: aiState.isLoading,
                    scroll: _scroll,
                    error: aiState.error,
                  ),
          ),
          // ── Input bar ──────────────────────────────────
          _InputBar(
            controller: _ctrl,
            onSend: _send,
            isLoading: aiState.isLoading,
          ),
        ],
      ),
    );
  }
}

// ── Welcome view ───────────────────────────────────────────────────────────────
class _WelcomeView extends StatelessWidget {
  final String firstName;
  final List<String> chips;
  final List<IconData> icons;
  final ValueChanged<String> onChip;
  const _WelcomeView(
      {required this.firstName,
      required this.chips,
      required this.icons,
      required this.onChip});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 16),
          Text('Hello $firstName! 👋',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('How can I help you today?',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 28),
          ...List.generate(chips.length, (i) {
            return GestureDetector(
              onTap: () => onChip(chips[i]),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Row(children: [
                  Icon(icons[i], color: AppColors.primary, size: 18),
                  const SizedBox(width: 12),
                  Text(chips[i],
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary)),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Chat view ──────────────────────────────────────────────────────────────────
class _ChatView extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool isLoading;
  final ScrollController scroll;
  final String? error;
  const _ChatView(
      {required this.messages,
      required this.isLoading,
      required this.scroll,
      this.error});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: messages.length + (isLoading ? 1 : 0) + (error != null ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i < messages.length) {
          final msg = messages[i];
          return _Bubble(message: msg);
        }
        if (isLoading) return const _TypingBubble();
        if (error != null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                  color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.primary, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: isUser
                    ? []
                    : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                    fontSize: 14,
                    color: isUser ? Colors.white : AppColors.textPrimary,
                    height: 1.5),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
              color: AppColors.primaryLight, shape: BoxShape.circle),
          child: const Icon(Icons.auto_awesome_rounded,
              color: AppColors.primary, size: 14),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
              ]),
          child: const TypingIndicator(),
        ),
      ]),
    );
  }
}

// ── Input bar ──────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final bool isLoading;
  const _InputBar(
      {required this.controller, required this.onSend, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: controller,
            onSubmitted: onSend,
            decoration: InputDecoration(
              hintText: 'Type your message...',
              filled: true,
              fillColor: AppColors.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none),
            ),
            textInputAction: TextInputAction.send,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: isLoading ? null : () => onSend(controller.text),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isLoading ? AppColors.textLight : AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.arrow_upward_rounded,
                    color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}
