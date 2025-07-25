import 'package:fake_mind/chat/presentation/widgets/chat_item_menu.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/model/chat_model.dart';
import '../../../../constants.dart';

class ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onPin;
  final VoidCallback onRename;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.onTap,
    required this.onDelete,
    required this.onPin,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xff1a1a1a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              chat.isPinned
                  ? kChatBubbleUser.withOpacity(0.5)
                  : Colors.grey[800]!,
          width: chat.isPinned ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildLeadingIcon(),
        title: _buildTitle(),
        subtitle: _buildSubtitle(),
        trailing: ChatItemMenu(
          chat: chat,
          onRename: onRename,
          onPin: onPin,
          onDelete: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLeadingIcon() {
    return SizedBox(
      width: 52, // add a bit of space to allow the icon to overflow
      height: 52,
      child: Stack(
        clipBehavior: Clip.none, // important: allow overflow
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kChatBubbleUser.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.chat_bubble,
              color: kChatBubbleUser,
              size: 24,
            ),
          ),
          if (chat.isPinned)
            const Positioned(
              right: -4, // slight overlap
              top: -4,
              child: CircleAvatar(
                radius: 7,
                backgroundColor: kChatBubbleUser,
                child: Icon(Icons.push_pin, size: 9, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      chat.title,
      style: GoogleFonts.inter(
        color: Colors.white,
        fontWeight: chat.isPinned ? FontWeight.w600 : FontWeight.w500,
        fontSize: 16,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatDate(chat.updatedAt),
          style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 14),
        ),
        if (chat.lastMessage != null)
          Text(
            chat.lastMessage!,
            style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
