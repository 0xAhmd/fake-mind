import 'package:uuid/uuid.dart';

class ChatModel {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final String? lastMessage;

  ChatModel({
    String? id,
    required this.title,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isPinned = false,
    this.lastMessage,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_pinned': isPinned ? 1 : 0,
      'last_message': lastMessage,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      id: map['id'],
      title: map['title'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isPinned: (map['is_pinned'] ?? 0) == 1,
      lastMessage: map['last_message'],
    );
  }

  // Add this method to your ChatModel class

  ChatModel copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    String? lastMessage,
  }) {
    return ChatModel(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatModel{id: $id, title: $title, isPinned: $isPinned}';
  }
}
