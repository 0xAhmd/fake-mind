import 'package:flutter/material.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';

import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';

void showDeleteChatDialog(BuildContext context, ChatCubit chatCubit) {
  QuickAlert.show(
    context: context,
    type: QuickAlertType.confirm,
    title: 'Delete Current Chat',
    text:
        'Are you sure you want to delete this chat? This action cannot be undone.',
    confirmBtnText: 'Delete',
    cancelBtnText: 'Cancel',
    confirmBtnColor: Colors.redAccent,
    textColor: Colors.white,
    backgroundColor: const Color(0xff2a2a2a),
    titleColor: Colors.white,
    barrierDismissible: true,
    onConfirmBtnTap: () {
      final state = chatCubit.state;
      if (state is ChatLoaded && state.currentChat != null) {
        chatCubit.deleteChat(state.currentChat!.id);
      }
      Navigator.of(context).pop(); // Close dialog
      Navigator.of(context).pop(); // Go back to chat list
    },
    onCancelBtnTap: () {
      Navigator.of(context).pop(); // Just close dialog
    },
  );
}
