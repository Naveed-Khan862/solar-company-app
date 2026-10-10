import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message.dart';
import 'repository_providers.dart';

/// AsyncNotifier for chat messages on a specific channel.
/// Provides loading / error / data states via AsyncValue.
///
/// Usage:
/// ```dart
/// final asyncMsgs = ref.watch(chatMessagesAsyncProvider(channel));
/// asyncMsgs.when(
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => ErrorWidget(retry: ...),
///   data: (msgs) => ListView(...),
/// );
/// ```
class ChatMessagesAsyncNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<ChatMessage>, String> {
  @override
  Future<List<ChatMessage>> build(String channel) async {
    // Reactivity: every repo mutation (load/addMessage) emits a revision →
    // provider rebuild. Without this the chat never updated at all.
    ref.watch(chatRevisionsProvider);
    final repo = ref.read(chatRepositoryProvider);
    return repo.messagesForChannel(channel);
  }

  /// Refresh from Firestore.
  Future<void> refresh(String channel) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build(channel));
  }
}

/// Messages for a channel with loading/error states.
final chatMessagesAsyncProvider =
    AutoDisposeAsyncNotifierProvider.family<ChatMessagesAsyncNotifier,
        List<ChatMessage>, String>(
  ChatMessagesAsyncNotifier.new,
);
