import 'package:fake_mind/chat/presentation/cubit/chat_cubit.dart';
import 'package:fake_mind/chat/presentation/pages/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickalert/quickalert.dart';
import '../../data/model/chat_model.dart';
import '../../../../constants.dart';

class ChatDialogs {
  static void showNewChatDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      title: 'New Chat',
      backgroundColor: const Color(0xff2a2a2a),
      titleColor: Colors.white,
      textColor: Colors.white70,
      confirmBtnText: 'Create',
      cancelBtnText: 'Cancel',
      showCancelBtn: true,
      confirmBtnColor: kChatBubbleUser,
      customAsset: null,
      widget: _buildTextField(nameController, 'Enter chat name...'),
      onConfirmBtnTap: () {
        final chatName = nameController.text.trim();
        if (chatName.isNotEmpty) {
          context.read<ChatCubit>().createNewChatWithName(chatName);
        } else {
          context.read<ChatCubit>().createNewChat();
        }
        Navigator.of(context).pop(); // close dialog
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatPage()),
        );
      },
    );
  }

  static void showRenameDialog(BuildContext context, ChatModel chat) {
    final TextEditingController nameController = TextEditingController(
      text: chat.title,
    );

    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      title: 'Rename Chat',
      backgroundColor: const Color(0xff2a2a2a),
      titleColor: Colors.white,
      textColor: Colors.white70,
      confirmBtnText: 'Rename',
      cancelBtnText: 'Cancel',
      showCancelBtn: true,
      confirmBtnColor: kChatBubbleUser,
      widget: _buildTextField(nameController, 'Enter new name...'),
      onConfirmBtnTap: () {
        final newName = nameController.text.trim();
        if (newName.isEmpty) {
          _showError(context, 'Chat name cannot be empty');
          return;
        }
        if (newName == chat.title) {
          Navigator.of(context).pop();
          return;
        }

        context.read<ChatCubit>().renameChat(chat.id, newName);
        Navigator.of(context).pop();
      },
    );
  }

  static void showDeleteDialog(BuildContext context, ChatModel chat) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: 'Delete Chat',
      text:
          'Are you sure you want to delete "${chat.title}"?\nThis action cannot be undone.',
      backgroundColor: const Color(0xff2a2a2a),
      titleColor: Colors.white,
      textColor: Colors.white70,
      confirmBtnText: 'Delete',
      cancelBtnText: 'Cancel',
      showCancelBtn: true,
      confirmBtnColor: Colors.redAccent,
      onConfirmBtnTap: () {
        context.read<ChatCubit>().deleteChat(chat.id);
        Navigator.of(context).pop(); // close the alert
      },
    );
  }

  static Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      maxLength: 50,
      textCapitalization: TextCapitalization.words,
      autofocus: true,
    );
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }
}
