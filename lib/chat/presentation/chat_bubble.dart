import 'package:fake_mind/chat/data/model/message_model.dart';
import 'package:fake_mind/constants.dart';
import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final MessageModel message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 13.0,
          horizontal: 17.0,
        ), // Adjusted padding
        margin: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 16.0,
        ), // Adjusted margin
        decoration: BoxDecoration(
          color:
              message.isUser
                  ? kChatBubbleUser
                  : kChatBubbleBot, 
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Text(
          message.content,
          style: const TextStyle(color: Colors.white, fontSize: 18.0),
        ),
      ),
    );
  }
}
