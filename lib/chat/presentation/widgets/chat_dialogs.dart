import 'package:fake_mind/chat/presentation/cubit/chat_cubit.dart';
import 'package:fake_mind/chat/presentation/pages/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/model/chat_model.dart';
import '../../../../constants.dart';

class ChatDialogs {
  static void showNewChatDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff2a2a2a),
        title: Text('New Chat', style: GoogleFonts.inter(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Give your chat a name (optional)',
              style: GoogleFonts.inter(color: Colors.grey[300]),
            ),
            const SizedBox(height: 16),
            _buildTextField(nameController, 'Enter chat name...'),
          ],
        ),
        actions: [
          _buildCancelButton(context),
          _buildCreateButton(context, nameController),
        ],
      ),
    );
  }

  static void showRenameDialog(BuildContext context, ChatModel chat) {
    final TextEditingController nameController = 
        TextEditingController(text: chat.title);

    debugPrint('🔄 Showing rename dialog for chat: ${chat.id} - "${chat.title}"');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff2a2a2a),
        title: Text('Rename Chat', style: GoogleFonts.inter(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: _getTextFieldDecoration('Enter new name...'),
              maxLength: 50,
              textCapitalization: TextCapitalization.words,
              autofocus: true,
              onSubmitted: (value) => _handleRenameSubmit(context, chat, value),
            ),
          ],
        ),
        actions: [
          _buildCancelButton(context),
          _buildRenameButton(context, chat, nameController),
        ],
      ),
    );
  }

  static void showDeleteDialog(BuildContext context, ChatModel chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff2a2a2a),
        title: Text('Delete Chat', style: GoogleFonts.inter(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${chat.title}"? This action cannot be undone.',
          style: GoogleFonts.inter(color: Colors.grey[300]),
        ),
        actions: [
          _buildCancelButton(context),
          TextButton(
            onPressed: () {
              context.read<ChatCubit>().deleteChat(chat.id);
              Navigator.of(context).pop();
            },
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  static Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(color: Colors.white),
      decoration: _getTextFieldDecoration(hint),
      maxLength: 50,
      textCapitalization: TextCapitalization.words,
    );
  }

  static InputDecoration _getTextFieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  static Widget _buildCancelButton(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey[400])),
    );
  }

  static Widget _buildCreateButton(
    BuildContext context,
    TextEditingController controller,
  ) {
    return ElevatedButton(
      onPressed: () => _handleCreateChat(context, controller),
      style: ElevatedButton.styleFrom(backgroundColor: kChatBubbleUser),
      child: Text('Create', style: GoogleFonts.inter(color: Colors.white)),
    );
  }

  static Widget _buildRenameButton(
    BuildContext context,
    ChatModel chat,
    TextEditingController controller,
  ) {
    return ElevatedButton(
      onPressed: () => _handleRename(context, chat, controller),
      style: ElevatedButton.styleFrom(backgroundColor: kChatBubbleUser),
      child: Text('Rename', style: GoogleFonts.inter(color: Colors.white)),
    );
  }

  static void _handleCreateChat(
    BuildContext context,
    TextEditingController controller,
  ) {
    final chatName = controller.text.trim();
    if (chatName.isNotEmpty) {
      context.read<ChatCubit>().createNewChatWithName(chatName);
    } else {
      context.read<ChatCubit>().createNewChat();
    }
    Navigator.of(context).pop();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatPage()),
    );
  }

  static void _handleRename(
    BuildContext context,
    ChatModel chat,
    TextEditingController controller,
  ) {
    final newName = controller.text.trim();
    debugPrint('🔄 Rename button pressed with name: "$newName"');

    if (newName.isNotEmpty && newName != chat.title) {
      debugPrint('✅ Proceeding with rename');
      context.read<ChatCubit>().renameChat(chat.id, newName);
      Navigator.of(context).pop();
    } else {
      _handleRenameError(context, newName, chat.title);
    }
  }

  static void _handleRenameSubmit(
    BuildContext context,
    ChatModel chat,
    String value,
  ) {
    final newName = value.trim();
    if (newName.isNotEmpty && newName != chat.title) {
      debugPrint('🔄 Submitting rename via Enter key: "$newName"');
      context.read<ChatCubit>().renameChat(chat.id, newName);
      Navigator.of(context).pop();
    }
  }

  static void _handleRenameError(
    BuildContext context,
    String newName,
    String originalTitle,
  ) {
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Chat name cannot be empty',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } else if (newName == originalTitle) {
      Navigator.of(context).pop();
    }
  }
}