import 'dart:async';
import 'dart:math';
import 'package:fake_mind/chat/data/db_helper.dart';
import 'package:fake_mind/chat/data/services/firebase/firebase_service.dart';
import 'package:fake_mind/chat/data/services/firebase/google_generative_api_service.dart';
import 'package:fake_mind/chat/data/services/offline/connectivity_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../data/model/message_model.dart';
import '../data/model/chat_model.dart';

class ChatProvider with ChangeNotifier {
  final _apiService = GoogleGenerativeApiService(
    apiKey: dotenv.env['API_KEY'] ?? '',
  );
  final _databaseHelper = DatabaseHelper.instance;
  final _firebaseService = FirebaseService();
  final _connectivityService = ConnectivityService();

  // Current chat state
  ChatModel? _currentChat;
  final List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isOnline = false;
  bool _isRetrying = false;

  // Chat history
  final List<ChatModel> _chatHistory = [];

  // Search
  String _searchQuery = '';
  List<ChatModel> _filteredChats = [];

  // Statistics
  Map<String, dynamic> _statistics = {};

  // Stream subscriptions
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<List<MessageModel>>? _messageStreamSubscription;
  Timer? _syncTimer;
  Timer? _retryTimer;

  // GETTERS
  ChatModel? get currentChat => _currentChat;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  bool get isRetrying => _isRetrying;
  List<ChatModel> get chatHistory =>
      _searchQuery.isEmpty ? _chatHistory : _filteredChats;
  String get searchQuery => _searchQuery;
  Map<String, dynamic> get statistics => _statistics;

  ChatProvider() {
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    try {
      // Initialize Firebase Auth
      await _firebaseService.signInAnonymously();

      // Initialize connectivity monitoring
      _connectivitySubscription = _connectivityService.connectivityStream
          .listen(_onConnectivityChanged);
      _isOnline = await _connectivityService.hasConnection();

      // Load chat history and statistics
      await _loadChatHistory();
      await _loadStatistics();

      // Sync data if online
      if (_isOnline) {
        await _syncDataWithFirebase();
      }

      // Set up periodic sync
      _startPeriodicSync();

      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing ChatProvider: $e');
    }
  }

  void _onConnectivityChanged(bool isOnline) async {
    final wasOffline = !_isOnline;
    _isOnline = isOnline;
    notifyListeners();

    if (isOnline && wasOffline) {
      // Just came back online
      await _syncDataWithFirebase();
      await retryFailedMessages();
    }
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_isOnline) {
        _syncDataWithFirebase();
      }
    });
  }

  Future<void> _loadChatHistory() async {
    try {
      final localChats = await _databaseHelper.getAllChats();
      _chatHistory.clear();
      _chatHistory.addAll(localChats);
      _updateFilteredChats();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
  }

  Future<void> _loadStatistics() async {
    try {
      _statistics = await _databaseHelper.getChatStatistics();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  Future<void> _syncDataWithFirebase() async {
    if (!_isOnline) return;

    try {
      // Get unsynced messages
      final unsyncedMessages = await _databaseHelper.getUnsyncedMessages();

      // Get unsynced chats (those created offline)
      final unsyncedChats =
          _chatHistory
              .where(
                (chat) =>
                    !unsyncedMessages.any(
                      (msg) => msg.chatId == chat.id && msg.synced,
                    ),
              )
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
    _searchQuery = query;
    _updateFilteredChats();
    notifyListeners();
  }

  void _updateFilteredChats() {
    if (_searchQuery.isEmpty) {
      _filteredChats.clear();
    } else {
      _filteredChats =
          _chatHistory
              .where(
                (chat) =>
                    chat.title.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    (chat.lastMessage?.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ??
                        false),
              )
              .toList();
    }
  }

  Future<List<MessageModel>> searchMessages(
    String query, {
    String? chatId,
  }) async {
    return await _databaseHelper.searchMessages(query, chatId: chatId);
  }

  // Create a new chat
  Future<void> createNewChat({String? firstMessage}) async {
    try {
      final newChat = ChatModel(
        title:
            firstMessage != null
                ? _generateChatTitle(firstMessage)
                : 'New Chat',
      );

      // Save to local database
      await _databaseHelper.insertChat(newChat);

      // Sync to Firebase if online
      if (_isOnline) {
        try {
          await _firebaseService.syncChat(newChat);
        } catch (e) {
          debugPrint('Failed to sync new chat to Firebase: $e');
        }
      }

      // Set as current chat
      await _setCurrentChat(newChat.id);

      // Add to history
      _chatHistory.insert(0, newChat);
      _updateFilteredChats();
      notifyListeners();

      // Send first message if provided
      if (firstMessage != null) {
        await sendMessage(firstMessage);
      }

      await _loadStatistics();
    } catch (e) {
      debugPrint('Error creating new chat: $e');
      throw Exception('Failed to create new chat');
    }
  }

  // Set current chat and load messages
  Future<void> _setCurrentChat(String chatId) async {
    try {
      _currentChat = await _databaseHelper.getChat(chatId);

      if (_currentChat != null) {
        // Cancel previous message stream
        _messageStreamSubscription?.cancel();

        // Load messages from local database
        final localMessages = await _databaseHelper.getMessagesForChat(chatId);
        _messages.clear();
        _messages.addAll(localMessages);

        // If online, also listen to Firebase stream
        if (_isOnline) {
          _messageStreamSubscription = _firebaseService
              .getMessageStream(chatId)
              .listen((firebaseMessages) {
                // Merge with local messages (avoiding duplicates)
                for (final fbMessage in firebaseMessages) {
                  if (!_messages.any((msg) => msg.id == fbMessage.id)) {
                    _messages.add(fbMessage);
                    // Save to local database
                    _databaseHelper.insertMessage(fbMessage);
                  }
                }
                _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
                notifyListeners();
              });
        }

        notifyListeners();
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
      final chat = await _databaseHelper.getChat(chatId);
      if (chat != null) {
        final updatedChat = chat.copyWith(isPinned: !chat.isPinned);
        await _databaseHelper.updateChat(updatedChat);

        if (_isOnline) {
          await _firebaseService.syncChat(updatedChat);
        }

        // Update in history
        final index = _chatHistory.indexWhere((c) => c.id == chatId);
        if (index != -1) {
          _chatHistory[index] = updatedChat;
        }

        // Update current chat if it's the same
        if (_currentChat?.id == chatId) {
          _currentChat = updatedChat;
        }

        await _loadChatHistory(); // Reload to update sorting
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling chat pin: $e');
    }
  }

  // Send a message with enhanced retry logic
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // If no current chat, create one
    if (_currentChat == null) {
      await createNewChat(firstMessage: content);
      return;
    }

    final userMessage = MessageModel(
      chatId: _currentChat!.id,
      content: content,
      isUser: true,
      synced: _isOnline,
    );

    // Add user message
    _messages.add(userMessage);
    await _databaseHelper.insertMessage(userMessage);

    // Sync to Firebase if online
    if (_isOnline) {
      try {
        await _firebaseService.syncMessage(userMessage);
        await _databaseHelper.markMessageAsSynced(userMessage.id);
      } catch (e) {
        debugPrint('Failed to sync user message: $e');
      }
    }

    notifyListeners();

    // Set loading state
    _isLoading = true;
    notifyListeners();

    try {
      String response;

      if (_isOnline) {
        // Use API service when online with exponential backoff
        response = await _sendMessageWithRetry(content);
      } else {
        // Provide offline response
        response =
            "I'm currently offline. Your message has been saved and I'll respond when connection is restored.";
      }

      final responseMessage = MessageModel(
        chatId: _currentChat!.id,
        content: response,
        isUser: false,
        synced: _isOnline,
      );

      _messages.add(responseMessage);
      await _databaseHelper.insertMessage(responseMessage);

      // Sync to Firebase if online
      if (_isOnline) {
        try {
          await _firebaseService.syncMessage(responseMessage);
          await _databaseHelper.markMessageAsSynced(responseMessage.id);
        } catch (e) {
          debugPrint('Failed to sync response message: $e');
        }
      }

      // Update chat title if it's the first exchange
      if (_messages.where((m) => m.isUser).length == 1) {
        final updatedChat = _currentChat!.copyWith(
          title: _generateChatTitle(content),
          updatedAt: DateTime.now(),
        );
        _currentChat = updatedChat;
        await _databaseHelper.updateChat(updatedChat);

        if (_isOnline) {
          try {
            await _firebaseService.syncChat(updatedChat);
          } catch (e) {
            debugPrint('Failed to sync updated chat: $e');
          }
        }

        // Update in history
        final index = _chatHistory.indexWhere(
          (chat) => chat.id == updatedChat.id,
        );
        if (index != -1) {
          _chatHistory[index] = updatedChat;
        }
      }
    } catch (e) {
      final errorMessage = MessageModel(
        chatId: _currentChat!.id,
        content: 'Sorry, something went wrong. Please try again later.',
        isUser: false,
        synced: false,
      );
      _messages.add(errorMessage);
      await _databaseHelper.insertMessage(errorMessage);
      debugPrint('Error sending message: $e');
    }

    _isLoading = false;
    await _loadStatistics();
    notifyListeners();
  }

  Future<String> _sendMessageWithRetry(
    String content, {
    int attempt = 1,
  }) async {
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
    if (!_isOnline || _isRetrying) return;

    _isRetrying = true;
    notifyListeners();

    try {
      final failedMessages = await _databaseHelper.getFailedMessages();

      for (final message in failedMessages) {
        if (message.hasMaxRetries) continue;

        try {
          // Find the user message that this bot message was responding to
          final userMessage =
              _messages
                  .where(
                    (m) =>
                        m.chatId == message.chatId &&
                        m.isUser &&
                        m.timestamp.isBefore(message.timestamp),
                  )
                  .lastOrNull;

          if (userMessage != null) {
            final response = await _sendMessageWithRetry(userMessage.content);

            final updatedMessage = message.copyWith(
              content: response,
              synced: true,
            );

            final index = _messages.indexWhere((m) => m.id == message.id);
            if (index != -1) {
              _messages[index] = updatedMessage;
            }

            await _databaseHelper.insertMessage(updatedMessage);
            await _firebaseService.syncMessage(updatedMessage);
            await _databaseHelper.markMessageAsSynced(updatedMessage.id);
          }
        } catch (e) {
          await _databaseHelper.incrementMessageRetryCount(message.id);
          debugPrint('Failed to retry message ${message.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error retrying failed messages: $e');
    }

    _isRetrying = false;
    await _loadStatistics();
    notifyListeners();
  }

  // Delete a chat
  Future<void> deleteChat(String chatId) async {
    try {
      await _databaseHelper.deleteChat(chatId);

      if (_isOnline) {
        try {
          await _firebaseService.deleteChat(chatId);
        } catch (e) {
          debugPrint('Failed to delete chat from Firebase: $e');
        }
      }

      _chatHistory.removeWhere((chat) => chat.id == chatId);
      _updateFilteredChats();

      // If deleting current chat, clear current chat
      if (_currentChat?.id == chatId) {
        _currentChat = null;
        _messages.clear();
        _messageStreamSubscription?.cancel();
      }

      await _loadStatistics();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting chat: $e');
      throw Exception('Failed to delete chat');
    }
  }

  // Delete a specific message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _databaseHelper.deleteMessage(messageId);

      _messages.removeWhere((msg) => msg.id == messageId);

      if (_isOnline) {
        // Note: Implement Firebase message deletion if needed
      }

      await _loadStatistics();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting message: $e');
    }
  }

  // Export chat functionality
  String exportChatAsText(String chatId) {
    final chatMessages = _messages.where((m) => m.chatId == chatId).toList();
    final chat = _chatHistory.firstWhere((c) => c.id == chatId);

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
      _chatHistory.clear();
      _filteredChats.clear();
      _messages.clear();
      _currentChat = null;
      _statistics.clear();
      _searchQuery = '';

      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing all data: $e');
      throw Exception('Failed to clear data');
    }
  }

  // Database maintenance
  Future<void> cleanupOldMessages({int daysOld = 30}) async {
    try {
      await _databaseHelper.deleteOldMessages(daysOld: daysOld);
      await _loadStatistics();
      notifyListeners();
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
  void dispose() {
    _connectivitySubscription?.cancel();
    _messageStreamSubscription?.cancel();
    _syncTimer?.cancel();
    _retryTimer?.cancel();
    _connectivityService.dispose();
    super.dispose();
  }
}
