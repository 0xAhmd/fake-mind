import 'package:fake_mind/chat/presentation/widgets/chat_bubble.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../../../../constants.dart';

class MessagesList extends StatelessWidget {
  final ScrollController scrollController;

  const MessagesList({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        if (state is ChatLoaded) {
          if (state.messages.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            controller: scrollController,
            itemBuilder: (context, index) {
              final message = state.messages[index];
              return ChatBubble(
                message: message,
                showSyncStatus: !state.isOnline,
                onRetry:
                    !message.isUser
                        ? () => _retryMessage(context, message.id)
                        : null,
              );
            },
            itemCount: state.messages.length,
          );
        }

        if (state is ChatError) {
          return _buildErrorState(state.error);
        }

        return const Center(
          child: CupertinoActivityIndicator(color: kChatBubbleUser),
        );
      },
    );
  }

  void _retryMessage(BuildContext context, String messageId) {
    // You'll need to implement this method in your ChatCubit
    context.read<ChatCubit>().retryMessage(messageId);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(startStateImg, width: 84, color: Colors.white),
          const SizedBox(height: 10),
          Text(
            'Start a conversation',
            style: GoogleFonts.inter(fontSize: 20, color: Colors.grey[400]),
          ),

          Text(
            'Type a message below to begin',
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Error loading messages',
            style: GoogleFonts.inter(fontSize: 18, color: Colors.red[400]),
          ),
          const SizedBox(height: 8),
          Text(
            error ?? 'Unknown error',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
