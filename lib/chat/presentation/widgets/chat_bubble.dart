// ignore_for_file: deprecated_member_use
import 'package:markdown/markdown.dart' as md;
import 'package:fake_mind/chat/data/model/message_model.dart';
import 'package:fake_mind/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    this.showSyncStatus = false,
    this.onRetry,
  });

  final MessageModel message;
  final bool showSyncStatus;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 13.0,
              horizontal: 17.0,
            ),
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: message.isUser ? kChatBubbleUser : kChatBubbleBot,
              borderRadius: BorderRadius.circular(16.0),
              border:
                  showSyncStatus && !message.synced
                      ? Border.all(
                        color: Colors.orange.withOpacity(0.5),
                        width: 1,
                      )
                      : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message content
                MarkdownBody(
                  data: message.content,
                  selectable: true,
                  builders: {'code': CodeElementBuilder()},
                  styleSheet: MarkdownStyleSheet.fromTheme(
                    Theme.of(context),
                  ).copyWith(
                    p: TextStyle(
                      fontSize: 16.0,
                      color: Colors.white,
                      fontFamily: GoogleFonts.inter().fontFamily,
                    ),
                    strong: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: GoogleFonts.inter().fontFamily,
                    ),
                    code:
                        const TextStyle(), // disable default style, we'll replace it
                    codeblockPadding: const EdgeInsets.all(0),
                    codeblockDecoration: const BoxDecoration(),
                  ),
                ),

                // Timestamp and sync status
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.timestamp),
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),

                    if (showSyncStatus) ...[
                      const SizedBox(width: 6),
                      Icon(
                        message.synced ? Icons.cloud_done : Icons.cloud_off,
                        size: 12,
                        color:
                            message.synced
                                ? Colors.green.withOpacity(0.7)
                                : Colors.orange.withOpacity(0.7),
                      ),
                    ],

                    if (message.isUser) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.synced ? Icons.done_all : Icons.done,
                        size: 12,
                        color:
                            message.synced
                                ? Colors.blue.withOpacity(0.7)
                                : Colors.white.withOpacity(0.5),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Action buttons for bot messages only
          if (!message.isUser) _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Copy button
          GestureDetector(
            onTap: () => _copyToClipboard(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.copy, size: 16, color: Colors.grey[400]),
            ),
          ),
          const SizedBox(width: 8),

          // Reload button
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.refresh, size: 16, color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.content));

    // Show a snackbar to confirm copy
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Message copied to clipboard',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: Colors.grey[800],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}

class CodeElementBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final code = element.textContent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: HighlightView(
        code,
        language: 'dart', // You can make this dynamic if needed
        theme: monokaiSublimeTheme,
        textStyle: TextStyle(
          fontFamily: GoogleFonts.firaCode().fontFamily,
          fontSize: 14,
        ),
      ),
    );
  }
}
