import 'package:fake_mind/chat/domain/repo/chat_repo.dart';

import '../../data/model/chat_model.dart';

class ChatManagementUseCase {
  final ChatRepository _repository;

  ChatManagementUseCase(this._repository);

  Future<List<ChatModel>> getAllChats() => _repository.getAllChats();

  Future<ChatModel?> getChat(String chatId) => _repository.getChat(chatId);

  Future<void> createChat({String? title, String? firstMessage}) async {
    final chat = ChatModel(
      title:
          title ??
          (firstMessage != null ? _generateTitle(firstMessage) : 'New Chat'),
    );
    await _repository.insertChat(chat);
  }

  Future<void> renameChat(String chatId, String newName) async {
    final chat = await _repository.getChat(chatId);
    if (chat != null) {
      final updatedChat = chat.copyWith(
        title: newName.trim(),
        updatedAt: DateTime.now(),
      );
      await _repository.updateChat(updatedChat);
    }
  }

  Future<void> togglePin(String chatId) async {
    final chat = await _repository.getChat(chatId);
    if (chat != null) {
      final updatedChat = chat.copyWith(isPinned: !chat.isPinned);
      await _repository.updateChat(updatedChat);
    }
  }

  Future<void> deleteChat(String chatId) => _repository.deleteChat(chatId);

  List<ChatModel> filterChats(List<ChatModel> chats, String query) {
    if (query.isEmpty) return chats;

    return chats.where((chat) {
      final titleMatch = chat.title.toLowerCase().contains(query.toLowerCase());
      final messageMatch =
          chat.lastMessage?.toLowerCase().contains(query.toLowerCase()) ??
          false;
      return titleMatch || messageMatch;
    }).toList();
  }

  String _generateTitle(String firstMessage) {
    final cleanMessage = firstMessage.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleanMessage.length <= 30) return cleanMessage;

    final words = cleanMessage.substring(0, 30).split(' ');
    if (words.length > 1) {
      words.removeLast();
      return '${words.join(' ')}...';
    }
    return '${cleanMessage.substring(0, 30)}...';
  }
}
