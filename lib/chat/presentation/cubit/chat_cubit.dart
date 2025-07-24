// lib/chat/presentation/bloc/chat_cubit.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../data/db_helper.dart';
import '../../data/services/firebase/firebase_service.dart';
import '../../data/services/firebase/google_generative_api_service.dart';
import '../../data/services/offline/connectivity_service.dart';
import '../../data/model/message_model.dart';
import '../../data/model/chat_model.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final _apiService = GoogleGenerativeApiService(
    apiKey: dotenv.env['API_KEY'] ?? '',
  );
  final _databaseHelper = DatabaseHelper.instance;
  final _firebaseService = FirebaseService();
  final _connectivityService = ConnectivityService();

  // Stream subscriptions
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<List<MessageModel>>? _messageStreamSubscription;
  Timer? _syncTimer;
  Timer? _retryTimer;

  ChatCubit() : super(const ChatInitial()) {
    _initializeCubit();
  }

  Future<void> _initializeCubit() async {
    try {
      // Initialize Firebase Auth
      await _firebaseService.signInAnonymously();

      // Initialize connectivity monitoring
      _connectivitySubscription = _connectivityService.connectivityStream
          .listen(_onConnectivityChanged);
      final isOnline = await _connectivityService.hasConnection();

      // Load initial data
      final chatHistory = await _databaseHelper.getAllChats();
      final statistics = await _databaseHelper.getChatStatistics();

      // Emit initial loaded state
      emit(ChatLoaded(
        chatHistory: chatHistory,
        filteredChats: chatHistory,
        statistics: statistics,
        isOnline: isOnline,
      ));

      // Sync data if online
      if (isOnline) {
        await _syncDataWithFirebase();
      }

      // Set up periodic sync
      _startPeriodicSync();
    } catch (e) {
      emit(ChatError(error: 'Failed to initialize: $e'));
      debugPrint('Error initializing ChatCubit: $e');
    }
  }

  void _onConnectivityChanged(bool isOnline) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final wasOffline = !currentState.isOnline;
      
      emit(currentState.copyWith(isOnline: isOnline));

      if (isOnline && wasOffline) {
        // Just came back online
        await _syncDataWithFirebase();
        await retryFailedMessages();
      }
    }
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (state is ChatLoaded && (state as ChatLoaded).isOnline) {
        _syncDataWithFirebase();
      }
    });
  }

  Future<void> _loadChatHistory() async {
    try {
      final localChats = await _databaseHelper.getAllChats();
      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        emit(currentState.copyWith(
          chatHistory: localChats,
          filteredChats: currentState.searchQuery.isEmpty 
              ? localChats 
              : _filterChats(localChats, currentState.searchQuery),
        ));
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final statistics = await _databaseHelper.getChatStatistics();
      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        emit(currentState.copyWith(statistics: statistics));
      }
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  Future<void> _syncDataWithFirebase() async {
    if (state is! ChatLoaded || !(state as ChatLoaded).isOnline) return;

    try {
      final currentState = state as ChatLoaded;
      
      // Get unsynced messages
      final unsyncedMessages = await _databaseHelper.getUnsyncedMessages();

      // Get unsynced chats
      final unsyncedChats = currentState.chatHistory
          .where((chat) => !unsyncedMessages.any(
              (msg) => msg.chatId == chat.id && msg.synced))
          .toList();

      // Sync unsynced data
      await _firebaseService.syncUnsyncedData(unsyncedChats, unsyncedMessages);

      // Mark messages as synced
      for (final message in unsyncedMessages) {
        await _databaseHelper.markMessageAsSynced(message.id);
      }

      // Sync chat history from Firebase
      final firebaseChats = await _firebaseService.getChatsFromFirestore();
      for (final chat in firebaseChats) {
        final existingChat = await _databaseHelper.getChat(chat.id);
        if (existingChat == null) {
          await _databaseHelper.insertChat(chat);
        } else if (chat.updatedAt.isAfter(existingChat.updatedAt)) {
          await _databaseHelper.updateChat(chat);
        }
      }

      await _loadChatHistory();
      await _loadStatistics();
    } catch (e) {
      debugPrint('Error syncing with Firebase: $e');
    }
  }

  // Search functionality
  void searchChats(String query) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final filteredChats = query.isEmpty 
          ? currentState.chatHistory
          : _filterChats(currentState.chatHistory, query);
      
      emit(currentState.copyWith(
        searchQuery: query,
        filteredChats: filteredChats,
      ));
    }
  }

  List<ChatModel> _filterChats(List<ChatModel> chats, String query) {
    return chats.where((chat) =>
        chat.title.toLowerCase().contains(query.toLowerCase()) ||
        (chat.lastMessage?.toLowerCase().contains(query.toLowerCase()) ?? false)
    ).toList();
  }

  Future<List<MessageModel>> searchMessages(String query, {String? chatId}) async {
    return await _databaseHelper.searchMessages(query, chatId: chatId);
  }

  // Create a new chat
  Future<void> createNewChat({String? firstMessage}) async {
    try {
      if (state is! ChatLoaded) return;
      
      final currentState = state as ChatLoaded;
      
      final newChat = ChatModel(
        title: firstMessage != null
            ? _generateChatTitle(firstMessage)
            : 'New Chat',
      );

      // Save to local database
      await _databaseHelper.insertChat(newChat);

      // Sync to Firebase if online
      if (currentState.isOnline) {
        try {
          await _firebaseService.syncChat(newChat);
        } catch (e) {
          debugPrint('Failed to sync new chat to Firebase: $e');
        }
      }

      // Set as current chat
      await _setCurrentChat(newChat.id);

      // Add to history
      final updatedHistory = [newChat, ...currentState.chatHistory];
      emit(currentState.copyWith(
        chatHistory: updatedHistory,
        filteredChats: currentState.searchQuery.isEmpty 
            ? updatedHistory 
            : _filterChats(updatedHistory, currentState.searchQuery),
      ));

      // Send first message if provided
      if (firstMessage != null) {
        await sendMessage(firstMessage);
      }

      await _loadStatistics();
    } catch (e) {
      emit(ChatError(error: 'Failed to create new chat: $e'));
      debugPrint('Error creating new chat: $e');
    }
  }

  // Set current chat and load messages
  Future<void> _setCurrentChat(String chatId) async {
    try {
      if (state is! ChatLoaded) return;
      
      final currentState = state as ChatLoaded;
      final chat = await _databaseHelper.getChat(chatId);

      if (chat != null) {
        // Cancel previous message stream
        _messageStreamSubscription?.cancel();

        // Load messages from local database
        final localMessages = await _databaseHelper.getMessagesForChat(chatId);

        // Update state with current chat and messages
        emit(currentState.copyWith(
          currentChat: chat,
          messages: localMessages,
        ));

        // If online, also listen to Firebase stream
        if (currentState.isOnline) {
          _messageStreamSubscription = _firebaseService
              .getMessageStream(chatId)
              .listen((firebaseMessages) {
            if (state is ChatLoaded) {
              final state_ = state as ChatLoaded;
              final updatedMessages = List<MessageModel>.from(state_.messages);
              
              // Merge with local messages (avoiding duplicates)
              for (final fbMessage in firebaseMessages) {
                if (!updatedMessages.any((msg) => msg.id == fbMessage.id)) {
                  updatedMessages.add(fbMessage);
                  // Save to local database
                  _databaseHelper.insertMessage(fbMessage);
                }
              }
              updatedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
              
              emit(state_.copyWith(messages: updatedMessages));
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error setting current chat: $e');
    }
  }

  // Switch to an existing chat
  Future<void> switchToChat(String chatId) async {
    await _setCurrentChat(chatId);
  }

  // Pin/Unpin chat
  Future<void> toggleChatPin(String chatId) async {
    try {
      if (state is! ChatLoaded) return;
      
      final currentState = state as ChatLoaded;
      final chat = await _databaseHelper.getChat(chatId);
      
      if (chat != null) {
        final updatedChat = chat.copyWith(isPinned: !chat.isPinned);
        await _databaseHelper.updateChat(updatedChat);

        if (currentState.isOnline) {
          await _firebaseService.syncChat(updatedChat);
        }

        // Update in history
        final updatedHistory = currentState.chatHistory.map((c) => 
            c.id == chatId ? updatedChat : c).toList();

        // Update current chat if it's the same
        final updatedCurrentChat = currentState.currentChat?.id == chatId 
            ? updatedChat 
            : currentState.currentChat;

        emit(currentState.copyWith(
          chatHistory: updatedHistory,
          currentChat: updatedCurrentChat,
          filteredChats: currentState.searchQuery.isEmpty 
              ? updatedHistory 
              : _filterChats(updatedHistory, currentState.searchQuery),
        ));

        await _loadStatistics();
      }
    } catch (e) {
      debugPrint('Error toggling chat pin: $e');
    }
  }

  // Send a message with enhanced retry logic
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;

    // If no current chat, create one
    if (currentState.currentChat == null) {
      await createNewChat(firstMessage: content);
      return;
    }

    final userMessage = MessageModel(
      chatId: currentState.currentChat!.id,
      content: content,
      isUser: true,
      synced: currentState.isOnline,
    );

    // Add user message
    final updatedMessages = [...currentState.messages, userMessage];
    await _databaseHelper.insertMessage(userMessage);

    // Sync to Firebase if online
    if (currentState.isOnline) {
      try {
        await _firebaseService.syncMessage(userMessage);
        await _databaseHelper.markMessageAsSynced(userMessage.id);
      } catch (e) {
        debugPrint('Failed to sync user message: $e');
      }
    }

    emit(currentState.copyWith(messages: updatedMessages));

    // Set loading state
    emit(currentState.copyWith(isLoading: true));

    try {
      String response;

      if (currentState.isOnline) {
        // Use API service when online with exponential backoff
        response = await _sendMessageWithRetry(content);
      } else {
        // Provide offline response
        response = "I'm currently offline. Your message has been saved and I'll respond when connection is restored.";
      }

      final responseMessage = MessageModel(
        chatId: currentState.currentChat!.id,
        content: response,
        isUser: false,
        synced: currentState.isOnline,
      );

      final finalMessages = [...updatedMessages, responseMessage];
      await _databaseHelper.insertMessage(responseMessage);

      // Sync to Firebase if online
      if (currentState.isOnline) {
        try {
          await _firebaseService.syncMessage(responseMessage);
          await _databaseHelper.markMessageAsSynced(responseMessage.id);
        } catch (e) {
          debugPrint('Failed to sync response message: $e');
        }
      }

      // Update chat title if it's the first exchange
      ChatModel? updatedCurrentChat = currentState.currentChat;
      List<ChatModel> updatedHistory = currentState.chatHistory;
      
      if (finalMessages.where((m) => m.isUser).length == 1) {
        updatedCurrentChat = currentState.currentChat!.copyWith(
          title: _generateChatTitle(content),
          updatedAt: DateTime.now(),
        );
        await _databaseHelper.updateChat(updatedCurrentChat);

        if (currentState.isOnline) {
          try {
            await _firebaseService.syncChat(updatedCurrentChat);
          } catch (e) {
            debugPrint('Failed to sync updated chat: $e');
          }
        }

        // Update in history
        updatedHistory = currentState.chatHistory.map((chat) => 
            chat.id == updatedCurrentChat!.id ? updatedCurrentChat : chat).toList();
      }

      emit(currentState.copyWith(
        messages: finalMessages,
        isLoading: false,
        currentChat: updatedCurrentChat,
        chatHistory: updatedHistory,
        filteredChats: currentState.searchQuery.isEmpty 
            ? updatedHistory 
            : _filterChats(updatedHistory, currentState.searchQuery),
      ));
    } catch (e) {
      final errorMessage = MessageModel(
        chatId: currentState.currentChat!.id,
        content: 'Sorry, something went wrong. Please try again later.',
        isUser: false,
        synced: false,
      );
      
      final errorMessages = [...updatedMessages, errorMessage];
      await _databaseHelper.insertMessage(errorMessage);
      
      emit(currentState.copyWith(
        messages: errorMessages,
        isLoading: false,
      ));
      
      debugPrint('Error sending message: $e');
    }

    await _loadStatistics();
  }

  Future<String> _sendMessageWithRetry(String content, {int attempt = 1}) async {
    const maxAttempts = 3;
    const baseDelay = Duration(seconds: 1);

    try {
      return await _apiService.sendMessage(content);
    } catch (e) {
      if (attempt < maxAttempts) {
        final delay = Duration(
          seconds: baseDelay.inSeconds * pow(2, attempt - 1).toInt(),
        );
        await Future.delayed(delay);
        return await _sendMessageWithRetry(content, attempt: attempt + 1);
      } else {
        throw e;
      }
    }
  }

  // Enhanced retry failed messages
  Future<void> retryFailedMessages() async {
    if (state is! ChatLoaded) return;
    
    final currentState = state as ChatLoaded;
    if (!currentState.isOnline || currentState.isRetrying) return;

    emit(currentState.copyWith(isRetrying: true));

    try {
      final failedMessages = await _databaseHelper.getFailedMessages();

      for (final message in failedMessages) {
        if (message.hasMaxRetries) continue;

        try {
          // Find the user message that this bot message was responding to
          final userMessage = currentState.messages
              .where((m) =>
                  m.chatId == message.chatId &&
                  m.isUser &&
                  m.timestamp.isBefore(message.timestamp))
              .lastOrNull;

          if (userMessage != null) {
            final response = await _sendMessageWithRetry(userMessage.content);

            final updatedMessage = message.copyWith(
              content: response,
              synced: true,
            );

            final updatedMessages = currentState.messages.map((m) => 
                m.id == message.id ? updatedMessage : m).toList();

            await _databaseHelper.insertMessage(updatedMessage);
            await _firebaseService.syncMessage(updatedMessage);
            await _databaseHelper.markMessageAsSynced(updatedMessage.id);
            
            emit(currentState.copyWith(messages: updatedMessages));
          }
        } catch (e) {
          await _databaseHelper.incrementMessageRetryCount(message.id);
          debugPrint('Failed to retry message ${message.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error retrying failed messages: $e');
    }

    if (state is ChatLoaded) {
      emit((state as ChatLoaded).copyWith(isRetrying: false));
    }
    await _loadStatistics();
  }

  // Delete a chat
  Future<void> deleteChat(String chatId) async {
    try {
      if (state is! ChatLoaded) return;
      
      final currentState = state as ChatLoaded;
      
      await _databaseHelper.deleteChat(chatId);

      if (currentState.isOnline) {
        try {
          await _firebaseService.deleteChat(chatId);
        } catch (e) {
          debugPrint('Failed to delete chat from Firebase: $e');
        }
      }

      final updatedHistory = currentState.chatHistory
          .where((chat) => chat.id != chatId)
          .toList();

      // If deleting current chat, clear current chat
      ChatModel? updatedCurrentChat = currentState.currentChat;
      List<MessageModel> updatedMessages = currentState.messages;
      
      if (currentState.currentChat?.id == chatId) {
        updatedCurrentChat = null;
        updatedMessages = [];
        _messageStreamSubscription?.cancel();
      }

      emit(currentState.copyWith(
        chatHistory: updatedHistory,
        filteredChats: currentState.searchQuery.isEmpty 
            ? updatedHistory 
            : _filterChats(updatedHistory, currentState.searchQuery),
        currentChat: updatedCurrentChat,
        messages: updatedMessages,
      ));

      await _loadStatistics();
    } catch (e) {
      emit(ChatError(error: 'Failed to delete chat: $e'));
      debugPrint('Error deleting chat: $e');
    }
  }

  // Delete a specific message
  Future<void> deleteMessage(String messageId) async {
    try {
      if (state is! ChatLoaded) return;
      
      final currentState = state as ChatLoaded;
      
      await _databaseHelper.deleteMessage(messageId);

      final updatedMessages = currentState.messages
          .where((msg) => msg.id != messageId)
          .toList();

      emit(currentState.copyWith(messages: updatedMessages));

      await _loadStatistics();
    } catch (e) {
      debugPrint('Error deleting message: $e');
    }
  }

  // Export chat functionality
  String exportChatAsText(String chatId) {
    if (state is! ChatLoaded) return '';
    
    final currentState = state as ChatLoaded;
    final chatMessages = currentState.messages.where((m) => m.chatId == chatId).toList();
    final chat = currentState.chatHistory.firstWhere((c) => c.id == chatId);

    final buffer = StringBuffer();
    buffer.writeln('Chat Export: ${chat.title}');
    buffer.writeln('Created: ${chat.createdAt}');
    buffer.writeln('Last Updated: ${chat.updatedAt}');
    buffer.writeln('${'=' * 50}');

    for (final message in chatMessages) {
      final sender = message.isUser ? 'You' : 'AI';
      buffer.writeln('[$sender] ${message.timestamp}');
      buffer.writeln(message.content);
      buffer.writeln();
    }

    return buffer.toString();
  }

  // Clear all data
  Future<void> clearAllData() async {
    try {
      await _databaseHelper.clearDatabase();
      
      emit(const ChatLoaded(
        chatHistory: [],
        filteredChats: [],
        messages: [],
        currentChat: null,
        statistics: {},
        searchQuery: '',
      ));
    } catch (e) {
      emit(ChatError(error: 'Failed to clear data: $e'));
      debugPrint('Error clearing all data: $e');
    }
  }

  // Database maintenance
  Future<void> cleanupOldMessages({int daysOld = 30}) async {
    try {
      await _databaseHelper.deleteOldMessages(daysOld: daysOld);
      await _loadStatistics();
    } catch (e) {
      debugPrint('Error cleaning up old messages: $e');
    }
  }

  Future<int> getDatabaseSize() async {
    return await _databaseHelper.getDatabaseSize();
  }

  // Generate chat title from first message
  String _generateChatTitle(String firstMessage) {
    // Remove extra whitespace and newlines
    final cleanMessage = firstMessage.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (cleanMessage.length <= 30) {
      return cleanMessage;
    }

    // Try to cut at a word boundary
    final words = cleanMessage.substring(0, 30).split(' ');
    if (words.length > 1) {
      words.removeLast(); // Remove potentially cut word
      return '${words.join(' ')}...';
    }

    return '${cleanMessage.substring(0, 30)}...';
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    _messageStreamSubscription?.cancel();
    _syncTimer?.cancel();
    _retryTimer?.cancel();
    _connectivityService.dispose();
    return super.close();
  }
}