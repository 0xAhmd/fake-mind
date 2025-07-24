import 'package:fake_mind/chat/presentation/pages/chat_list_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../constants.dart';

class ChatErrorView extends StatelessWidget {
  final String? error;

  const ChatErrorView({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Error loading chats',
            style: GoogleFonts.inter(fontSize: 18, color: Colors.red[400]),
          ),
          const SizedBox(height: 8),
          Text(
            error ?? 'Unknown error',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _retryLoading(context),
            style: ElevatedButton.styleFrom(backgroundColor: kChatBubbleUser),
            child: Text('Retry', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _retryLoading(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ChatListPage()),
    );
  }
}
