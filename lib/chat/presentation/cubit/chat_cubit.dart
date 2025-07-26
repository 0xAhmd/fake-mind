import 'dart:async';
import 'dart:math';
import 'package:fake_mind/chat/domain/repo/chat_repo.dart';
import 'package:fake_mind/chat/domain/usecases/chat_managment_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../../domain/usecases/message_usecase.dart';
import '../../domain/usecases/sync_usecase.dart';
import '../../data/services/firebase/google_generative_api_service.dart';
import '../../data/services/offline/connectivity_service.dart';
import '../../data/services/firebase/firebase_service.dart';
import '../../data/model/message_model.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatManagementUseCase _chatUseCase;
  final MessageUseCase _messageUseCase;
  final SyncUseCase _syncUseCase;
  final GoogleGenerativeApiService _apiService;
  final ConnectivityService _connectivityService;
  final FirebaseService _firebaseService; // Add this
  final ChatRepository chatRepository;

  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<List<MessageModel>>? _messageStreamSubscription;
  Timer? _syncTimer;
  bool _isAuthenticationComplete = false; // Track auth status

  ChatCubit({
    required this.chatRepository,
    required ChatManagementUseCase chatUseCase,
    required MessageUseCase messageUseCase,
    required SyncUseCase syncUseCase,
    required GoogleGenerativeApiService apiService,
    required ConnectivityService connectivityService,
    required FirebaseService firebaseService, // Add this parameter
  }) : _chatUseCase = chatUseCase,
       _messageUseCase = messageUseCase,
       _syncUseCase = syncUseCase,
       _apiService = apiService,
       _connectivityService = connectivityService,
       _firebaseService = firebaseService, // Initialize this
       super(const ChatInitial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // First, check connectivity
      final isOnline = await _connectivityService.hasConnection();

      // Load local data first (this should always work)
      final chatHistory = await _chatUseCase.getAllChats();
      final statistics = await _getStatistics();

      // Set up connectivity listener
      _connectivitySubscription = _connectivityService.connectivityStream
          .listen(_onConnectivityChanged);

      // Emit initial state with local data
      emit(
        ChatLoaded(
          chatHistory: chatHistory,
          filteredChats: chatHistory,
          statistics: statistics,
          isOnline: isOnline,
        ),
      );

      // If online, attempt authentication and sync
      if (isOnline) {
        await _authenticateAndSync();
      }

      // Start periodic sync timer (but it will only work when authenticated)
      _startPeriodicSync();
    } catch (e) {
      emit(ChatError(error: 'Failed to initialize: $e'));
      debugPrint('Error initializing ChatCubit: $e');
    }
  }

  /// Handle authentication and initial sync
  Future<void> _authenticateAndSync() async {
    try {
      debugPrint('🔐 Starting authentication process...');

      // Attempt anonymous sign-in
      final _ = await _firebaseService.signInAnonymously();

      if (_firebaseService.isAuthenticated) {
        _isAuthenticationComplete = true;
        debugPrint('✅ Authentication completed successfully');

        // Now perform sync
        await _performSync();
        await retryFailedMessages();
      } else {
        debugPrint('❌ Authentication failed');
        _isAuthenticationComplete = false;
      }
    } catch (e) {
      debugPrint('❌ Authentication error: $e');
      _isAuthenticationComplete = false;
      // Don't emit error state - app should still work offline
    }
  }

  void _onConnectivityChanged(bool isOnline) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      emit(currentState.copyWith(isOnline: isOnline));

      if (isOnline && !currentState.isOnline) {
        // Connection restored - authenticate and sync
        await _authenticateAndSync();
      } else if (!isOnline) {
        // Connection lost - reset auth status
        _isAuthenticationComplete = false;
      }
    }
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (state is ChatLoaded &&
          (state as ChatLoaded).isOnline &&
          _isAuthenticationComplete) {
        _performSync();
      }
    });
  }

  Future<void> _performSync() async {
    if (state is! ChatLoaded) return;

    // Check if we're authenticated before attempting sync
    if (!_isAuthenticationComplete || !_firebaseService.isAuthenticated) {
      debugPrint('⏳ Skipping sync - authentication not complete');
      return;
    }

    final currentState = state as ChatLoaded;
    try {
      debugPrint('🔄 Starting sync process...');

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

      debugPrint('✅ Sync completed successfully');
    } catch (e) {
      debugPrint('❌ Sync error: $e');

      // If auth failed, reset auth status
      if (e.toString().contains('not authenticated')) {
        _isAuthenticationComplete = false;
      }
    }
  }

  Future<Map<String, dynamic>> _getStatistics() async {
    try {
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

      // Perform sync if online AND authenticated
      if (currentState.isOnline && _isAuthenticationComplete) {
        debugPrint('🔄 Performing sync after load...');
        await _performSync();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading chat history: $e');
      debugPrint('Stack trace: $stackTrace');

      if (state is ChatLoaded) {
        emit((state as ChatLoaded).copyWith(isLoading: false));
      }
    }
  }

  // Chat Management Methods
  Future<void> createNewChat({String? firstMessage}) async {
    if (state is! ChatLoaded) return;

    try {
      final _ = state as ChatLoaded;
      await _chatUseCase.createChat(firstMessage: firstMessage);

      await loadChatHistory();

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

      await loadChatHistory();

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

  // Fixed renameChat method in ChatCubit
  Future<void> renameChat(String chatId, String newName) async {
    if (state is! ChatLoaded) {
      debugPrint('❌ Cannot rename chat: Invalid state');
      return;
    }

    if (newName.trim().isEmpty) {
      debugPrint('❌ Cannot rename chat: Empty name');
      emit(const ChatError(error: 'Chat name cannot be empty'));
      return;
    }

    try {
      final currentState = state as ChatLoaded;
      debugPrint('🏷️ Starting chat rename: $chatId -> $newName');

      // Set loading state
      emit(currentState.copyWith(isLoading: true));

      // Perform the rename operation
      await _chatUseCase.renameChat(chatId, newName.trim());
      debugPrint('✅ Chat renamed successfully in use case');

      // Reload chat history to get updated data
      await loadChatHistory();
      debugPrint('✅ Chat history reloaded after rename');

      // Update current chat if it's the same one being renamed
      if (currentState.currentChat?.id == chatId) {
        debugPrint('🔄 Updating current chat reference');
        final updatedChat = await _chatUseCase.getChat(chatId);
        if (state is ChatLoaded && updatedChat != null) {
          emit(
            (state as ChatLoaded).copyWith(
              currentChat: updatedChat,
              isLoading: false,
            ),
          );
          debugPrint('✅ Current chat reference updated');
        }
      } else {
        // Just clear loading state if we're not updating current chat
        if (state is ChatLoaded) {
          emit((state as ChatLoaded).copyWith(isLoading: false));
        }
      }

      // Sync to Firebase if online AND authenticated
      if (currentState.isOnline && _isAuthenticationComplete) {
        try {
          debugPrint('🔄 Syncing renamed chat to Firebase');
          final updatedChat = await _chatUseCase.getChat(chatId);
          if (updatedChat != null) {
            await _syncUseCase.syncChat(updatedChat);
            debugPrint('✅ Chat synced to Firebase successfully');
          }
        } catch (syncError) {
          debugPrint(
            '⚠️ Failed to sync to Firebase, but local rename succeeded: $syncError',
          );
          // Don't emit error state since local operation succeeded
        }
      }

      debugPrint('✅ Chat rename operation completed successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error renaming chat: $e');
      debugPrint('Stack trace: $stackTrace');

      // Clear loading state and emit error
      if (state is ChatLoaded) {
        emit((state as ChatLoaded).copyWith(isLoading: false));
      }
      emit(ChatError(error: 'Failed to rename chat: ${e.toString()}'));
    }
  }

  Future<void> toggleChatPin(String chatId) async {
    if (state is! ChatLoaded) return;

    try {
      final currentState = state as ChatLoaded;
      await _chatUseCase.togglePin(chatId);

      await loadChatHistory();

      // Update current chat if it's the same one
      if (currentState.currentChat?.id == chatId) {
        final updatedChat = await _chatUseCase.getChat(chatId);
        if (state is ChatLoaded && updatedChat != null) {
          emit((state as ChatLoaded).copyWith(currentChat: updatedChat));
        }
      }

      // Only sync if authenticated
      if (currentState.isOnline && _isAuthenticationComplete) {
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
      debugPrint('🗑️ Starting chat deletion: $chatId');

      // Set loading state
      emit(currentState.copyWith(isLoading: true));

      // Delete from local database first
      debugPrint('🗑️ Deleting chat from local database...');
      await _chatUseCase.deleteChat(chatId);
      debugPrint('✅ Chat deleted from local database');

      // Delete from Firebase if authenticated
      if (currentState.isOnline && _isAuthenticationComplete) {
        try {
          debugPrint('🗑️ Deleting chat from Firebase...');
          await _firebaseService.deleteChat(chatId);
          debugPrint('✅ Chat deleted from Firebase');
        } catch (firebaseError) {
          debugPrint('⚠️ Failed to delete from Firebase: $firebaseError');
          // Don't fail the operation if local deletion succeeded
        }
      }

      // Reload chat history
      await loadChatHistory();

      // Clear current chat if it was deleted
      if (currentState.currentChat?.id == chatId) {
        debugPrint('🔄 Clearing current chat reference');
        _messageStreamSubscription?.cancel();
        if (state is ChatLoaded) {
          emit(
            (state as ChatLoaded).copyWith(
              currentChat: null,
              messages: [],
              isLoading: false,
            ),
          );
        }
      } else {
        // Just clear loading state
        if (state is ChatLoaded) {
          emit((state as ChatLoaded).copyWith(isLoading: false));
        }
      }

      debugPrint('✅ Chat deletion completed successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error deleting chat: $e');
      debugPrint('Stack trace: $stackTrace');

      // Clear loading state and emit error
      if (state is ChatLoaded) {
        emit((state as ChatLoaded).copyWith(isLoading: false));
      }
      emit(ChatError(error: 'Failed to delete chat: ${e.toString()}'));
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

        // Only set up Firebase stream if authenticated
        if (currentState.isOnline && _isAuthenticationComplete) {
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
      currentState.isOnline && _isAuthenticationComplete,
    );

    // Add user message immediately
    final updatedMessages = [...currentState.messages, userMessage];
    emit(currentState.copyWith(messages: updatedMessages));

    await _messageUseCase.saveMessage(userMessage);

    // Only sync if authenticated
    if (currentState.isOnline && _isAuthenticationComplete) {
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
        currentState.isOnline && _isAuthenticationComplete,
      );

      final finalMessages = [...updatedMessages, responseMessage];
      await _messageUseCase.saveMessage(responseMessage);

      // Only sync if authenticated
      if (currentState.isOnline && _isAuthenticationComplete) {
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

  /// Retry/regenerate a specific bot message
  Future<void> retryMessage(String messageId) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;
    if (!currentState.isOnline || !_isAuthenticationComplete) {
      _showOfflineMessage();
      return;
    }

    try {
      debugPrint('🔄 Retrying message: $messageId');

      // Get the message to retry
      final messageToRetry = await _messageUseCase.getMessage(messageId);
      if (messageToRetry == null || messageToRetry.isUser) {
        debugPrint('❌ Cannot retry: message not found or is user message');
        return;
      }

      // Get the previous user message to regenerate response
      final previousUserMessage = await _messageUseCase.getPreviousUserMessage(
        messageId,
      );
      if (previousUserMessage == null) {
        debugPrint('❌ Cannot retry: no previous user message found');
        return;
      }

      // Get conversation context for better regeneration
      final context = await _messageUseCase.getConversationContext(
        messageId,
        contextLimit: 5,
      );

      // Set loading state for this specific message
      emit(currentState.copyWith(isLoading: true));

      // Generate new response using the previous user message and context
      final newResponse = await _generateResponseWithContext(
        previousUserMessage.content,
        context,
      );

      // Update the message with new content
      final regeneratedMessage = await _messageUseCase.regenerateBotMessage(
        messageId: messageId,
        newContent: newResponse,
        isOnline: true,
      );

      // Update the messages list in the state
      final updatedMessages =
          currentState.messages.map((msg) {
            return msg.id == messageId ? regeneratedMessage : msg;
          }).toList();

      // Sync the updated message
      try {
        await _syncUseCase.syncMessage(regeneratedMessage);
        await _messageUseCase.markAsSynced(messageId);
      } catch (e) {
        debugPrint('Failed to sync regenerated message: $e');
      }

      emit(currentState.copyWith(messages: updatedMessages, isLoading: false));

      debugPrint('✅ Message regenerated successfully');
    } catch (e) {
      debugPrint('❌ Error retrying message: $e');

      // Create error message to replace the failed one
      try {
        const errorResponse =
            'Sorry, I couldn\'t regenerate this response. Please try again.';
        final errorMessage = await _messageUseCase.regenerateBotMessage(
          messageId: messageId,
          newContent: errorResponse,
          isOnline: false,
        );

        final updatedMessages =
            currentState.messages.map((msg) {
              return msg.id == messageId ? errorMessage : msg;
            }).toList();

        emit(
          currentState.copyWith(messages: updatedMessages, isLoading: false),
        );
      } catch (updateError) {
        debugPrint('❌ Failed to update message with error: $updateError');
        emit(currentState.copyWith(isLoading: false));
      }
    }
  }

  /// Generate response with conversation context
  Future<String> _generateResponseWithContext(
    String userMessage,
    List<MessageModel> context,
  ) async {
    try {
      // Build context string from previous messages
      final contextBuffer = StringBuffer();

      if (context.isNotEmpty) {
        contextBuffer.writeln('Previous conversation context:');
        for (final msg in context) {
          final sender = msg.isUser ? 'User' : 'Assistant';
          contextBuffer.writeln('$sender: ${msg.content}');
        }
        contextBuffer.writeln('\nCurrent message:');
      }

      contextBuffer.writeln('User: $userMessage');

      // Send the full context to the API
      return await _sendMessageWithRetry(contextBuffer.toString());
    } catch (e) {
      // Fallback to simple message if context fails
      debugPrint('Context generation failed, using simple message: $e');
      return await _sendMessageWithRetry(userMessage);
    }
  }

  void _showOfflineMessage() {
    // This would typically show a snackbar or toast
    debugPrint('Cannot retry message while offline or not authenticated');
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
        rethrow;
      }
    }
  }

  Future<void> retryFailedMessages() async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;
    if (!currentState.isOnline ||
        !_isAuthenticationComplete ||
        currentState.isRetrying) {
      return;
    }

    emit(currentState.copyWith(isRetrying: true));

    try {
      final failedMessages = await _messageUseCase.getFailedMessages();
      debugPrint('🔄 Retrying ${failedMessages.length} failed messages');

      for (final failedMessage in failedMessages) {
        try {
          if (!failedMessage.isUser) {
            // For bot messages, regenerate the response
            await retryMessage(failedMessage.id);
          } else {
            // For user messages, just mark as synced if we can sync them
            await _syncUseCase.syncMessage(failedMessage);
            await _messageUseCase.markAsSynced(failedMessage.id);
          }
        } catch (e) {
          debugPrint('Failed to retry message ${failedMessage.id}: $e');
          // Increment retry count for tracking
          await chatRepository.incrementMessageRetryCount(failedMessage.id);
        }
      }

      debugPrint('✅ Finished retrying failed messages');
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
