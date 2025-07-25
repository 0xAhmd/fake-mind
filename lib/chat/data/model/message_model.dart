import 'package:uuid/uuid.dart';

enum MessageType { text, image, file, system }

class MessageModel {
  final String id;
  final String chatId;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool synced;
  final int retryCount;
  final MessageType messageType;

  MessageModel({
    String? id,
    required this.chatId,
    required this.content,
    required this.isUser,
    DateTime? timestamp,
    this.synced = false,
    this.retryCount = 0,
    this.messageType = MessageType.text,
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
      'retry_count': retryCount,
      'message_type': messageType.name,
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
      retryCount: map['retry_count'] ?? 0,
      messageType: MessageType.values.firstWhere(
        (type) => type.name == (map['message_type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
    );
  }
  // Add this copyWith method to your MessageModel class

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    bool? synced,
    int? retryCount,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      synced: synced ?? this.synced,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  bool get isFailed => !synced && retryCount > 0;
  bool get isRetrying => retryCount > 0 && retryCount < 3;
  bool get hasMaxRetries => retryCount >= 3;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MessageModel{id: $id, isUser: $isUser, synced: $synced, retryCount: $retryCount}';
  }
}
