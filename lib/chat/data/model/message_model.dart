import 'package:uuid/uuid.dart';

class MessageModel {
  final String id;
  final String chatId;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool synced;

  MessageModel({
    String? id,
    required this.chatId,
    required this.content,
    required this.isUser,
    DateTime? timestamp,
    this.synced = false,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_id': chatId,
      'content': content,
      'is_user': isUser ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'],
      chatId: map['chat_id'],
      content: map['content'],
      isUser: map['is_user'] == 1,
      timestamp: DateTime.parse(map['timestamp']),
      synced: map['synced'] == 1,
    );
  }

  MessageModel copyWith({String? content, bool? synced}) {
    return MessageModel(
      id: id,
      chatId: chatId,
      content: content ?? this.content,
      isUser: isUser,
      timestamp: timestamp,
      synced: synced ?? this.synced,
    );
  }
}
