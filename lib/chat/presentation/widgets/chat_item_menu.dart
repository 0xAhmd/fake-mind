import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/model/chat_model.dart';

class ChatItemMenu extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback onRename;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  const ChatItemMenu({
    super.key,
    required this.chat,
    required this.onRename,
    required this.onPin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.grey[400]),
      color: const Color(0xff2a2a2a),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        switch (value) {
          case 'rename':
            onRename();
            break;
          case 'pin':
            onPin();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      itemBuilder:
          (context) => [
            _buildMenuItem('rename', Icons.edit, 'Rename', Colors.white),
            _buildMenuItem(
              'pin',
              chat.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              chat.isPinned ? 'Unpin' : 'Pin',
              Colors.white,
            ),
            _buildMenuItem('delete', Icons.delete, 'Delete', Colors.redAccent),
          ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    String value,
    IconData icon,
    String text,
    Color color,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
