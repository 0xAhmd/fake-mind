import 'dart:async';
import 'package:fake_mind/chat/domain/repo/chat_repo.dart';

import '../../data/services/firebase/firebase_service.dart';
import '../../data/model/chat_model.dart';
import '../../data/model/message_model.dart';

class SyncUseCase {
  final ChatRepository _repository;
  final FirebaseService _firebaseService;

  SyncUseCase(this._repository, this._firebaseService);

  Future<void> syncToFirebase(
    List<ChatModel> chats,
    List<MessageModel> messages,
  ) async {
    // Sync unsynced messages
    final unsyncedMessages = await _repository.getUnsyncedMessages();

    // Sync unsynced chats
    final unsyncedChats =
        chats
            .where(
              (chat) =>
                  !unsyncedMessages.any(
                    (msg) => msg.chatId == chat.id && msg.synced,
                  ),
            )
            .toList();

    await _firebaseService.syncUnsyncedData(unsyncedChats, unsyncedMessages);

    // Mark messages as synced
    for (final message in unsyncedMessages) {
      await _repository.markMessageAsSynced(message.id);
    }
  }

  Future<List<ChatModel>> syncFromFirebase() async {
    final firebaseChats = await _firebaseService.getChatsFromFirestore();

    for (final chat in firebaseChats) {
      final existingChat = await _repository.getChat(chat.id);
      if (existingChat == null) {
        await _repository.insertChat(chat);
      } else if (chat.updatedAt.isAfter(existingChat.updatedAt)) {
        await _repository.updateChat(chat);
      }
    }

    // Return sorted chats from repository (it will handle sorting)
    return await _repository.getAllChats();
  }

  Future<void> syncChat(ChatModel chat) => _firebaseService.syncChat(chat);

  Future<void> syncMessage(MessageModel message) =>
      _firebaseService.syncMessage(message);

  Stream<List<MessageModel>> getMessageStream(String chatId) =>
      _firebaseService.getMessageStream(chatId);
}
