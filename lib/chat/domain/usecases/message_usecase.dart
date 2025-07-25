import 'package:fake_mind/chat/domain/repo/chat_repo.dart';

import '../../data/model/message_model.dart';
import '../../data/model/chat_model.dart';

class MessageUseCase {
  final ChatRepository _repository;

  MessageUseCase(this._repository);

  Future<List<MessageModel>> getMessagesForChat(String chatId) =>
      _repository.getMessagesForChat(chatId);

  Future<void> saveMessage(MessageModel message) =>
      _repository.insertMessage(message);

  Future<void> updateMessage(MessageModel message) =>
      _repository.updateMessage(message);

  Future<MessageModel?> getMessage(String messageId) =>
      _repository.getMessage(messageId);

  Future<void> deleteMessage(String messageId) =>
      _repository.deleteMessage(messageId);

  Future<List<MessageModel>> searchMessages(String query, {String? chatId}) =>
      _repository.searchMessages(query, chatId: chatId);

  Future<void> markAsSynced(String messageId) =>
      _repository.markMessageAsSynced(messageId);

  Future<List<MessageModel>> getUnsyncedMessages() =>
      _repository.getUnsyncedMessages();

  Future<List<MessageModel>> getFailedMessages() =>
      _repository.getFailedMessages();

  Future<Map<String, dynamic>> getStatistics() =>
      _repository.getChatStatistics();

  /// Creates a new bot message with regenerated content
  MessageModel createRegeneratedBotMessage({
    required String originalMessageId,
    required String chatId,
    required String newContent,
    required bool isOnline,
  }) {
    return MessageModel(
      id: originalMessageId, // Keep the same ID to replace the original
      chatId: chatId,
      content: newContent,
      isUser: false,
      synced: isOnline,
      timestamp: DateTime.now(), // Update timestamp
    );
  }

  /// Regenerates a bot message by creating a new message with updated content
  Future<MessageModel> regenerateBotMessage({
    required String messageId,
    required String newContent,
    required bool isOnline,
  }) async {
    final originalMessage = await _repository.getMessage(messageId);
    if (originalMessage == null) {
      throw Exception('Message not found: $messageId');
    }

    if (originalMessage.isUser) {
      throw Exception('Cannot regenerate user messages');
    }

    final regeneratedMessage = originalMessage.copyWith(
      content: newContent,
      synced: isOnline,
      timestamp: DateTime.now(),
    );

    await _repository.updateMessage(regeneratedMessage);
    return regeneratedMessage;
  }

  /// Gets the user message that preceded a bot message for regeneration
  Future<MessageModel?> getPreviousUserMessage(String botMessageId) async {
    final botMessage = await _repository.getMessage(botMessageId);
    if (botMessage == null || botMessage.isUser) {
      return null;
    }

    final chatMessages = await _repository.getMessagesForChat(
      botMessage.chatId,
    );

    // Sort messages by timestamp
    chatMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Find the bot message index
    final botMessageIndex = chatMessages.indexWhere(
      (m) => m.id == botMessageId,
    );
    if (botMessageIndex == -1) return null;

    // Look backwards for the most recent user message
    for (int i = botMessageIndex - 1; i >= 0; i--) {
      if (chatMessages[i].isUser) {
        return chatMessages[i];
      }
    }

    return null;
  }

  /// Gets the conversation context for a message (useful for retry with context)
  Future<List<MessageModel>> getConversationContext(
    String messageId, {
    int contextLimit = 10,
  }) async {
    final message = await _repository.getMessage(messageId);
    if (message == null) return [];

    final chatMessages = await _repository.getMessagesForChat(message.chatId);
    chatMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final messageIndex = chatMessages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return [];

    // Get context messages (up to contextLimit messages before the current one)
    final startIndex = (messageIndex - contextLimit).clamp(0, messageIndex);
    return chatMessages.sublist(startIndex, messageIndex);
  }

  MessageModel createUserMessage(String chatId, String content, bool isOnline) {
    return MessageModel(
      chatId: chatId,
      content: content,
      isUser: true,
      synced: isOnline,
    );
  }

  MessageModel createBotMessage(String chatId, String content, bool isOnline) {
    return MessageModel(
      chatId: chatId,
      content: content,
      isUser: false,
      synced: isOnline,
    );
  }

  String exportChatAsText(List<MessageModel> messages, ChatModel chat) {
    final buffer = StringBuffer();
    buffer.writeln('Chat Export: ${chat.title}');
    buffer.writeln('Created: ${chat.createdAt}');
    buffer.writeln('Last Updated: ${chat.updatedAt}');
    buffer.writeln('=' * 50);

    for (final message in messages) {
      final sender = message.isUser ? 'You' : 'AI';
      buffer.writeln('[$sender] ${message.timestamp}');
      buffer.writeln(message.content);
      buffer.writeln();
    }

    return buffer.toString();
  }
}
