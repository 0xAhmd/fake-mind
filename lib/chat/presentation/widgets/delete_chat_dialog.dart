import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';

void showDeleteChatDialog(BuildContext context, ChatCubit chatCubit) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xff2a2a2a),
        title: Text(
          'Delete Current Chat',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete this chat? This action cannot be undone.',
          style: GoogleFonts.inter(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            onPressed: () {
              final state = chatCubit.state;
              if (state is ChatLoaded && state.currentChat != null) {
                chatCubit.deleteChat(state.currentChat!.id);
              }
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to chat list
            },
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: Colors.red),
            ),
          ),
        ],
      );
    },
  );
}