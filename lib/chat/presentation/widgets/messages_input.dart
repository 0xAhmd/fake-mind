// lib/chat/presentation/widgets/message_input.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../constants.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              cursorColor: Colors.white,
              style: GoogleFonts.inter(color: Colors.white),
              controller: controller,
              maxLines: null,
              decoration: _buildInputDecoration(),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: kChatBubbleUser,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: onSend,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration() {
    return InputDecoration(
      hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
      hintText: 'Type a message...',
      contentPadding: const EdgeInsets.symmetric(
        vertical: 15.0,
        horizontal: 16.0,
      ),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[700]!, width: 1.0),
        borderRadius: BorderRadius.circular(25.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[700]!, width: 1.0),
        borderRadius: BorderRadius.circular(25.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: kChatBubbleUser, width: 2.0),
        borderRadius: BorderRadius.circular(25.0),
      ),
      filled: true,
      fillColor: Colors.grey[900],
    );
  }
}
