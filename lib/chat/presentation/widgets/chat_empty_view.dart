import 'package:fake_mind/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatEmptyView extends StatelessWidget {
  final String searchQuery;

  const ChatEmptyView({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final bool isSearching = searchQuery.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            isSearching ? emptySearchStateImg : emptyStateImg,
            width: 130,
          ),

          Text(
            isSearching ? 'No Chats Found' : 'No chats yet',
            style: GoogleFonts.inter(
              fontSize: 22,
              color: Colors.grey[300],
              fontWeight: FontWeight.w600,
            ),
          ),

          Text(
            isSearching
                ? 'Try another search query'
                : 'Start a new conversation',
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
