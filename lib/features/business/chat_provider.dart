// ============================================================
// CHAT PROVIDER — GetWork App
// Riverpod state for conversations list + messages
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chat_repository.dart';

// ── Conversations list provider ───────────────────────────────
class ConversationsNotifier
    extends AsyncNotifier<List<ConversationModel>> {
  @override
  Future<List<ConversationModel>> build() async {
    return ChatRepository.instance.fetchConversations();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ChatRepository.instance.fetchConversations(),
    );
  }
}

final conversationsProvider =
    AsyncNotifierProvider<ConversationsNotifier, List<ConversationModel>>(
  ConversationsNotifier.new,
);

// ── Messages for a conversation provider ─────────────────────
class MessagesNotifier
    extends AsyncNotifier<List<MessageModel>> {
  late String _conversationId;

  void setConversationId(String id) {
    _conversationId = id;
  }

  @override
  Future<List<MessageModel>> build() async {
    return [];
  }

  Future<void> loadMessages(String conversationId) async {
    _conversationId = conversationId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ChatRepository.instance.fetchMessages(conversationId),
    );
  }

  Future<void> sendMessage(String body, String senderName) async {
    final sent = await ChatRepository.instance.sendMessage(
      conversationId: _conversationId,
      body: body,
      senderName: senderName,
    );
    if (sent) {
      await loadMessages(_conversationId);
    }
  }
}

final messagesProvider =
    AsyncNotifierProvider<MessagesNotifier, List<MessageModel>>(
  MessagesNotifier.new,
);
