import 'package:fake_mind/chat/presentation/widgets/delete_chat_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';

class ChatMenu extends StatelessWidget {
  const ChatMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        return PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: const Color(0xff2a2a2a),
          onSelected: (value) => _handleMenuSelection(context, value, state),
          itemBuilder:
              (BuildContext context) => [
                _buildMenuItem('new_chat', Icons.add, 'New Chat', Colors.white),

                if (state is ChatLoaded && state.currentChat != null)
                  _buildMenuItem(
                    'delete',
                    Icons.delete,
                    'Delete Chat',
                    Colors.red,
                  ),
              ],
        );
      },
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    String value,
    IconData icon,
    String text,
    Color color,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(text, style: GoogleFonts.inter(color: color)),
        ],
      ),
    );
  }

  void _handleMenuSelection(
    BuildContext context,
    String value,
    ChatState state,
  ) {
    final chatCubit = context.read<ChatCubit>();

    switch (value) {
      case 'new_chat':
        chatCubit.createNewChat();

        break;
      case 'delete':
        if (state is ChatLoaded && state.currentChat != null) {
          showDeleteChatDialog(context, chatCubit);
        }
        break;
    }
  }
}
