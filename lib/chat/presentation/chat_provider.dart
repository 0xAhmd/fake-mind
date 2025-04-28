import 'package:fake_mind/chat/data/deepseek_api_service.dart';
import 'package:fake_mind/chat/data/model/message_model.dart';
import 'package:flutter/material.dart';

class ChatProvider with ChangeNotifier {
  final _apiService = DeepseekApiService(
    apiKey: 'sk-2d54856600ba4f58a722333104bea9ce',
  );
  // messages list to store the messages
  final List<MessageModel> _messages = [];
  // loading state to show loading indicator
  bool _isLoading = false;
  // GETTERS
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;

  // method to send a message

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final userMessage = MessageModel(
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
    // add the user message to the list
    _messages.add(userMessage);
    notifyListeners();
    // set loading state to true
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.sendMessage(content);

      final responseMessage = MessageModel(
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(responseMessage);

      
    } catch (e) {
      final errorMessage = MessageModel(
        content: 'Sorry, something went wrong: $e',
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(errorMessage);
    }
    _isLoading = false;
    notifyListeners();
  }
}
