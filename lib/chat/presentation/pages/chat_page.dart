import 'package:fake_mind/chat/presentation/cubit/chat_cubit.dart';
import 'package:fake_mind/chat/presentation/widgets/chat_appbar.dart';
import 'package:fake_mind/chat/presentation/widgets/connection_status_bar.dart';
import 'package:fake_mind/chat/presentation/widgets/loading_indicator.dart';
import 'package:fake_mind/chat/presentation/widgets/messages_list.dart';
import 'package:fake_mind/chat/presentation/widgets/messages_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../constants.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final content = _controller.text.trim();
    if (content.isNotEmpty) {
      context.read<ChatCubit>().sendMessage(content);
      _controller.clear();
      FocusScope.of(context).unfocus();
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: kScaffoldBackgroundColor,
        appBar: const ChatAppBar(),
        body: Column(
          children: [
            const ConnectionStatusBanner(),
            const SizedBox(height: 14),
            Expanded(child: MessagesList(scrollController: _scrollController)),
            const LoadingIndicator(),
            MessageInput(controller: _controller, onSend: _sendMessage),
          ],
        ),
      ),
    );
  }
}
