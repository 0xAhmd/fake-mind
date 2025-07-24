import 'package:fake_mind/chat/presentation/widgets/chat_dialogs.dart';
import 'package:fake_mind/chat/presentation/widgets/chat_list_appbar.dart';
import 'package:fake_mind/chat/presentation/widgets/chat_list_body.dart';
import 'package:flutter/material.dart';

import '../../../constants.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ChatListAppBar(),
      backgroundColor: kScaffoldBackgroundColor,
      body: const ChatListBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ChatDialogs.showNewChatDialog(context),
        backgroundColor: kChatBubbleUser,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
