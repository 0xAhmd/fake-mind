// lib/chat/presentation/widgets/chat_list_app_bar.dart
import 'package:fake_mind/chat/presentation/cubit/chat_cubit.dart';
import 'package:fake_mind/chat/presentation/cubit/chat_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatListAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatListAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
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
                  _buildStatusIndicator(state.isOnline),
                  const SizedBox(width: 8),
                  if (!state.isOnline) _buildRetryButton(context),
                  const SizedBox(width: 8),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOnline ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isOnline ? 'Online' : 'Offline',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRetryButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.refresh, color: Colors.white),
      onPressed: () => context.read<ChatCubit>().retryFailedMessages(),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
