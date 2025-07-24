import 'dart:async';
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

  // Chat history
  final List<ChatModel> _chatHistory = [];

  // Stream subscriptions
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<List<MessageModel>>? _messageStreamSubscription;

  // GETTERS
  ChatModel? get currentChat => _currentChat;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  List<ChatModel> get chatHistory => _chatHistory;

  ChatProvider() {
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    // Initialize Firebase Auth
    await _firebaseService.signInAnonymously();

    // Initialize connectivity monitoring
    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      _onConnectivityChanged,
    );
    _isOnline = await _connectivityService.hasConnection();

    // Load chat history
    await _loadChatHistory();

    // Sync data if online
    if (_isOnline) {
      await _syncDataWithFirebase();
    }

    notifyListeners();
  }

  void _onConnectivityChanged(bool isOnline) async {
    _isOnline = isOnline;
    notifyListeners();

    if (isOnline) {
      await _syncDataWithFirebase();
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final localChats = await _databaseHelper.getAllChats();
      _chatHistory.clear();
      _chatHistory.addAll(localChats);
      notifyListeners();
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  Future<void> _syncDataWithFirebase() async {
    if (!_isOnline) return;

    try {
      // Get unsynced messages
      final unsyncedMessages = await _databaseHelper.getUnsyncedMessages();

      // Sync unsynced data
      await _firebaseService.syncUnsyncedData(_chatHistory, unsyncedMessages);

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
        }
      }

      await _loadChatHistory();
    } catch (e) {
      print('Error syncing with Firebase: $e');
    }
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
        await _firebaseService.syncChat(newChat);
      }

      // Set as current chat
      await _setCurrentChat(newChat.id);

      // Add to history
      _chatHistory.insert(0, newChat);
      notifyListeners();

      // Send first message if provided
      if (firstMessage != null) {
        await sendMessage(firstMessage);
      }
    } catch (e) {
      print('Error creating new chat: $e');
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
      print('Error setting current chat: $e');
    }
  }

  // Switch to an existing chat
  Future<void> switchToChat(String chatId) async {
    await _setCurrentChat(chatId);
  }

  // Send a message
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
      await _firebaseService.syncMessage(userMessage);
      await _databaseHelper.markMessageAsSynced(userMessage.id);
    }

    notifyListeners();

    // Set loading state
    _isLoading = true;
    notifyListeners();

    try {
      String response;

      if (_isOnline) {
        // Use API service when online
        response = await _apiService.sendMessage(content);
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
        await _firebaseService.syncMessage(responseMessage);
        await _databaseHelper.markMessageAsSynced(responseMessage.id);
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
          await _firebaseService.syncChat(updatedChat);
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
        content: 'Sorry, something went wrong: $e',
        isUser: false,
        synced: false,
      );
      _messages.add(errorMessage);
      await _databaseHelper.insertMessage(errorMessage);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Delete a chat
  Future<void> deleteChat(String chatId) async {
    try {
      await _databaseHelper.deleteChat(chatId);

      if (_isOnline) {
        await _firebaseService.deleteChat(chatId);
      }

      _chatHistory.removeWhere((chat) => chat.id == chatId);

      // If deleting current chat, clear current chat
      if (_currentChat?.id == chatId) {
        _currentChat = null;
        _messages.clear();
        _messageStreamSubscription?.cancel();
      }

      notifyListeners();
    } catch (e) {
      print('Error deleting chat: $e');
    }
  }

  // Generate chat title from first message
  String _generateChatTitle(String firstMessage) {
    if (firstMessage.length <= 30) {
      return firstMessage;
    }
    return '${firstMessage.substring(0, 30)}...';
  }

  // Retry failed messages when back online
  Future<void> retryFailedMessages() async {
    if (!_isOnline) return;

    final unsyncedMessages =
        _messages.where((msg) => !msg.synced && !msg.isUser).toList();

    for (final message in unsyncedMessages) {
      try {
        // Retry API call for bot messages that failed
        final response = await _apiService.sendMessage(
          _messages
              .where((m) => m.timestamp.isBefore(message.timestamp) && m.isUser)
              .last
              .content,
        );

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
      } catch (e) {
        print('Error retrying message: $e');
      }
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _messageStreamSubscription?.cancel();
    _connectivityService.dispose();
    super.dispose();
  }
}
