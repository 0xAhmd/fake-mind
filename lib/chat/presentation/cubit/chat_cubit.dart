import 'dart:async';
import 'dart:math';
import 'package:fake_mind/chat/domain/usecases/chat_managment_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../../domain/usecases/message_usecase.dart';
import '../../domain/usecases/sync_usecase.dart';
import '../../data/services/firebase/google_generative_api_service.dart';
import '../../data/services/offline/connectivity_service.dart';
import '../../data/model/message_model.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatManagementUseCase _chatUseCase;
  final MessageUseCase _messageUseCase;
  final SyncUseCase _syncUseCase;
  final GoogleGenerativeApiService _apiService;
  final ConnectivityService _connectivityService;

  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<List<MessageModel>>? _messageStreamSubscription;
  Timer? _syncTimer;

  ChatCubit({
    required ChatManagementUseCase chatUseCase,
    required MessageUseCase messageUseCase,
    required SyncUseCase syncUseCase,
    required GoogleGenerativeApiService apiService,
    required ConnectivityService connectivityService,
  }) : _chatUseCase = chatUseCase,
       _messageUseCase = messageUseCase,
       _syncUseCase = syncUseCase,
       _apiService = apiService,
       _connectivityService = connectivityService,
       super(const ChatInitial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _connectivitySubscription = _connectivityService.connectivityStream
          .listen(_onConnectivityChanged);

      final isOnline = await _connectivityService.hasConnection();
      final chatHistory = await _chatUseCase.getAllChats();
      final statistics = await _getStatistics();

      emit(
        ChatLoaded(
          chatHistory: chatHistory,
          filteredChats: chatHistory,
          statistics: statistics,
          isOnline: isOnline,
        ),
      );

      if (isOnline) {
        await _performSync();
      }

      _startPeriodicSync();
    } catch (e) {
      emit(ChatError(error: 'Failed to initialize: $e'));
      debugPrint('Error initializing ChatCubit: $e');
    }
  }

  void _onConnectivityChanged(bool isOnline) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      emit(currentState.copyWith(isOnline: isOnline));

      if (isOnline && !currentState.isOnline) {
        await _performSync();
        await retryFailedMessages();
      }
    }
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (state is ChatLoaded && (state as ChatLoaded).isOnline) {
        _performSync();
      }
    });
  }

  Future<void> _performSync() async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;
    try {
      await _syncUseCase.syncToFirebase(
        currentState.chatHistory,
        currentState.messages,
      );
      final updatedChats = await _syncUseCase.syncFromFirebase();

      emit(
        currentState.copyWith(
          chatHistory: updatedChats,
          filteredChats:
              currentState.searchQuery.isEmpty
                  ? updatedChats
                  : _chatUseCase.filterChats(
                    updatedChats,
                    currentState.searchQuery,
                  ),
        ),
      );
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  Future<Map<String, dynamic>> _getStatistics() async {
    try {
      // Get statistics from repository through use case
      return await _messageUseCase.getStatistics();
    } catch (e) {
      debugPrint('Error getting statistics: $e');
      return {};
    }
  }

  // FIXED: Load chat history method
  Future<void> loadChatHistory() async {
    try {
      if (state is! ChatLoaded) {
        debugPrint(
          'Cannot load chat history: Invalid state ${state.runtimeType}',
        );
        return;
      }

      final currentState = state as ChatLoaded;

      // Set loading state
      emit(currentState.copyWith(isLoading: true));

      debugPrint('🔄 Loading chat history...');

      // Load chats from repository
      final localChats = await _chatUseCase.getAllChats();
      debugPrint('✅ Loaded ${localChats.length} chats from local database');

      // Apply current search filter
      final filteredChats =
          currentState.searchQuery.isEmpty
              ? localChats
              : _chatUseCase.filterChats(localChats, currentState.searchQuery);

      debugPrint('📊 Filtered to ${filteredChats.length} chats');

      // Update statistics
      final statistics = await _getStatistics();

      // Update state with new data
      emit(
        currentState.copyWith(
          chatHistory: localChats,
          filteredChats: filteredChats,
          statistics: statistics,
          isLoading: false,
        ),
      );

      debugPrint('✅ Chat history loaded successfully');

      // Perform sync if online
      if (currentState.isOnline) {
        debugPrint('🔄 Performing sync after load...');
        await _performSync();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading chat history: $e');
      debugPrint('Stack trace: $stackTrace');

      if (state is ChatLoaded) {
        emit((state as ChatLoaded).copyWith(isLoading: false));
      }
      // Don't emit error state for loading failures, just log
    }
  }

  // Chat Management Methods
  Future<void> createNewChat({String? firstMessage}) async {
    if (state is! ChatLoaded) return;

    try {
      final _ = state as ChatLoaded;
      await _chatUseCase.createChat(firstMessage: firstMessage);

      await loadChatHistory(); // Use the fixed loadChatHistory method

      if (firstMessage != null) {
        final updatedHistory = await _chatUseCase.getAllChats();
        final newChat = updatedHistory.first;
        await switchToChat(newChat.id);
        await sendMessage(firstMessage);
      }
    } catch (e) {
      emit(ChatError(error: 'Failed to create chat: $e'));
      debugPrint('Error creating new chat: $e');
    }
  }

  Future<void> createNewChatWithName(String chatName) async {
    if (state is! ChatLoaded) return;

    try {
      final _ = state as ChatLoaded;
      await _chatUseCase.createChat(title: chatName.trim());

      await loadChatHistory(); // Use the fixed loadChatHistory method

      final updatedHistory = await _chatUseCase.getAllChats();
      final newChat = updatedHistory.first;

      if (state is ChatLoaded) {
        emit((state as ChatLoaded).copyWith(currentChat: newChat));
      }
    } catch (e) {
      emit(ChatError(error: 'Failed to create chat: $e'));
      debugPrint('Error creating new chat with name: $e');
    }
  }

  Future<void> renameChat(String chatId, String newName) async {
    if (state is! ChatLoaded) return;

    try {
      final currentState = state as ChatLoaded;
      await _chatUseCase.renameChat(chatId, newName);

      await loadChatHistory(); // Use the fixed loadChatHistory method

      // Update current chat if it's the same one
      if (currentState.currentChat?.id == chatId) {
        final updatedChat = await _chatUseCase.getChat(chatId);
        if (state is ChatLoaded && updatedChat != null) {
          emit((state as ChatLoaded).copyWith(currentChat: updatedChat));
        }
      }

      if (currentState.isOnline) {
        final updatedChat = await _chatUseCase.getChat(chatId);
        if (updatedChat != null) {
          await _syncUseCase.syncChat(updatedChat);
        }
      }
    } catch (e) {
      emit(ChatError(error: 'Failed to rename chat: $e'));
      debugPrint('Error renaming chat: $e');
    }
  }

  Future<void> toggleChatPin(String chatId) async {
    if (state is! ChatLoaded) return;

    try {
      final currentState = state as ChatLoaded;
      await _chatUseCase.togglePin(chatId);

      await loadChatHistory(); // Use the fixed loadChatHistory method

      // Update current chat if it's the same one
      if (currentState.currentChat?.id == chatId) {
        final updatedChat = await _chatUseCase.getChat(chatId);
        if (state is ChatLoaded && updatedChat != null) {
          emit((state as ChatLoaded).copyWith(currentChat: updatedChat));
        }
      }

      if (currentState.isOnline) {
        final updatedChat = await _chatUseCase.getChat(chatId);
        if (updatedChat != null) {
          await _syncUseCase.syncChat(updatedChat);
        }
      }
    } catch (e) {
      debugPrint('Error toggling chat pin: $e');
    }
  }

  Future<void> deleteChat(String chatId) async {
    if (state is! ChatLoaded) return;

    try {
      final currentState = state as ChatLoaded;
      await _chatUseCase.deleteChat(chatId);

      await loadChatHistory(); // Use the fixed loadChatHistory method

      // Clear current chat if it was deleted
      if (currentState.currentChat?.id == chatId) {
        _messageStreamSubscription?.cancel();
        if (state is ChatLoaded) {
          emit((state as ChatLoaded).copyWith(currentChat: null, messages: []));
        }
      }
    } catch (e) {
      emit(ChatError(error: 'Failed to delete chat: $e'));
      debugPrint('Error deleting chat: $e');
    }
  }

  Future<void> switchToChat(String chatId) async {
    if (state is! ChatLoaded) return;

    try {
      final currentState = state as ChatLoaded;
      final chat = await _chatUseCase.getChat(chatId);

      if (chat != null) {
        _messageStreamSubscription?.cancel();

        final messages = await _messageUseCase.getMessagesForChat(chatId);
        emit(currentState.copyWith(currentChat: chat, messages: messages));

        if (currentState.isOnline) {
          _messageStreamSubscription = _syncUseCase
              .getMessageStream(chatId)
              .listen(
                (firebaseMessages) => _handleFirebaseMessages(firebaseMessages),
              );
        }
      }
    } catch (e) {
      debugPrint('Error switching to chat: $e');
    }
  }

  void _handleFirebaseMessages(List<MessageModel> firebaseMessages) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final updatedMessages = List<MessageModel>.from(currentState.messages);

      for (final fbMessage in firebaseMessages) {
        if (!updatedMessages.any((msg) => msg.id == fbMessage.id)) {
          updatedMessages.add(fbMessage);
          _messageUseCase.saveMessage(fbMessage);
        }
      }

      updatedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      emit(currentState.copyWith(messages: updatedMessages));
    }
  }

  // Message Methods
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;

    if (currentState.currentChat == null) {
      await createNewChat(firstMessage: content);
      return;
    }

    final userMessage = _messageUseCase.createUserMessage(
      currentState.currentChat!.id,
      content,
      currentState.isOnline,
    );

    // Add user message immediately
    final updatedMessages = [...currentState.messages, userMessage];
    emit(currentState.copyWith(messages: updatedMessages));

    await _messageUseCase.saveMessage(userMessage);

    if (currentState.isOnline) {
      try {
        await _syncUseCase.syncMessage(userMessage);
        await _messageUseCase.markAsSynced(userMessage.id);
      } catch (e) {
        debugPrint('Failed to sync user message: $e');
      }
    }

    // Set loading state
    emit(currentState.copyWith(messages: updatedMessages, isLoading: true));

    try {
      final response =
          currentState.isOnline
              ? await _sendMessageWithRetry(content)
              : "I'm currently offline. Your message has been saved and I'll respond when connection is restored.";

      final responseMessage = _messageUseCase.createBotMessage(
        currentState.currentChat!.id,
        response,
        currentState.isOnline,
      );

      final finalMessages = [...updatedMessages, responseMessage];
      await _messageUseCase.saveMessage(responseMessage);

      if (currentState.isOnline) {
        try {
          await _syncUseCase.syncMessage(responseMessage);
          await _messageUseCase.markAsSynced(responseMessage.id);
        } catch (e) {
          debugPrint('Failed to sync response message: $e');
        }
      }

      emit(currentState.copyWith(messages: finalMessages, isLoading: false));
    } catch (e) {
      final errorMessage = _messageUseCase.createBotMessage(
        currentState.currentChat!.id,
        'Sorry, something went wrong. Please try again later.',
        false,
      );

      final errorMessages = [...updatedMessages, errorMessage];
      await _messageUseCase.saveMessage(errorMessage);

      emit(currentState.copyWith(messages: errorMessages, isLoading: false));
      debugPrint('Error sending message: $e');
    }
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

  Future<void> retryFailedMessages() async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;
    if (!currentState.isOnline || currentState.isRetrying) return;

    emit(currentState.copyWith(isRetrying: true));

    try {
      final _ = await _messageUseCase.getFailedMessages();
      // Implementation for retry logic...
    } catch (e) {
      debugPrint('Error retrying failed messages: $e');
    }

    if (state is ChatLoaded) {
      emit((state as ChatLoaded).copyWith(isRetrying: false));
    }
  }

  // Search Methods
  void searchChats(String query) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final filteredChats = _chatUseCase.filterChats(
        currentState.chatHistory,
        query,
      );
      emit(
        currentState.copyWith(searchQuery: query, filteredChats: filteredChats),
      );
    }
  }

  Future<List<MessageModel>> searchMessages(String query, {String? chatId}) =>
      _messageUseCase.searchMessages(query, chatId: chatId);

  // Export Methods
  String exportChatAsText(String chatId) {
    if (state is! ChatLoaded) return '';

    final currentState = state as ChatLoaded;
    final chatMessages =
        currentState.messages.where((m) => m.chatId == chatId).toList();
    final chat = currentState.chatHistory.firstWhere((c) => c.id == chatId);

    return _messageUseCase.exportChatAsText(chatMessages, chat);
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    _messageStreamSubscription?.cancel();
    _syncTimer?.cancel();
    _connectivityService.dispose();
    return super.close();
  }
}
