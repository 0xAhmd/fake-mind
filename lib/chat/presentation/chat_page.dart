import 'package:fake_mind/chat/presentation/chat_bubble.dart';
import 'package:fake_mind/chat/presentation/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Start a convo..',
                      style: TextStyle(fontSize: 22, color: Colors.white),
                    ),
                  );
                }
                return ListView.builder(
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    return ChatBubble(message: message);
                  },
                  itemCount: chatProvider.messages.length,
                );
              },
            ),
          ),

          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              if (chatProvider.isLoading) {
                return  Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 180.0),
                    child: LinearProgressIndicator(
                      color: Colors.white,
                      backgroundColor: Colors.grey[600],
                    ))),
                );
              }
              return const SizedBox.shrink();
            },
          ),


          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: TextField(
                    cursorColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    controller: _controller,
                    decoration: InputDecoration(
                      hintStyle: const TextStyle(color: Colors.white),
                      hintText: 'Type a message',
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 15.0,
                        horizontal: 16.0,
                      ),

                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 16.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () {
                    final content = _controller.text.trim();
                    if (content.isNotEmpty) {
                      context.read<ChatProvider>().sendMessage(content);
                      _controller.clear();
                      FocusScope.of(context).unfocus();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
