import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../../../../constants.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        if (state is ChatLoaded && state.isLoading) {
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
                      state.isOnline ? 'Thinking...' : 'Saving offline...',
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
    );
  }
}
