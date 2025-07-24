import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_bubble.dart';
import 'chat_provider.dart';
import 'chat_list_page.dart';
import '../../constants.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: kscaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatProvider.currentChat?.title ?? 'New Chat',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color:
                              chatProvider.isOnline
                                  ? Colors.green
                                  : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        chatProvider.isOnline ? 'Online' : 'Offline',
                        style: GoogleFonts.inter(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.history, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatListPage()),
                );
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: const Color(0xff2a2a2a),
              onSelected: (value) {
                final chatProvider = context.read<ChatProvider>();
                switch (value) {
                  case 'new_chat':
                    chatProvider.createNewChat();
                    break;
                  case 'retry':
                    chatProvider.retryFailedMessages();
                    break;
                  case 'delete':
                    if (chatProvider.currentChat != null) {
                      _showDeleteCurrentChatDialog(context, chatProvider);
                    }
                    break;
                }
              },
              itemBuilder:
                  (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'new_chat',
                      child: Row(
                        children: [
                          const Icon(Icons.add, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'New Chat',
                            style: GoogleFonts.inter(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'retry',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.refresh,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Retry Failed',
                            style: GoogleFonts.inter(color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                    if (context.read<ChatProvider>().currentChat != null)
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Delete Chat',
                              style: GoogleFonts.inter(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                  ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Connection status banner
            Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (!chatProvider.isOnline) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    color: Colors.orange.withOpacity(0.2),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.wifi_off,
                          color: Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'You\'re offline. Messages will sync when connected.',
                          style: GoogleFonts.inter(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => chatProvider.retryFailedMessages(),
                          child: Text(
                            'Retry',
                            style: GoogleFonts.inter(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 14),

            // Messages list
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  if (chatProvider.messages.isEmpty) {
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
                            'Start a conversation',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Type a message below to begin',
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
                    controller: _scrollController,
                    itemBuilder: (context, index) {
                      final message = chatProvider.messages[index];
                      return ChatBubble(
                        message: message,
                        showSyncStatus: !chatProvider.isOnline,
                      );
                    },
                    itemCount: chatProvider.messages.length,
                  );
                },
              ),
            ),

            // Loading indicator
            Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.isLoading) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Column(
                          children: [
                            LinearProgressIndicator(
                              color: kChatBubbleUser,
                              backgroundColor: Colors.grey[600],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              chatProvider.isOnline
                                  ? 'Thinking...'
                                  : 'Saving offline...',
                              style: GoogleFonts.inter(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Input field
            Container(
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
                      controller: _controller,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
                        hintText: 'Type a message...',
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15.0,
                          horizontal: 16.0,
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey[700]!,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey[700]!,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: kChatBubbleUser,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                      ),
                      onSubmitted: (value) => _sendMessage(),
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
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final content = _controller.text.trim();
    if (content.isNotEmpty) {
      context.read<ChatProvider>().sendMessage(content);
      _controller.clear();
      FocusScope.of(context).unfocus();
      _scrollToBottom();
    }
  }

  void _showDeleteCurrentChatDialog(
    BuildContext context,
    ChatProvider chatProvider,
  ) {
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
                if (chatProvider.currentChat != null) {
                  chatProvider.deleteChat(chatProvider.currentChat!.id);
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
}
