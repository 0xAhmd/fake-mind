// lib/chat/presentation/chat_list_page.dart
import 'package:fake_mind/chat/presentation/cubit/chat_cubit.dart';
import 'package:fake_mind/chat/presentation/cubit/chat_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/model/chat_model.dart';

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
            fontSize: 28,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          BlocBuilder<ChatCubit, ChatState>(
            builder: (context, state) {
              if (state is ChatLoaded) {
                return Row(
                  children: [
                    // Online/Offline indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: state.isOnline ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        state.isOnline ? 'Online' : 'Offline',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Retry button for offline mode
                    if (!state.isOnline)
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed:
                            () =>
                                context.read<ChatCubit>().retryFailedMessages(),
                      ),
                    const SizedBox(width: 8),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      backgroundColor: kScaffoldBackgroundColor,
      body: BlocBuilder<ChatCubit, ChatState>(
        builder: (context, state) {
          if (state is ChatLoaded) {
            final chats =
                state.searchQuery.isEmpty
                    ? state.chatHistory
                    : state.filteredChats;

            if (chats.isEmpty) {
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
                      state.searchQuery.isEmpty
                          ? 'No chats yet'
                          : 'No chats found',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.searchQuery.isEmpty
                          ? 'Start a new conversation'
                          : 'Try a different search term',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Search bar
                if (state.chatHistory.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: TextField(
                      onChanged:
                          (query) =>
                              context.read<ChatCubit>().searchChats(query),
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search chats...',
                        hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                        suffixIcon:
                            state.searchQuery.isNotEmpty
                                ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.grey[500],
                                  ),
                                  onPressed:
                                      () => context
                                          .read<ChatCubit>()
                                          .searchChats(''),
                                )
                                : null,
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                // Chat list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await context.read<ChatCubit>().loadChatHistory();
                    },
                    color: kChatBubbleUser,
                    backgroundColor: Colors.black,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        return ChatListItem(
                          chat: chat,
                          onTap: () {
                            context.read<ChatCubit>().switchToChat(chat.id);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ChatPage(),
                              ),
                            );
                          },
                          onDelete: () => _showDeleteDialog(context, chat),
                          onPin:
                              () => context.read<ChatCubit>().toggleChatPin(
                                chat.id,
                              ),
                          onRename: () => _showRenameDialog(context, chat),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          }

          if (state is ChatError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading chats',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: Colors.red[400],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.error ?? 'Unknown error',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Recreate the cubit to retry initialization
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatListPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kChatBubbleUser,
                    ),
                    child: Text(
                      'Retry',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          return const Center(
            child: CircularProgressIndicator(color: kChatBubbleUser),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatDialog(context),
        backgroundColor: kChatBubbleUser,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showNewChatDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xff2a2a2a),
          title: Text(
            'New Chat',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Give your chat a name (optional)',
                style: GoogleFonts.inter(color: Colors.grey[300]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter chat name...',
                  hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLength: 50,
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey[400]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final chatName = nameController.text.trim();
                if (chatName.isNotEmpty) {
                  context.read<ChatCubit>().createNewChatWithName(chatName);
                } else {
                  context.read<ChatCubit>().createNewChat();
                }
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatPage()),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: kChatBubbleUser),
              child: Text(
                'Create',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, ChatModel chat) {
    final TextEditingController nameController = TextEditingController(
      text: chat.title,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xff2a2a2a),
          title: Text(
            'Rename Chat',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter new name...',
                  hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLength: 50,
                textCapitalization: TextCapitalization.words,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey[400]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty && newName != chat.title) {
                  context.read<ChatCubit>().renameChat(chat.id, newName);
                }
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: kChatBubbleUser),
              child: Text(
                'Rename',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, ChatModel chat) {
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
                context.read<ChatCubit>().deleteChat(chat.id);
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
        leading: Stack(
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
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: kChatBubbleUser,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.push_pin,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          chat.title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: chat.isPinned ? FontWeight.w600 : FontWeight.w500,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
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
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey[400]),
          color: const Color(0xff2a2a2a),
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
              (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'rename',
                  child: Row(
                    children: [
                      const Icon(Icons.edit, color: kChatBubbleUser, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Rename',
                        style: GoogleFonts.inter(color: kChatBubbleUser),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'pin',
                  child: Row(
                    children: [
                      Icon(
                        chat.isPinned
                            ? Icons.push_pin_outlined
                            : Icons.push_pin,
                        color: kChatBubbleUser,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        chat.isPinned ? 'Unpin' : 'Pin',
                        style: GoogleFonts.inter(color: kChatBubbleUser),
                      ),
                    ],
                  ),
                ),
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
