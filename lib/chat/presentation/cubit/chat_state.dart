// lib/chat/presentation/bloc/chat_state.dart
import 'package:equatable/equatable.dart';
import '../../data/model/chat_model.dart';
import '../../data/model/message_model.dart';

abstract class ChatState extends Equatable {
  const ChatState({
    this.currentChat,
    this.messages = const [],
    this.chatHistory = const [],
    this.isLoading = false,
    this.isOnline = false,
    this.isRetrying = false,
    this.searchQuery = '',
    this.filteredChats = const [],
    this.statistics = const {},
    this.error,
  });

  final ChatModel? currentChat;
  final List<MessageModel> messages;
  final List<ChatModel> chatHistory;
  final bool isLoading;
  final bool isOnline;
  final bool isRetrying;
  final String searchQuery;
  final List<ChatModel> filteredChats;
  final Map<String, dynamic> statistics;
  final String? error;

  @override
  List<Object?> get props => [
    currentChat,
    messages,
    chatHistory,
    isLoading,
    isOnline,
    isRetrying,
    searchQuery,
    filteredChats,
    statistics,
    error,
  ];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoaded extends ChatState {
  const ChatLoaded({
    super.currentChat,
    super.messages,
    super.chatHistory,
    super.isLoading,
    super.isOnline,
    super.isRetrying,
    super.searchQuery,
    super.filteredChats,
    super.statistics,
    super.error,
  });

  ChatLoaded copyWith({
    ChatModel? currentChat,
    List<MessageModel>? messages,
    List<ChatModel>? chatHistory,
    bool? isLoading,
    bool? isOnline,
    bool? isRetrying,
    String? searchQuery,
    List<ChatModel>? filteredChats,
    Map<String, dynamic>? statistics,
    String? error,
  }) {
    return ChatLoaded(
      currentChat: currentChat ?? this.currentChat,
      messages: messages ?? this.messages,
      chatHistory: chatHistory ?? this.chatHistory,
      isLoading: isLoading ?? this.isLoading,
      isOnline: isOnline ?? this.isOnline,
      isRetrying: isRetrying ?? this.isRetrying,
      searchQuery: searchQuery ?? this.searchQuery,
      filteredChats: filteredChats ?? this.filteredChats,
      statistics: statistics ?? this.statistics,
      error: error,
    );
  }
}

class ChatError extends ChatState {
  const ChatError({
    required String error,
    super.currentChat,
    super.messages,
    super.chatHistory,
    super.isLoading,
    super.isOnline,
    super.isRetrying,
    super.searchQuery,
    super.filteredChats,
    super.statistics,
  }) : super(error: error);
}
