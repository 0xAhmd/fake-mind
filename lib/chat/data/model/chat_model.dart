// lib/chat/data/model/chat_model.dart
import 'package:uuid/uuid.dart';

class ChatModel {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatModel({
    String? id,
    required this.title,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      id: map['id'],
      title: map['title'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  ChatModel copyWith({
    String? title,
    DateTime? updatedAt,
  }) {
    return ChatModel(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// lib/chat/data/model/message_model.dart - Updated
