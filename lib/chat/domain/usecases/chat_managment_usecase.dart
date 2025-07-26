// Fixed ChatManagementUseCase with proper sorting and better create logic
import 'package:fake_mind/chat/data/model/chat_model.dart';
import 'package:fake_mind/chat/domain/repo/chat_repo.dart';
import 'package:flutter/material.dart';

class ChatManagementUseCase {
  final ChatRepository _repository;

  ChatManagementUseCase(this._repository);

  Future<List<ChatModel>> getAllChats() async {
    try {
      final chats = await _repository.getAllChats();
      // Additional sorting to ensure consistency (pinned chats first, then by date)
      return _sortChats(chats);
    } catch (e) {
      debugPrint('Error getting all chats: $e');
      return [];
    }
  }

  List<ChatModel> _sortChats(List<ChatModel> chats) {
    // First separate pinned and unpinned chats
    final pinnedChats = chats.where((chat) => chat.isPinned).toList();
    final unpinnedChats = chats.where((chat) => !chat.isPinned).toList();

    // Sort both lists by updatedAt (newest first)
    pinnedChats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    unpinnedChats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // Return pinned chats first, then unpinned
    return [...pinnedChats, ...unpinnedChats];
  }

  Future<ChatModel?> getChat(String chatId) async {
    try {
      return await _repository.getChat(chatId);
    } catch (e) {
      debugPrint('Error getting chat: $e');
      return null;
    }
  }

  Future<ChatModel> createChat({String? title, String? firstMessage}) async {
    try {
      final chat = ChatModel(
        title: title ?? _generateChatTitle(firstMessage),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _repository.insertChat(chat);
      debugPrint('✅ Created new chat: ${chat.id} - ${chat.title}');
      return chat;
    } catch (e) {
      debugPrint('❌ Error creating chat: $e');
      rethrow;
    }
  }

  Future<void> renameChat(String chatId, String newTitle) async {
    try {
      debugPrint('🏷️ Renaming chat $chatId to: $newTitle');

      // Get the existing chat
      final existingChat = await _repository.getChat(chatId);
      if (existingChat == null) {
        debugPrint('❌ Chat not found: $chatId');
        throw Exception('Chat not found');
      }

      // Create updated chat with new title and updated timestamp
      final updatedChat = existingChat.copyWith(
        title: newTitle.trim(),
        updatedAt: DateTime.now(),
      );

      debugPrint('📝 Updating chat with new data: ${updatedChat.toMap()}');

      // Update the chat in repository
      await _repository.updateChat(updatedChat);

      debugPrint('✅ Successfully renamed chat: $chatId');
    } catch (e, stackTrace) {
      debugPrint('❌ Error renaming chat: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> togglePin(String chatId) async {
    try {
      debugPrint('📌 Toggling pin for chat: $chatId');

      final existingChat = await _repository.getChat(chatId);
      if (existingChat == null) {
        debugPrint('❌ Chat not found: $chatId');
        throw Exception('Chat not found');
      }

      final updatedChat = existingChat.copyWith(
        isPinned: !existingChat.isPinned,
        updatedAt: DateTime.now(),
      );

      await _repository.updateChat(updatedChat);
      debugPrint('✅ Successfully toggled pin for chat: $chatId');
    } catch (e) {
      debugPrint('❌ Error toggling pin: $e');
      rethrow;
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      debugPrint('🗑️ Deleting chat: $chatId');
      await _repository.deleteChat(chatId);
      debugPrint('✅ Successfully deleted chat: $chatId');
    } catch (e) {
      debugPrint('❌ Error deleting chat: $e');
      rethrow;
    }
  }

  List<ChatModel> filterChats(List<ChatModel> chats, String query) {
    if (query.isEmpty) return chats;

    final lowercaseQuery = query.toLowerCase();
    final filtered =
        chats
            .where(
              (chat) =>
                  chat.title.toLowerCase().contains(lowercaseQuery) ||
                  (chat.lastMessage?.toLowerCase().contains(lowercaseQuery) ??
                      false),
            )
            .toList();

    // Maintain sorting even after filtering
    return _sortChats(filtered);
  }

  String _generateChatTitle(String? firstMessage) {
    if (firstMessage != null && firstMessage.isNotEmpty) {
      // Use first 30 characters of the message as title
      return firstMessage.length > 30
          ? '${firstMessage.substring(0, 30)}...'
          : firstMessage;
    }
    return 'New Chat ${DateTime.now().millisecondsSinceEpoch}';
  }
}
