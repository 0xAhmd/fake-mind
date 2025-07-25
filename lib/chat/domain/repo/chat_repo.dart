
import 'package:fake_mind/chat/data/model/chat_model.dart';
import 'package:fake_mind/chat/data/model/message_model.dart';

abstract class ChatRepository {
  Future<List<ChatModel>> getAllChats();
  Future<ChatModel?> getChat(String chatId);
  Future<void> insertChat(ChatModel chat);
  Future<void> updateChat(ChatModel chat);
  Future<void> deleteChat(String chatId);
  Future<List<MessageModel>> getMessagesForChat(String chatId);
  Future<void> insertMessage(MessageModel message);
  Future<void> deleteMessage(String messageId);
  Future<List<MessageModel>> searchMessages(String query, {String? chatId});
  Future<Map<String, dynamic>> getChatStatistics();
  Future<void> markMessageAsSynced(String messageId);
  Future<List<MessageModel>> getUnsyncedMessages();
  Future<List<MessageModel>> getFailedMessages();
  Future<void> incrementMessageRetryCount(String messageId);
  Future<void> deleteOldMessages({int daysOld = 30});
  Future<int> getDatabaseSize();
  Future<void> clearDatabase();
}
