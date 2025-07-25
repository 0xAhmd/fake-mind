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
    buffer.writeln('${'=' * 50}');

    for (final message in messages) {
      final sender = message.isUser ? 'You' : 'AI';
      buffer.writeln('[$sender] ${message.timestamp}');
      buffer.writeln(message.content);
      buffer.writeln();
    }

    return buffer.toString();
  }
}
