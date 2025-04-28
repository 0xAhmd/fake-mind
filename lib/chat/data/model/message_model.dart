class MessageModel {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  MessageModel({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}
