import 'package:fake_mind/chat/data/model/chat_model.dart';
import 'package:fake_mind/chat/data/model/message_model.dart';
import 'package:fake_mind/chat/domain/repo/chat_repo.dart';

import '../services/offline/db_helper.dart';

class ChatRepositoryImpl implements ChatRepository {
  final DatabaseHelper _databaseHelper;

  ChatRepositoryImpl(this._databaseHelper);

  @override
  Future<List<ChatModel>> getAllChats() => _databaseHelper.getAllChats();

  @override
  Future<ChatModel?> getChat(String chatId) => _databaseHelper.getChat(chatId);

  @override
  Future<void> insertChat(ChatModel chat) => _databaseHelper.insertChat(chat);

  @override
  Future<void> updateChat(ChatModel chat) => _databaseHelper.updateChat(chat);

  @override
  Future<void> deleteChat(String chatId) => _databaseHelper.deleteChat(chatId);

  @override
  Future<List<MessageModel>> getMessagesForChat(String chatId) =>
      _databaseHelper.getMessagesForChat(chatId);

  @override
  Future<void> insertMessage(MessageModel message) =>
      _databaseHelper.insertMessage(message);

  @override
  Future<void> updateMessage(MessageModel message) =>
      _databaseHelper.updateMessage(message);

  @override
  Future<MessageModel?> getMessage(String messageId) =>
      _databaseHelper.getMessage(messageId);

  @override
  Future<void> deleteMessage(String messageId) =>
      _databaseHelper.deleteMessage(messageId);

  @override
  Future<List<MessageModel>> searchMessages(String query, {String? chatId}) =>
      _databaseHelper.searchMessages(query, chatId: chatId);

  @override
  Future<Map<String, dynamic>> getChatStatistics() =>
      _databaseHelper.getChatStatistics();

  @override
  Future<void> markMessageAsSynced(String messageId) =>
      _databaseHelper.markMessageAsSynced(messageId);

  @override
  Future<List<MessageModel>> getUnsyncedMessages() =>
      _databaseHelper.getUnsyncedMessages();

  @override
  Future<List<MessageModel>> getFailedMessages() =>
      _databaseHelper.getFailedMessages();

  @override
  Future<void> incrementMessageRetryCount(String messageId) =>
      _databaseHelper.incrementMessageRetryCount(messageId);

  @override
  Future<void> deleteOldMessages({int daysOld = 30}) =>
      _databaseHelper.deleteOldMessages(daysOld: daysOld);

  @override
  Future<int> getDatabaseSize() => _databaseHelper.getDatabaseSize();

  @override
  Future<void> clearDatabase() => _databaseHelper.clearDatabase();
}
