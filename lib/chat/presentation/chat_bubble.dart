// ignore_for_file: deprecated_member_use
import 'package:markdown/markdown.dart' as md;
import 'package:fake_mind/chat/data/model/message_model.dart';
import 'package:fake_mind/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final MessageModel message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13.0, horizontal: 17.0),
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: message.isUser ? kChatBubbleUser : kChatBubbleBot,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: MarkdownBody(
          data: message.content,
          selectable: true,
          builders: {
            'code': CodeElementBuilder(),
          },
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
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
            code: const TextStyle(), // disable default style, we'll replace it
            codeblockPadding: const EdgeInsets.all(0),
            codeblockDecoration: const BoxDecoration(),
          ),
        ),
      ),
    );
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
