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
                      style: TextStyle(fontSize: 20),
                    ),
                  );
                }
                return ListView.builder(
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    return Text(message.content);
                  },
                  itemCount: chatProvider.messages.length,
                );
              },
            ),
          ),

          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.greenAccent,
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(16.0)),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 16.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () {
                    final content = _controller.text.trim();
                    if (content.isNotEmpty) {
                      context.read<ChatProvider>().sendMessage(content);
                      _controller.clear();
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
