import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/realtime_chat_models.dart';
import '../models/user_model.dart';

class RealtimeChatService {
  RealtimeChatService({
    DatabaseReference? database,
    FirebaseFirestore? firestore,
  })  : _database = database ?? _getDatabaseRef(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final DatabaseReference _database;
  final FirebaseFirestore _firestore;

  static DatabaseReference _getDatabaseRef() {
    // Set the database URL explicitly
    // Replace with your actual database URL from Firebase Console
    final databaseUrl = 'https://workforce-f9e89-default-rtdb.asia-southeast1.firebasedatabase.app';
    
    // Get the default Firebase app
    final app = Firebase.app();
    
    // Get database instance with the URL
    final database = FirebaseDatabase.instanceFor(
      app: app,
      databaseURL: databaseUrl,
    );
    
    // Enable persistence for offline support (not supported on web)
    if (!kIsWeb) {
      try {
        database.setPersistenceEnabled(true);
      } catch (e) {
        // Ignore errors if persistence is not supported on this platform
        print('Persistence not available: $e');
      }
    }
    
    return database.ref();
  }

  // Get current user ID (you'll need to implement this based on your auth)
  String? getCurrentUserId() {
    // TODO: Get from Firebase Auth or your auth system
    // For now, return null - you'll need to pass userId from controller
    return null;
  }

  // Get users from Firestore
  Future<List<UserModel>> getUsers({String? excludeUserId}) async {
    try {
      print('🔍 Fetching users from Firestore (excluding: $excludeUserId)');
      
      // Get users from Firestore with timeout
      QuerySnapshot snapshot;
      try {
        snapshot = await _firestore
            .collection('users')
            .orderBy('name')
            .get()
            .timeout(const Duration(seconds: 10));
        print('✅ Successfully fetched with orderBy');
      } catch (e) {
        // If orderBy fails (e.g., no index), try without it
        print('⚠️ orderBy failed, trying without: $e');
        try {
          snapshot = await _firestore
              .collection('users')
              .get()
              .timeout(const Duration(seconds: 10));
          print('✅ Successfully fetched without orderBy');
        } catch (e2) {
          print('❌ Error fetching users without orderBy: $e2');
          rethrow;
        }
      }
      
      print('📊 Found ${snapshot.docs.length} documents in Firestore');
      
      final allUsers = <UserModel>[];
      final parseErrors = <String>[];
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            print('⚠️ Document ${doc.id} has null data');
            continue;
          }
          
          // Log the raw data for debugging
          print('📄 User ${doc.id}: ${data.keys.join(", ")}');
          
          final user = UserModel.fromMap(data, id: doc.id);
          
          // Validate required fields
          if (user.name.isEmpty) {
            print('⚠️ User ${doc.id} has empty name, skipping');
            continue;
          }
          
          allUsers.add(user);
        } catch (e, stackTrace) {
          final errorMsg = 'Error parsing user ${doc.id}: $e';
          print('❌ $errorMsg');
          print('Stack trace: $stackTrace');
          parseErrors.add(errorMsg);
        }
      }
      
      print('✅ Successfully parsed ${allUsers.length} users');
      if (parseErrors.isNotEmpty) {
        print('❌ Failed to parse ${parseErrors.length} users');
      }
      
      // Exclude current user
      final filteredUsers = allUsers
          .where((user) => excludeUserId == null || user.id != excludeUserId)
          .toList();
      
      print('👤 After excluding current user: ${filteredUsers.length} users');
      
      // Sort by name
      filteredUsers.sort((a, b) => a.name.compareTo(b.name));
      
      print('✅ Returning ${filteredUsers.length} users from Firestore');
      return filteredUsers;
    } catch (e, stackTrace) {
      print('❌ Error fetching users: $e');
      print('Stack trace: $stackTrace');
      // Return empty list if Firestore fails
      return [];
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, id: doc.id);
      }
      return null;
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  // Create a direct conversation between two users
  Future<String> createDirectConversation(
    String userId1,
    String userId2,
    String userName1,
    String userName2,
  ) async {
    try {
      // Sort user IDs to ensure consistent conversation ID
      final sortedIds = [userId1, userId2]..sort();
      final conversationId = 'direct_${sortedIds[0]}_${sortedIds[1]}';

      // Check if conversation already exists
      final existing = await _database
          .child('conversations')
          .child(conversationId)
          .get();

      if (existing.exists) {
        return conversationId;
      }

      // Create conversation
      await _database.child('conversations').child(conversationId).set({
        'type': ConversationType.direct.name,
        'name': userName2, // For userId1, show userId2's name
        'memberIds': sortedIds,
        'memberNames': {
          userId1: userName1,
          userId2: userName2,
        },
        'lastMessage': '',
        'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
        'unreadCount': 0,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Add conversation reference to each user
      await _database
          .child('userConversations')
          .child(userId1)
          .child(conversationId)
          .set(true);
      await _database
          .child('userConversations')
          .child(userId2)
          .child(conversationId)
          .set(true);

      return conversationId;
    } catch (e) {
      print('Error creating direct conversation: $e');
      rethrow;
    }
  }

  // Create a group conversation
  Future<String> createGroupConversation(
    String groupName,
    String createdBy,
    String createdByName,
    List<String> memberIds,
    Map<String, String> memberNames,
  ) async {
    try {
      final conversationId = _database.child('conversations').push().key!;

      await _database.child('conversations').child(conversationId).set({
        'type': ConversationType.group.name,
        'name': groupName,
        'memberIds': memberIds,
        'memberNames': memberNames,
        'lastMessage': '',
        'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
        'unreadCount': 0,
        'createdBy': createdBy,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Add conversation reference to each member
      for (final memberId in memberIds) {
        await _database
            .child('userConversations')
            .child(memberId)
            .child(conversationId)
            .set(true);
      }

      return conversationId;
    } catch (e) {
      print('Error creating group conversation: $e');
      rethrow;
    }
  }

  // Send a message
  Future<void> sendMessage(
    String conversationId,
    RealtimeChatMessage message,
  ) async {
    try {
      print('Sending message to conversation: $conversationId');
      print('Message text: ${message.text}');
      print('Message sender: ${message.senderName} (${message.senderId})');
      
      final messageRef = _database
          .child('conversations')
          .child(conversationId)
          .child('messages')
          .push();

      final messageData = message.toMap();
      print('Message data to save: $messageData');
      
      await messageRef.set(messageData);
      print('Message sent successfully with key: ${messageRef.key}');

      // Update conversation last message
      await _database.child('conversations').child(conversationId).update({
        'lastMessage': message.text,
        'lastMessageTime': message.timestamp,
      });
      print('Conversation updated successfully');
    } catch (e) {
      print('Error sending message: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Get conversations for a user
  Future<List<RealtimeChatConversation>> getUserConversations(
    String userId,
  ) async {
    try {
      final userConversationsRef =
          _database.child('userConversations').child(userId);
      final snapshot = await userConversationsRef
          .get()
          .timeout(const Duration(seconds: 10));

      if (!snapshot.exists) {
        print('No conversations found for user: $userId');
        return [];
      }

      final conversationIds = <String>[];
      if (snapshot.value is Map) {
        final map = snapshot.value as Map;
        conversationIds.addAll(map.keys.map((e) => e.toString()));
      }

      print('Found ${conversationIds.length} conversation IDs for user: $userId');

      final conversations = <RealtimeChatConversation>[];

      for (final conversationId in conversationIds) {
        try {
          final conversationRef =
              _database.child('conversations').child(conversationId);
          final conversationSnapshot = await conversationRef
              .get()
              .timeout(const Duration(seconds: 5));

          if (conversationSnapshot.exists) {
            final data = conversationSnapshot.value as Map<dynamic, dynamic>;
            conversations.add(
              RealtimeChatConversation.fromMap(data, conversationId),
            );
          }
        } catch (e) {
          print('Error fetching conversation $conversationId: $e');
          // Continue with other conversations
        }
      }

      // Sort by last message time
      conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

      print('Loaded ${conversations.length} conversations for user: $userId');
      return conversations;
    } catch (e) {
      print('Error fetching conversations: $e');
      return [];
    }
  }

  // Get messages for a conversation (stream)
  Stream<List<RealtimeChatMessage>> getMessagesStream(String conversationId) {
    try {
      print('Setting up messages stream for conversation: $conversationId');
      final messagesRef = _database
          .child('conversations')
          .child(conversationId)
          .child('messages');

      StreamSubscription<DatabaseEvent>? subscription;
      late final StreamController<List<RealtimeChatMessage>> controller;

      controller = StreamController<List<RealtimeChatMessage>>.broadcast(
        onListen: () {
          controller.add(<RealtimeChatMessage>[]);
          subscription = messagesRef
              .orderByChild('timestamp')
              .onValue
              .listen(
                (event) {
                  print(
                      'Messages stream event received for conversation: $conversationId');
                  print('Event snapshot exists: ${event.snapshot.exists}');

                  if (!event.snapshot.exists || event.snapshot.value == null) {
                    print('No messages found for conversation: $conversationId');
                    controller.add(<RealtimeChatMessage>[]);
                    return;
                  }

                  final data = event.snapshot.value;
                  print('Received data type: ${data.runtimeType}');

                  if (data is! Map) {
                    print('Messages data is not a Map: ${data.runtimeType}');
                    controller.add(<RealtimeChatMessage>[]);
                    return;
                  }

                  final messages = <RealtimeChatMessage>[];

                  data.forEach((key, value) {
                    try {
                      if (value is Map) {
                        messages.add(
                          RealtimeChatMessage.fromMap(
                            value,
                            key.toString(),
                          ),
                        );
                      }
                    } catch (e) {
                      print('Error parsing message $key: $e');
                    }
                  });

                  messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
                  print(
                      'Parsed ${messages.length} messages for conversation: $conversationId');
                  if (messages.isNotEmpty) {
                    print(
                        'Latest message: ${messages.last.text} from ${messages.last.senderName}');
                  }
                  controller.add(messages);
                },
                onError: (error) {
                  print(
                      'Error in messages stream for conversation $conversationId: $error');
                  print('Error stack trace: ${StackTrace.current}');
                  controller.add(<RealtimeChatMessage>[]);
                },
              );
        },
        onCancel: () async {
          print('Cancelling messages stream for conversation: $conversationId');
          await subscription?.cancel();
          subscription = null;
          if (!controller.isClosed) {
            await controller.close();
          }
        },
      );

      return controller.stream;
    } catch (e) {
      print('Error setting up messages stream: $e');
      print('Stack trace: ${StackTrace.current}');
      final errorController =
          StreamController<List<RealtimeChatMessage>>.broadcast();
      errorController.add(<RealtimeChatMessage>[]);
      return errorController.stream;
    }
  }

  // Get conversation stream
  Stream<RealtimeChatConversation?> getConversationStream(
    String conversationId,
  ) {
    try {
      StreamSubscription<DatabaseEvent>? subscription;
      late final StreamController<RealtimeChatConversation?> controller;

      controller = StreamController<RealtimeChatConversation?>.broadcast(
        onListen: () {
          subscription = _database
              .child('conversations')
              .child(conversationId)
              .onValue
              .listen(
                (event) {
                  if (!event.snapshot.exists || event.snapshot.value == null) {
                    controller.add(null);
                    return;
                  }

                  final data = event.snapshot.value as Map<dynamic, dynamic>;
                  controller.add(
                    RealtimeChatConversation.fromMap(data, conversationId),
                  );
                },
                onError: (error) {
                  print('Error getting conversation stream: $error');
                  controller.addError(error);
                },
              );
        },
        onCancel: () async {
          await subscription?.cancel();
          subscription = null;
          if (!controller.isClosed) {
            await controller.close();
          }
        },
      );

      return controller.stream;
    } catch (e) {
      print('Error getting conversation stream: $e');
      return Stream.value(null);
    }
  }

  // Mark conversation as read
  Future<void> markAsRead(String conversationId, String userId) async {
    try {
      // Reset unread count for this user
      // You might want to track per-user unread counts
      await _database
          .child('conversations')
          .child(conversationId)
          .child('unreadCount')
          .set(0);
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  // Update group members
  Future<void> updateGroupMembers(
    String conversationId,
    List<String> memberIds,
    Map<String, String> memberNames,
  ) async {
    try {
      await _database.child('conversations').child(conversationId).update({
        'memberIds': memberIds,
        'memberNames': memberNames,
      });

      // Update user conversation references
      // Remove old members
      final conversationRef =
          _database.child('conversations').child(conversationId);
      final snapshot = await conversationRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final oldMemberIds =
            (data['memberIds'] as List<dynamic>? ?? [])
                .map((e) => e.toString())
                .toList();

        // Remove conversation from users no longer in group
        for (final oldMemberId in oldMemberIds) {
          if (!memberIds.contains(oldMemberId)) {
            await _database
                .child('userConversations')
                .child(oldMemberId)
                .child(conversationId)
                .remove();
          }
        }
      }

      // Add conversation to new members
      for (final memberId in memberIds) {
        await _database
            .child('userConversations')
            .child(memberId)
            .child(conversationId)
            .set(true);
      }
    } catch (e) {
      print('Error updating group members: $e');
      rethrow;
    }
  }
}

