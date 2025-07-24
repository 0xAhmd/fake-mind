// lib/chat/presentation/widgets/connection_status_banner.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';

class ConnectionStatusBanner extends StatelessWidget {
  const ConnectionStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        if (state is ChatLoaded && !state.isOnline) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.orange.withOpacity(0.2),
            child: Row(
              children: [
                const Icon(Icons.wifi_off, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Text(
                  'You\'re offline. Messages will sync when connected.',
                  style: GoogleFonts.inter(color: Colors.orange, fontSize: 12),
                ),
                const Spacer(),
                TextButton(
                  onPressed:
                      () => context.read<ChatCubit>().retryFailedMessages(),
                  child: Text(
                    'Retry',
                    style: GoogleFonts.inter(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
