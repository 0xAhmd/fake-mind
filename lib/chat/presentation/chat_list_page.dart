import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/model/chat_model.dart';
import 'chat_provider.dart';
import 'chat_page.dart';
import '../../constants.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat History',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              return Row(
                children: [
                  // Online/Offline indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          chatProvider.isOnline ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      chatProvider.isOnline ? 'Online' : 'Offline',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Retry button for offline mode
                  if (!chatProvider.isOnline)
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () => chatProvider.retryFailedMessages(),
                    ),
                  const SizedBox(width: 8),
                ],
              );
            },
          ),
        ],
      ),
      backgroundColor: kscaffoldBackgroundColor,
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.chatHistory.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a new conversation',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chatProvider.chatHistory.length,
            itemBuilder: (context, index) {
              final chat = chatProvider.chatHistory[index];
              return ChatListItem(
                chat: chat,
                onTap: () {
                  chatProvider.switchToChat(chat.id);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatPage()),
                  );
                },
                onDelete: () => _showDeleteDialog(context, chat, chatProvider),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<ChatProvider>().createNewChat();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatPage()),
          );
        },
        backgroundColor: kChatBubbleUser,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    ChatModel chat,
    ChatProvider chatProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xff2a2a2a),
          title: Text(
            'Delete Chat',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to delete "${chat.title}"? This action cannot be undone.',
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
                chatProvider.deleteChat(chat.id);
                Navigator.of(context).pop();
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
}

class ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xff1a1a1a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
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
        title: Text(
          chat.title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatDate(chat.updatedAt),
          style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 14),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey[400]),
          color: const Color(0xff2a2a2a),
          onSelected: (value) {
            if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder:
              (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Delete',
                        style: GoogleFonts.inter(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
        ),
        onTap: onTap,
      ),
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
