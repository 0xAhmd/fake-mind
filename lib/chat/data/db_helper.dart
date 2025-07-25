import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../data/model/chat_model.dart';
import '../data/model/message_model.dart';

class DatabaseHelper {
  static const _databaseName = "chat_database.db";
  static const _databaseVersion = 2; // Increased version for new features

  static const tableChats = 'chats';
  static const tableMessages = 'messages';

  // Chat table columns
  static const columnChatId = 'id';
  static const columnChatTitle = 'title';
  static const columnChatCreatedAt = 'created_at';
  static const columnChatUpdatedAt = 'updated_at';
  static const columnChatIsPinned = 'is_pinned'; // New field
  static const columnChatLastMessage = 'last_message'; // New field

  // Messages table columns
  static const columnMessageId = 'id';
  static const columnMessageChatId = 'chat_id';
  static const columnMessageContent = 'content';
  static const columnMessageIsUser = 'is_user';
  static const columnMessageTimestamp = 'timestamp';
  static const columnMessageSynced = 'synced';
  static const columnMessageRetryCount = 'retry_count'; // New field
  static const columnMessageMessageType =
      'message_type'; // New field (text, image, etc.)

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableChats (
        $columnChatId TEXT PRIMARY KEY,
        $columnChatTitle TEXT NOT NULL,
        $columnChatCreatedAt TEXT NOT NULL,
        $columnChatUpdatedAt TEXT NOT NULL,
        $columnChatIsPinned INTEGER NOT NULL DEFAULT 0,
        $columnChatLastMessage TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableMessages (
        $columnMessageId TEXT PRIMARY KEY,
        $columnMessageChatId TEXT NOT NULL,
        $columnMessageContent TEXT NOT NULL,
        $columnMessageIsUser INTEGER NOT NULL,
        $columnMessageTimestamp TEXT NOT NULL,
        $columnMessageSynced INTEGER NOT NULL DEFAULT 0,
        $columnMessageRetryCount INTEGER NOT NULL DEFAULT 0,
        $columnMessageMessageType TEXT NOT NULL DEFAULT 'text',
        FOREIGN KEY ($columnMessageChatId) REFERENCES $tableChats ($columnChatId) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute('''
      CREATE INDEX idx_messages_chat_id ON $tableMessages($columnMessageChatId)
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_timestamp ON $tableMessages($columnMessageTimestamp)
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_synced ON $tableMessages($columnMessageSynced)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns to existing tables
      await db.execute(
        'ALTER TABLE $tableChats ADD COLUMN $columnChatIsPinned INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE $tableChats ADD COLUMN $columnChatLastMessage TEXT',
      );
      await db.execute(
        'ALTER TABLE $tableMessages ADD COLUMN $columnMessageRetryCount INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE $tableMessages ADD COLUMN $columnMessageMessageType TEXT NOT NULL DEFAULT \'text\'',
      );

      // Create indexes
      await db.execute(
        'CREATE INDEX idx_messages_chat_id ON $tableMessages($columnMessageChatId)',
      );
      await db.execute(
        'CREATE INDEX idx_messages_timestamp ON $tableMessages($columnMessageTimestamp)',
      );
      await db.execute(
        'CREATE INDEX idx_messages_synced ON $tableMessages($columnMessageSynced)',
      );
    }
  }

  // Enhanced Chat operations
  Future<String> insertChat(ChatModel chat) async {
    try {
      Database db = await database;
      await db.insert(
        tableChats,
        chat.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return chat.id;
    } catch (e) {
      debugPrint('Error inserting chat: $e');
      rethrow;
    }
  }

  Future<List<ChatModel>> getAllChats() async {
    try {
      Database db = await database;
      List<Map<String, dynamic>> maps = await db.query(
        tableChats,
        orderBy: '$columnChatIsPinned DESC, $columnChatUpdatedAt DESC',
      );
      return List.generate(maps.length, (i) => ChatModel.fromMap(maps[i]));
    } catch (e) {
      debugPrint('Error getting all chats: $e');
      return [];
    }
  }

  Future<ChatModel?> getChat(String chatId) async {
    try {
      Database db = await database;
      List<Map<String, dynamic>> maps = await db.query(
        tableChats,
        where: '$columnChatId = ?',
        whereArgs: [chatId],
      );
      if (maps.isNotEmpty) {
        return ChatModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting chat: $e');
      return null;
    }
  }

  Future<void> updateChat(ChatModel chat) async {
    try {
      debugPrint('🔄 DatabaseHelper.updateChat called for: ${chat.id}');
      debugPrint('📄 Chat data: ${chat.toMap()}');

      Database db = await database;

      final result = await db.update(
        tableChats,
        chat.toMap(),
        where: '$columnChatId = ?',
        whereArgs: [chat.id],
      );

      debugPrint('✅ Database update result: $result rows affected');

      if (result == 0) {
        debugPrint('⚠️ No rows were updated - chat might not exist');
        // Optionally insert if update failed
        await db.insert(
          tableChats,
          chat.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        debugPrint('✅ Chat inserted instead of updated');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error updating chat in database: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> pinChat(String chatId, bool isPinned) async {
    try {
      Database db = await database;
      await db.update(
        tableChats,
        {columnChatIsPinned: isPinned ? 1 : 0},
        where: '$columnChatId = ?',
        whereArgs: [chatId],
      );
    } catch (e) {
      debugPrint('Error pinning chat: $e');
      rethrow;
    }
  }

  Future<void> updateChatLastMessage(String chatId, String lastMessage) async {
    try {
      Database db = await database;
      await db.update(
        tableChats,
        {
          columnChatLastMessage: lastMessage,
          columnChatUpdatedAt: DateTime.now().toIso8601String(),
        },
        where: '$columnChatId = ?',
        whereArgs: [chatId],
      );
    } catch (e) {
      debugPrint('Error updating last message: $e');
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      Database db = await database;
      await db.transaction((txn) async {
        // Delete messages first
        await txn.delete(
          tableMessages,
          where: '$columnMessageChatId = ?',
          whereArgs: [chatId],
        );
        // Then delete chat
        await txn.delete(
          tableChats,
          where: '$columnChatId = ?',
          whereArgs: [chatId],
        );
      });
    } catch (e) {
      debugPrint('Error deleting chat: $e');
      rethrow;
    }
  }

  // Enhanced Message operations
  Future<String> insertMessage(MessageModel message) async {
    try {
      Database db = await database;
      await db.transaction((txn) async {
        await txn.insert(
          tableMessages,
          message.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Update chat's last message
        await txn.update(
          tableChats,
          {
            columnChatLastMessage:
                message.content.length > 50
                    ? '${message.content.substring(0, 50)}...'
                    : message.content,
            columnChatUpdatedAt: DateTime.now().toIso8601String(),
          },
          where: '$columnChatId = ?',
          whereArgs: [message.chatId],
        );
      });
      return message.id;
    } catch (e) {
      debugPrint('Error inserting message: $e');
      rethrow;
    }
  }

  Future<List<MessageModel>> getMessagesForChat(
    String chatId, {
    int? limit,
    int? offset,
  }) async {
    try {
      Database db = await database;
      List<Map<String, dynamic>> maps = await db.query(
        tableMessages,
        where: '$columnMessageChatId = ?',
        whereArgs: [chatId],
        orderBy: '$columnMessageTimestamp DESC',
        limit: limit,
        offset: offset,
      );
      return List.generate(
        maps.length,
        (i) => MessageModel.fromMap(maps[i]),
      ).reversed.toList(); // Reverse to get chronological order
    } catch (e) {
      debugPrint('Error getting messages for chat: $e');
      return [];
    }
  }

  Future<List<MessageModel>> getUnsyncedMessages() async {
    try {
      Database db = await database;
      List<Map<String, dynamic>> maps = await db.query(
        tableMessages,
        where: '$columnMessageSynced = ?',
        whereArgs: [0],
        orderBy: '$columnMessageTimestamp ASC',
      );
      return List.generate(maps.length, (i) => MessageModel.fromMap(maps[i]));
    } catch (e) {
      debugPrint('Error getting unsynced messages: $e');
      return [];
    }
  }

  Future<List<MessageModel>> getFailedMessages() async {
    try {
      Database db = await database;
      List<Map<String, dynamic>> maps = await db.query(
        tableMessages,
        where: '$columnMessageSynced = ? AND $columnMessageRetryCount > ?',
        whereArgs: [0, 0],
        orderBy: '$columnMessageTimestamp ASC',
      );
      return List.generate(maps.length, (i) => MessageModel.fromMap(maps[i]));
    } catch (e) {
      debugPrint('Error getting failed messages: $e');
      return [];
    }
  }

  Future<void> markMessageAsSynced(String messageId) async {
    try {
      Database db = await database;
      await db.update(
        tableMessages,
        {columnMessageSynced: 1},
        where: '$columnMessageId = ?',
        whereArgs: [messageId],
      );
    } catch (e) {
      debugPrint('Error marking message as synced: $e');
      rethrow;
    }
  }

  Future<void> incrementMessageRetryCount(String messageId) async {
    try {
      Database db = await database;
      await db.update(
        tableMessages,
        {columnMessageRetryCount: '$columnMessageRetryCount + 1'},
        where: '$columnMessageId = ?',
        whereArgs: [messageId],
      );
    } catch (e) {
      debugPrint('Error incrementing retry count: $e');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      Database db = await database;
      await db.delete(
        tableMessages,
        where: '$columnMessageId = ?',
        whereArgs: [messageId],
      );
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }

  // Search functionality
  Future<List<ChatModel>> searchChats(String query) async {
    try {
      Database db = await database;
      List<Map<String, dynamic>> maps = await db.query(
        tableChats,
        where: '$columnChatTitle LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: '$columnChatUpdatedAt DESC',
      );
      return List.generate(maps.length, (i) => ChatModel.fromMap(maps[i]));
    } catch (e) {
      debugPrint('Error searching chats: $e');
      return [];
    }
  }

  Future<List<MessageModel>> searchMessages(
    String query, {
    String? chatId,
  }) async {
    try {
      Database db = await database;
      String whereClause = '$columnMessageContent LIKE ?';
      List<String> whereArgs = ['%$query%'];

      if (chatId != null) {
        whereClause += ' AND $columnMessageChatId = ?';
        whereArgs.add(chatId);
      }

      List<Map<String, dynamic>> maps = await db.query(
        tableMessages,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: '$columnMessageTimestamp DESC',
      );
      return List.generate(maps.length, (i) => MessageModel.fromMap(maps[i]));
    } catch (e) {
      debugPrint('Error searching messages: $e');
      return [];
    }
  }

  // Analytics
  Future<Map<String, dynamic>> getChatStatistics() async {
    try {
      Database db = await database;

      final chatCount =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $tableChats'),
          ) ??
          0;

      final messageCount =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $tableMessages'),
          ) ??
          0;

      final userMessageCount =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM $tableMessages WHERE $columnMessageIsUser = 1',
            ),
          ) ??
          0;

      final unsyncedCount =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM $tableMessages WHERE $columnMessageSynced = 0',
            ),
          ) ??
          0;

      return {
        'chatCount': chatCount,
        'messageCount': messageCount,
        'userMessageCount': userMessageCount,
        'botMessageCount': messageCount - userMessageCount,
        'unsyncedCount': unsyncedCount,
      };
    } catch (e) {
      debugPrint('Error getting statistics: $e');
      return {
        'chatCount': 0,
        'messageCount': 0,
        'userMessageCount': 0,
        'botMessageCount': 0,
        'unsyncedCount': 0,
      };
    }
  }

  // Maintenance operations
  Future<void> clearDatabase() async {
    try {
      Database db = await database;
      await db.transaction((txn) async {
        await txn.delete(tableMessages);
        await txn.delete(tableChats);
      });
    } catch (e) {
      debugPrint('Error clearing database: $e');
      rethrow;
    }
  }

  Future<void> deleteOldMessages({int daysOld = 30}) async {
    try {
      Database db = await database;
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      await db.delete(
        tableMessages,
        where: '$columnMessageTimestamp < ?',
        whereArgs: [cutoffDate.toIso8601String()],
      );
    } catch (e) {
      debugPrint('Error deleting old messages: $e');
      rethrow;
    }
  }

  Future<int> getDatabaseSize() async {
    try {
      String path = join(await getDatabasesPath(), _databaseName);
      final file = await File(path).stat();
      return file.size;
    } catch (e) {
      debugPrint('Error getting database size: $e');
      return 0;
    }
  }

  Future<void> updateMessage(MessageModel message) async {
    final db = await database;
    await db.update(
      'messages',
      message.toMap(),
      where: 'id = ?',
      whereArgs: [message.id],
    );
    debugPrint('✅ Updated message: ${message.id}');
  }

  /// Gets a specific message by ID
  Future<MessageModel?> getMessage(String messageId) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'id = ?',
      whereArgs: [messageId],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return MessageModel.fromMap(result.first);
    }
    return null;
  }

  
}
