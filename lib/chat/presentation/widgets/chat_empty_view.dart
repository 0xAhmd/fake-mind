import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatEmptyView extends StatelessWidget {
  final String searchQuery;

  const ChatEmptyView({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty ? 'No chats yet' : 'No chats found',
            style: GoogleFonts.inter(fontSize: 18, color: Colors.grey[400]),
          ),

          Text(
            searchQuery.isEmpty
                ? 'Start a new conversation'
                : 'Try a different search term',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
