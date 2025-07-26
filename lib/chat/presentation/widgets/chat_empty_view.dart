import 'package:fake_mind/constants.dart';
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
          Image.asset(emptyStateImg, width: 130, color: Colors.white),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty ? 'No chats yet' : 'No chats found',
            style: GoogleFonts.inter(fontSize: 20, color: Colors.grey[400]),
          ),

          Text(
            searchQuery.isEmpty
                ? 'Start a new conversation'
                : 'Try a different search term',
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
