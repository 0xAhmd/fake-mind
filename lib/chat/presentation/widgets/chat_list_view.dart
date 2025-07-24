import 'package:fake_mind/chat/presentation/cubit/chat_cubit.dart';
import 'package:fake_mind/chat/presentation/pages/chat_page.dart';
import 'package:fake_mind/chat/presentation/widgets/chat_dialogs.dart';
import 'package:fake_mind/chat/presentation/widgets/chat_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/model/chat_model.dart';
import '../../../../constants.dart';

class ChatListView extends StatelessWidget {
  final List<ChatModel> chats;

  const ChatListView({super.key, required this.chats});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
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
            onTap: () => _navigateToChat(context, chat),
            onDelete: () => ChatDialogs.showDeleteDialog(context, chat),
            onPin: () => context.read<ChatCubit>().toggleChatPin(chat.id),
            onRename: () => ChatDialogs.showRenameDialog(context, chat),
          );
        },
      ),
    );
  }

  void _navigateToChat(BuildContext context, ChatModel chat) {
    context.read<ChatCubit>().switchToChat(chat.id);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatPage()),
    );
  }
}
