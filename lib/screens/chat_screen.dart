import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message.dart';
import '../models/user.dart';
import '../providers.dart';
import '../repositories/request_repository.dart';
import '../repositories/team_repository.dart';
import '../utils/ids.dart';
import '../widgets/app_background.dart';
import '../widgets/async_state_view.dart';
import '../widgets/chat_parts.dart';
import '../theme/app_theme.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String channel;
  final String title;
  final UserModel user;

  const ChatScreen({
    super.key,
    required this.channel,
    required this.title,
    required this.user,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    // Fresh data from Firestore when the chat opens (receiver side).
    _refresh();
  }

  Future<void> _refresh() async {
    final repo = ref.read(chatRepositoryProvider);
    repo.resetLoaded();
    try {
      await repo.load(user: widget.user);
    } catch (_) {
      // permission/network issue - empty state dikhega
    }
    if (mounted) ref.invalidate(chatMessagesAsyncProvider(widget.channel));
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// Owner email from the request doc — denormalized into the message when
  /// sending on chat (the rules read this without get()).
  String? _requestUserEmail(String requestId) {
    for (final r in RequestRepository.instance.all) {
      if (r.id == requestId) return r.userEmail;
    }
    return null;
  }

  String? _requestAssignedTo(String requestId) {
    for (final r in RequestRepository.instance.all) {
      if (r.id == requestId) return r.assignedTo;
    }
    return null;
  }

  Future<void> _send() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    _chatController.clear();
    final displayName = ref.read(displayNameProvider(widget.user));
    try {
      await ref.read(chatRepositoryProvider).addMessage(
        ChatMessage(
          id: generateId(),
          channel: widget.channel,
          senderEmail: widget.user.email,
          senderName: displayName,
          text: text,
          sentAt: DateTime.now(),
          // The rules' read gate relies on these fields (without get()).
          // team:{owner} → ownerEmail + memberEmails; request:{id} → userEmail + assignedTo.
          ownerEmail: widget.channel.startsWith('team:')
              ? widget.channel.substring(5)
              : null,
          memberEmails: widget.channel.startsWith('team:')
              ? TeamRepository.instance
                  .subTeamOf(widget.channel.substring(5))
                  .map((m) => m.email)
                  .toList()
              : null,
          userEmail: widget.channel.startsWith('request:')
              ? _requestUserEmail(widget.channel.substring(8))
              : null,
          assignedTo: widget.channel.startsWith('request:')
              ? _requestAssignedTo(widget.channel.substring(8))
              : null,
          // SEC-01 v2: rules do not parse the channel — doc path comes from requestId.
          requestId: widget.channel.startsWith('request:')
              ? widget.channel.substring(8)
              : null,
        ),
      );
    } catch (e) {
      // No silent failure — restore the text and show the real error.
      _chatController.text = text;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Message could not be sent — $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!mounted) return;
    ref.invalidate(chatMessagesAsyncProvider(widget.channel));
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final asyncMsgs = ref.watch(chatMessagesAsyncProvider(widget.channel));
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppPalette.textPrimary, size: 20),
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          color: AppPalette.textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(Icons.chat_bubble_rounded,
                        color: Color(0xFF00A86B), size: 22),
                  ],
                ),
              ),
              Expanded(
                child: asyncMsgs.when(
                  loading: () => const LoadingView(),
                  error: (e, st) => ErrorRetryView(
                    error: e,
                    message: 'Messages could not be loaded',
                    onRetry: () => ref
                        .read(chatMessagesAsyncProvider(widget.channel).notifier)
                        .refresh(widget.channel),
                  ),
                  data: (messages) => ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    children: [
                      if (messages.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No messages yet\nSend the first message',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppPalette.textMuted, fontSize: 13),
                          ),
                        ),
                      for (final m in messages)
                        ChatBubble(
                          message: m,
                          mine: m.senderEmail == widget.user.email,
                        ),
                    ],
                  ),
                ),
              ),
              ChatInputBar(
                controller: _chatController,
                onSend: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}