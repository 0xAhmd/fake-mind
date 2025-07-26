import 'package:fake_mind/chat/presentation/cubit/chat_cubit.dart';
import 'package:fake_mind/chat/presentation/cubit/chat_state.dart';
import 'package:fake_mind/chat/presentation/widgets/chat_empty_view.dart';
import 'package:fake_mind/chat/presentation/widgets/chat_err_view.dart';
import 'package:fake_mind/chat/presentation/widgets/chat_list_view.dart';
import 'package:fake_mind/chat/presentation/widgets/chat_search_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../constants.dart';

class ChatListBody extends StatelessWidget {
  const ChatListBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        if (state is ChatLoaded) {
          final chats = state.searchQuery.isEmpty
              ? state.chatHistory
              : state.filteredChats;

          return Column(
            children: [
              // Show search bar if there are any chats in history
              if (state.chatHistory.isNotEmpty) const ChatSearchBar(),
              const SizedBox(height: 3),
              
              // Show content based on whether we have filtered results
              Expanded(
                child: chats.isEmpty
                    ? ChatEmptyView(searchQuery: state.searchQuery)
                    : ChatListView(chats: chats),
              ),
            ],
          );
        }

        if (state is ChatError) {
          return ChatErrorView(error: state.error);
        }

        return const Center(
          child: CupertinoActivityIndicator(color: kChatBubbleUser),
        );
      },
    );
  }
}