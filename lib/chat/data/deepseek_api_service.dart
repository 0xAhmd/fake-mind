// ignore_for_file: unused_field

/*
Service class to handle API requests to DeepSeek API.
This class is responsible for making HTTP requests to the DeepSeek API
and returning the results.
 */
import 'dart:convert';

import 'package:http/http.dart' as http;

class DeepseekApiService {
  static const String basUrl = "https://api.deepseek.com/v1/chat/completions";
  static const String _model = "deepseek-chat"; // model to be used
  // store the API key in a secure way
  final String _apiKey;

  // constructor to initialize the API key
  DeepseekApiService({required String apiKey}) : _apiKey = apiKey;

  // send a request to the DeepSeek API

  Future<String> sendMessage(String content) async {
    try {
      // make a POST request to the API
      final response = await http.post(
        Uri.parse(basUrl),
        headers: _getHeaders(),
        body: _getBody(content),
      );

      // check if the response is successful
      if (response.statusCode == 200) {
        // parse the response body
        // and extract the message content
        final responseBody = jsonDecode(response.body);
        final message = responseBody['choices'][0]['message']['content'];
        return message;
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load data: $e');
    }
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey', // Add 'Bearer' prefix
    };
  }

  String _getBody(String content) => jsonEncode({
    'model': _model,
    'messages': [
      {'role': 'user', 'content': content},
    ],
    'max_tokens': 1024,
  });
}
