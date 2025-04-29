import 'package:fake_mind/chat/data/google_generative_api_service.dart';
import 'package:fake_mind/chat/data/model/message_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatProvider with ChangeNotifier {
  final _apiService = GoogleGenerativeApiService(
    apiKey: dotenv.env['API_KEY'] ?? '',
  );

  // Messages list to store the messages
  final List<MessageModel> _messages = [];
  // Loading state to show loading indicator
  bool _isLoading = false;

  // GETTERS
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;

  // Method to send a message
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final userMessage = MessageModel(
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
    // Add the user message to the list
    _messages.add(userMessage);
    notifyListeners();

    // Set loading state to true
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
