import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_mind/chat/data/model/chat_model.dart';
import 'package:fake_mind/chat/data/model/message_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  bool get isAuthenticated => _auth.currentUser != null;

  // Enhanced authentication with better error handling
  Future<UserCredential?> signInAnonymously() async {
    try {
      debugPrint('🔐 Attempting anonymous sign in...');

      // Check if already signed in
      if (_auth.currentUser != null) {
        debugPrint('✅ Already signed in with UID: ${_auth.currentUser!.uid}');
        return null;
      }

      final credential = await _auth.signInAnonymously();
      debugPrint(
        '✅ Anonymous sign in successful. UID: ${credential.user?.uid}',
      );

      // Test Firestore connection immediately after auth
      await _testFirestoreConnection();

      return credential;
    } catch (e) {
      debugPrint('❌ Error signing in anonymously: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Test Firestore connection
  Future<void> _testFirestoreConnection() async {
    try {
      debugPrint('🧪 Testing Firestore connection...');

      if (currentUserId == null) {
        debugPrint('❌ No current user ID for Firestore test');
        return;
      }

      // Try to write a test document
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('test')
          .doc('connection_test')
          .set({'timestamp': FieldValue.serverTimestamp(), 'test': true});

      debugPrint('✅ Firestore connection test successful');

      // Clean up test document
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('test')
          .doc('connection_test')
          .delete();
    } catch (e) {
      debugPrint('❌ Firestore connection test failed: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      debugPrint('🔐 Signing out...');
      await _auth.signOut();
      debugPrint('✅ Sign out successful');
    } catch (e) {
      debugPrint('❌ Error signing out: $e');
    }
  }

  // Enhanced chat operations with detailed logging
  Future<void> syncChat(ChatModel chat) async {
    if (!isAuthenticated) {
      debugPrint('❌ Cannot sync chat: User not authenticated');
      throw Exception('User not authenticated');
    }

    try {
      debugPrint('📤 Syncing chat: ${chat.id} - ${chat.title}');
      debugPrint('🔍 Current user ID: $currentUserId');

      final docRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('chats')
          .doc(chat.id);

      debugPrint('📍 Document path: ${docRef.path}');
      debugPrint('📄 Chat data: ${chat.toMap()}');

      await docRef.set(chat.toMap(), SetOptions(merge: true));

      debugPrint('✅ Chat synced successfully: ${chat.id}');

      // Verify the write by reading it back
      final doc = await docRef.get();
      if (doc.exists) {
        debugPrint('✅ Chat write verified: ${doc.data()}');
      } else {
        debugPrint('❌ Chat write verification failed: Document does not exist');
      }
    } catch (e) {
      debugPrint('❌ Error syncing chat ${chat.id}: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      throw Exception('Failed to sync chat: $e');
    }
  }

  Future<List<ChatModel>> getChatsFromFirestore() async {
    if (!isAuthenticated) {
      debugPrint('❌ Cannot get chats: User not authenticated');
      return [];
    }

    try {
      debugPrint('📥 Getting chats from Firestore for user: $currentUserId');

      final query = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('chats')
          .orderBy('updated_at', descending: true);

      debugPrint('🔍 Query path: ${query.parameters}');

      final snapshot = await query.get();

      debugPrint('📊 Retrieved ${snapshot.docs.length} chats from Firestore');

      final chats =
          snapshot.docs
              .map((doc) {
                try {
                  final data = doc.data();
                  debugPrint('📄 Chat document ${doc.id}: $data');
                  return ChatModel.fromMap(data);
                } catch (e) {
                  debugPrint('❌ Error parsing chat document ${doc.id}: $e');
                  return null;
                }
              })
              .where((chat) => chat != null)
              .cast<ChatModel>()
              .toList();

      // Sort chats: pinned first (by updated_at), then unpinned (by updated_at)
      final pinnedChats = chats.where((chat) => chat.isPinned).toList();
      final unpinnedChats = chats.where((chat) => !chat.isPinned).toList();

      pinnedChats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      unpinnedChats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      final sortedChats = [...pinnedChats, ...unpinnedChats];

      debugPrint(
        '✅ Successfully parsed and sorted ${sortedChats.length} chats',
      );
      return sortedChats;
    } catch (e) {
      debugPrint('❌ Error getting chats from Firestore: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  Future<void> deleteChat(String chatId) async {
    if (!isAuthenticated) {
      debugPrint('❌ Cannot delete chat: User not authenticated');
      return;
    }

    try {
      debugPrint('🗑️ Deleting chat: $chatId');

      // Delete all messages in the chat first
      final messagesQuery = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('chats')
          .doc(chatId)
          .collection('messages');

      final messagesSnapshot = await messagesQuery.get();
      debugPrint(
        '🗑️ Found ${messagesSnapshot.docs.length} messages to delete',
      );

      // Use batch to delete all messages
      final batch = _firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the chat document
      final chatRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('chats')
          .doc(chatId);

      batch.delete(chatRef);

      // Commit the batch
      await batch.commit();

      debugPrint('✅ Chat deleted successfully: $chatId');
    } catch (e) {
      debugPrint('❌ Error deleting chat from Firestore: $e');
      throw Exception('Failed to delete chat: $e');
    }
  }

  // Enhanced message operations
  Future<void> syncMessage(MessageModel message) async {
    if (!isAuthenticated) {
      debugPrint('❌ Cannot sync message: User not authenticated');
      throw Exception('User not authenticated');
    }

    try {
      debugPrint(
        '📤 Syncing message: ${message.id} in chat: ${message.chatId}',
      );

      final docRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('chats')
          .doc(message.chatId)
          .collection('messages')
          .doc(message.id);

      debugPrint('📍 Message document path: ${docRef.path}');
      debugPrint('📄 Message data: ${message.toMap()}');

      await docRef.set(message.toMap(), SetOptions(merge: true));

      debugPrint('✅ Message synced successfully: ${message.id}');

      // Verify the write
      final doc = await docRef.get();
      if (doc.exists) {
        debugPrint('✅ Message write verified');
      } else {
        debugPrint('❌ Message write verification failed');
      }
    } catch (e) {
      debugPrint('❌ Error syncing message ${message.id}: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      throw Exception('Failed to sync message: $e');
    }
  }

  Future<List<MessageModel>> getMessagesFromFirestore(String chatId) async {
    if (!isAuthenticated) {
      debugPrint('❌ Cannot get messages: User not authenticated');
      return [];
    }

    try {
      debugPrint('📥 Getting messages for chat: $chatId');

      final query = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false);

      final snapshot = await query.get();

      debugPrint(
        '📊 Retrieved ${snapshot.docs.length} messages from Firestore',
      );

      final messages =
          snapshot.docs
              .map((doc) {
                try {
                  final data = doc.data();
                  return MessageModel.fromMap(data);
                } catch (e) {
                  debugPrint('❌ Error parsing message document ${doc.id}: $e');
                  return null;
                }
              })
              .where((message) => message != null)
              .cast<MessageModel>()
              .toList();

      debugPrint('✅ Successfully parsed ${messages.length} messages');
      return messages;
    } catch (e) {
      debugPrint('❌ Error getting messages from Firestore: $e');
      return [];
    }
  }

  // Enhanced sync operations with batch processing
  Future<void> syncUnsyncedData(
    List<ChatModel> chats,
    List<MessageModel> messages,
  ) async {
    if (!isAuthenticated) {
      debugPrint('❌ Cannot sync unsynced data: User not authenticated');
      throw Exception('User not authenticated');
    }

    try {
      debugPrint(
        '🔄 Syncing ${chats.length} chats and ${messages.length} messages',
      );

      // Use batch for better performance and atomicity
      final batch = _firestore.batch();
      int operationCount = 0;

      // Sync chats
      for (final chat in chats) {
        if (operationCount >= 500) {
          // Firestore batch limit is 500 operations
          await batch.commit();
          operationCount = 0;
        }

        final chatRef = _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('chats')
            .doc(chat.id);

        batch.set(chatRef, chat.toMap(), SetOptions(merge: true));
        operationCount++;
      }

      // Sync messages
      for (final message in messages) {
        if (operationCount >= 500) {
          await batch.commit();
          operationCount = 0;
        }

        final messageRef = _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('chats')
            .doc(message.chatId)
            .collection('messages')
            .doc(message.id);

        batch.set(messageRef, message.toMap(), SetOptions(merge: true));
        operationCount++;
      }

      // Commit remaining operations
      if (operationCount > 0) {
        await batch.commit();
      }

      debugPrint('✅ Successfully synced all unsynced data');
    } catch (e) {
      debugPrint('❌ Error syncing unsynced data: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      throw Exception('Failed to sync data: $e');
    }
  }

  // Enhanced real-time streams with error handling
  Stream<List<ChatModel>> getChatStream() {
    if (!isAuthenticated) {
      debugPrint('❌ Cannot get chat stream: User not authenticated');
      return Stream.value([]);
    }

    debugPrint('📡 Setting up chat stream for user: $currentUserId');

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('chats')
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint('📡 Chat stream update: ${snapshot.docs.length} chats');

          return snapshot.docs
              .map((doc) {
                try {
                  return ChatModel.fromMap(doc.data());
                } catch (e) {
                  debugPrint('❌ Error parsing chat in stream: $e');
                  return null;
                }
              })
              .where((chat) => chat != null)
              .cast<ChatModel>()
              .toList();
        })
        .handleError((error) {
          debugPrint('❌ Error in chat stream: $error');
        });
  }

  Stream<List<MessageModel>> getMessageStream(String chatId) {
    if (!isAuthenticated) {
      debugPrint('❌ Cannot get message stream: User not authenticated');
      return Stream.value([]);
    }

    debugPrint('📡 Setting up message stream for chat: $chatId');

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          debugPrint(
            '📡 Message stream update: ${snapshot.docs.length} messages',
          );

          return snapshot.docs
              .map((doc) {
                try {
                  return MessageModel.fromMap(doc.data());
                } catch (e) {
                  debugPrint('❌ Error parsing message in stream: $e');
                  return null;
                }
              })
              .where((message) => message != null)
              .cast<MessageModel>()
              .toList();
        })
        .handleError((error) {
          debugPrint('❌ Error in message stream: $error');
        });
  }

  // Debug methods
  Future<void> debugFirestoreRules() async {
    if (!isAuthenticated) {
      debugPrint('❌ Cannot test rules: User not authenticated');
      return;
    }

    try {
      debugPrint('🧪 Testing Firestore security rules...');

      // Test read access
      final testRead =
          await _firestore.collection('users').doc(currentUserId).get();

      debugPrint(
        '✅ Read access: ${testRead.exists ? 'SUCCESS' : 'DOCUMENT_NOT_EXISTS'}',
      );

      // Test write access
      await _firestore.collection('users').doc(currentUserId).set({
        'test': 'rule_test',
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Write access: SUCCESS');
    } catch (e) {
      debugPrint('❌ Firestore rules test failed: $e');
      debugPrint('This might indicate a security rules issue');
    }
  }

  Future<Map<String, dynamic>> getDebugInfo() async {
    return {
      'isAuthenticated': isAuthenticated,
      'currentUserId': currentUserId,
      'authState': _auth.currentUser?.toString(),
      'firestoreSettings': _firestore.settings.toString(),
    };
  }
}
