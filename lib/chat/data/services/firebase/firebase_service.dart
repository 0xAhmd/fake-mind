import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_mind/chat/data/model/chat_model.dart';
import 'package:fake_mind/chat/data/model/message_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Authentication
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      print('Error signing in anonymously: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Chat operations
  Future<void> syncChat(ChatModel chat) async {
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('chats')
          .doc(chat.id)
          .set(chat.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Error syncing chat: $e');
      throw Exception('Failed to sync chat');
    }
  }

  Future<List<ChatModel>> getChatsFromFirestore() async {
    if (currentUserId == null) return [];

    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('chats')
              .orderBy('updated_at', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => ChatModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting chats from Firestore: $e');
      return [];
    }
  }

  Future<void> deleteChat(String chatId) async {
    if (currentUserId == null) return;

    try {
      // Delete all messages in the chat
      QuerySnapshot messagesSnapshot =
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .get();

      for (QueryDocumentSnapshot doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the chat
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('chats')
          .doc(chatId)
          .delete();
    } catch (e) {
      print('Error deleting chat from Firestore: $e');
      throw Exception('Failed to delete chat');
    }
  }

  // Message operations
  Future<void> syncMessage(MessageModel message) async {
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('chats')
          .doc(message.chatId)
          .collection('messages')
          .doc(message.id)
          .set(message.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Error syncing message: $e');
      throw Exception('Failed to sync message');
    }
  }

  Future<List<MessageModel>> getMessagesFromFirestore(String chatId) async {
    if (currentUserId == null) return [];

    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .orderBy('timestamp', descending: false)
              .get();

      return snapshot.docs
          .map(
            (doc) => MessageModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('Error getting messages from Firestore: $e');
      return [];
    }
  }

  // Sync operations
  Future<void> syncUnsyncedData(
    List<ChatModel> chats,
    List<MessageModel> messages,
  ) async {
    if (currentUserId == null) return;

    try {
      // Sync chats
      for (ChatModel chat in chats) {
        await syncChat(chat);
      }

      // Sync messages
      for (MessageModel message in messages) {
        await syncMessage(message);
      }
    } catch (e) {
      print('Error syncing unsynced data: $e');
      throw Exception('Failed to sync data');
    }
  }

  // Listen to real-time updates
  Stream<List<ChatModel>> getChatStream() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('chats')
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ChatModel.fromMap(doc.data()))
                  .toList(),
        );
  }

  Stream<List<MessageModel>> getMessageStream(String chatId) {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => MessageModel.fromMap(doc.data()))
                  .toList(),
        );
  }
}
