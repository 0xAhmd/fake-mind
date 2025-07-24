import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../data/model/chat_model.dart';
import '../data/model/message_model.dart';

class DatabaseHelper {
  static const _databaseName = "chat_database.db";
  static const _databaseVersion = 1;

  static const tableChats = 'chats';
  static const tableMessages = 'messages';

  // Chat table columns
  static const columnChatId = 'id';
  static const columnChatTitle = 'title';
  static const columnChatCreatedAt = 'created_at';
  static const columnChatUpdatedAt = 'updated_at';

  // Messages table columns
  static const columnMessageId = 'id';
  static const columnMessageChatId = 'chat_id';
  static const columnMessageContent = 'content';
  static const columnMessageIsUser = 'is_user';
  static const columnMessageTimestamp = 'timestamp';
  static const columnMessageSynced = 'synced';

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
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableChats (
        $columnChatId TEXT PRIMARY KEY,
        $columnChatTitle TEXT NOT NULL,
        $columnChatCreatedAt TEXT NOT NULL,
        $columnChatUpdatedAt TEXT NOT NULL
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
        FOREIGN KEY ($columnMessageChatId) REFERENCES $tableChats ($columnChatId) ON DELETE CASCADE
      )
    ''');
  }

  // Chat operations
  Future<String> insertChat(ChatModel chat) async {
    Database db = await database;
    await db.insert(tableChats, chat.toMap());
    return chat.id;
  }

  Future<List<ChatModel>> getAllChats() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableChats,
      orderBy: '$columnChatUpdatedAt DESC',
    );
    return List.generate(maps.length, (i) => ChatModel.fromMap(maps[i]));
  }

  Future<ChatModel?> getChat(String chatId) async {
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
  }

  Future<void> updateChat(ChatModel chat) async {
    Database db = await database;
    await db.update(
      tableChats,
      chat.toMap(),
      where: '$columnChatId = ?',
      whereArgs: [chat.id],
    );
  }

  Future<void> deleteChat(String chatId) async {
    Database db = await database;
    await db.delete(
      tableChats,
      where: '$columnChatId = ?',
      whereArgs: [chatId],
    );
  }

  // Message operations
  Future<String> insertMessage(MessageModel message) async {
    Database db = await database;
    await db.insert(tableMessages, message.toMap());
    return message.id;
  }

  Future<List<MessageModel>> getMessagesForChat(String chatId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableMessages,
      where: '$columnMessageChatId = ?',
      whereArgs: [chatId],
      orderBy: '$columnMessageTimestamp ASC',
    );
    return List.generate(maps.length, (i) => MessageModel.fromMap(maps[i]));
  }

  Future<List<MessageModel>> getUnsyncedMessages() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableMessages,
      where: '$columnMessageSynced = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => MessageModel.fromMap(maps[i]));
  }

  Future<void> markMessageAsSynced(String messageId) async {
    Database db = await database;
    await db.update(
      tableMessages,
      {columnMessageSynced: 1},
      where: '$columnMessageId = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> deleteMessage(String messageId) async {
    Database db = await database;
    await db.delete(
      tableMessages,
      where: '$columnMessageId = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> clearDatabase() async {
    Database db = await database;
    await db.delete(tableChats);
    await db.delete(tableMessages);
  }
}
