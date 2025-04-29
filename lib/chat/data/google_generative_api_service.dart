import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleGenerativeApiService {
  static const String baseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";
  final String _apiKey;

  GoogleGenerativeApiService({required String apiKey}) : _apiKey = apiKey;

  Future<String> sendMessage(String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?key=$_apiKey'),
        headers: _getHeaders(),
        body: _getBody(content),
      );

      // Log the response body for debugging

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        // Safely access nested fields based on the actual response structure
        final candidates = responseBody['candidates'];
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          if (content != null) {
            final parts = content['parts'];
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'];
              if (text != null) {
                return text;
              }
            }
          }
        }
        throw Exception('Unexpected response structure: ${response.body}');
      } else {
        throw Exception(
          'Failed to load data: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to load data: $e');
    }
  }

  Map<String, String> _getHeaders() {
    return {'Content-Type': 'application/json'};
  }

  String _getBody(String content) => jsonEncode({
    'contents': [
      {
        'parts': [
          {'text': content},
        ],
      },
    ],
  });
}
