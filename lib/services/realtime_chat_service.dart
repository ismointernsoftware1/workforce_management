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

      // Create conversation with per-user unread counts
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
        'unreadCounts': {
          userId1: 0,
          userId2: 0,
        },
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

      // Initialize unread counts for all members
      final initialUnreadCounts = <String, int>{};
      for (final memberId in memberIds) {
        initialUnreadCounts[memberId] = 0;
      }
      
      await _database.child('conversations').child(conversationId).set({
        'type': ConversationType.group.name,
        'name': groupName,
        'memberIds': memberIds,
        'memberNames': memberNames,
        'lastMessage': '',
        'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
        'unreadCounts': initialUnreadCounts,
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

      // Get conversation to update unread counts
      final conversationRef = _database.child('conversations').child(conversationId);
      final conversationSnapshot = await conversationRef.get();
      
      if (conversationSnapshot.exists) {
        final conversationData = conversationSnapshot.value as Map<dynamic, dynamic>;
        final memberIds = (conversationData['memberIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
        
        // Increment unread count for all members except the sender
        // Note: In production, you'd track unread counts per user
        final updates = <String, dynamic>{
          'lastMessage': message.text,
          'lastMessageTime': message.timestamp,
        };
        
        // Increment unread count for recipients (not sender) - per-user tracking
        final senderId = message.senderId;
        final unreadCounts = (conversationData['unreadCounts'] as Map<dynamic, dynamic>? ?? {})
            .map((key, value) => MapEntry(
              key.toString(),
              (value is int) ? value : (int.tryParse(value.toString()) ?? 0),
            ));
        
        // Increment unread count for each recipient (not sender)
        for (final memberId in memberIds) {
          if (memberId != senderId) {
            final currentCount = unreadCounts[memberId] ?? 0;
            unreadCounts[memberId] = currentCount + 1;
            print('Incremented unread count for user $memberId to ${currentCount + 1}');
          } else {
            // Ensure sender's unread count is 0
            unreadCounts[memberId] = 0;
          }
        }
        
        updates['unreadCounts'] = unreadCounts;
        print('Updated unread counts for conversation $conversationId: $unreadCounts');
        
        await conversationRef.update(updates);
        print('Conversation updated successfully with unread count');
      } else {
        // Fallback: just update last message
        await conversationRef.update({
          'lastMessage': message.text,
          'lastMessageTime': message.timestamp,
        });
      }
    } catch (e) {
      print('Error sending message: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Get conversations stream for a user
  Stream<List<RealtimeChatConversation>> getUserConversationsStream(
    String userId,
  ) {
    try {
      final userConversationsRef =
          _database.child('userConversations').child(userId);
      
      StreamSubscription<DatabaseEvent>? userConversationsSubscription;
      final Map<String, StreamSubscription<DatabaseEvent>> conversationSubscriptions = {};
      late final StreamController<List<RealtimeChatConversation>> controller;
      final Map<String, RealtimeChatConversation> conversationsMap = {};

      void emitConversations() {
        final conversations = conversationsMap.values.toList();
        conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        controller.add(conversations);
      }

      controller = StreamController<List<RealtimeChatConversation>>.broadcast(
        onListen: () {
          // Listen to userConversations to know which conversations to track
          userConversationsSubscription = userConversationsRef.onValue.listen(
            (event) async {
              if (!event.snapshot.exists || event.snapshot.value == null) {
                // Cancel all conversation subscriptions
                for (final sub in conversationSubscriptions.values) {
                  await sub.cancel();
                }
                conversationSubscriptions.clear();
                conversationsMap.clear();
                controller.add([]);
                return;
              }

              final conversationIds = <String>[];
              if (event.snapshot.value is Map) {
                final map = event.snapshot.value as Map;
                conversationIds.addAll(map.keys.map((e) => e.toString()));
              }

              // Cancel subscriptions for conversations that are no longer in the list
              final currentIds = conversationIds.toSet();
              final subscriptionsToRemove = <String>[];
              for (final id in conversationSubscriptions.keys) {
                if (!currentIds.contains(id)) {
                  subscriptionsToRemove.add(id);
                }
              }
              for (final id in subscriptionsToRemove) {
                await conversationSubscriptions[id]?.cancel();
                conversationSubscriptions.remove(id);
                conversationsMap.remove(id);
              }

              // Set up real-time listeners for each conversation
              for (final conversationId in conversationIds) {
                // Skip if we already have a subscription for this conversation
                if (conversationSubscriptions.containsKey(conversationId)) {
                  continue;
                }

                // Set up real-time listener for this conversation
                final conversationRef =
                    _database.child('conversations').child(conversationId);
                
                final subscription = conversationRef.onValue.listen(
                  (conversationEvent) {
                    if (!conversationEvent.snapshot.exists || 
                        conversationEvent.snapshot.value == null) {
                      conversationsMap.remove(conversationId);
                      emitConversations();
                      return;
                    }

                    try {
                      final data = conversationEvent.snapshot.value as Map<dynamic, dynamic>;
                      final conversation = RealtimeChatConversation.fromMap(
                        data,
                        conversationId,
                        currentUserId: userId,
                      );
                      conversationsMap[conversationId] = conversation;
                      emitConversations();
                    } catch (e) {
                      print('Error parsing conversation $conversationId: $e');
                    }
                  },
                  onError: (error) {
                    print('Error listening to conversation $conversationId: $error');
                  },
                );

                conversationSubscriptions[conversationId] = subscription;
              }

              // If no conversations, emit empty list
              if (conversationIds.isEmpty) {
                controller.add([]);
              }
            },
            onError: (error) {
              print('Error in user conversations stream: $error');
              controller.add([]);
            },
          );
        },
        onCancel: () async {
          await userConversationsSubscription?.cancel();
          for (final sub in conversationSubscriptions.values) {
            await sub.cancel();
          }
          conversationSubscriptions.clear();
          conversationsMap.clear();
          if (!controller.isClosed) {
            await controller.close();
          }
        },
      );

      return controller.stream;
    } catch (e) {
      print('Error setting up user conversations stream: $e');
      return Stream.value([]);
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
              RealtimeChatConversation.fromMap(data, conversationId, currentUserId: userId),
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
  //
  // IMPORTANT:
  // We return the Firebase `onValue` stream directly mapped to a list of
  // `RealtimeChatMessage`. This avoids using an intermediate StreamController,
  // which can drop the first event if it fires before any listeners are added,
  // causing the UI's StreamBuilder to stay in a perpetual loading state.
  Stream<List<RealtimeChatMessage>> getMessagesStream(String conversationId) async* {
    try {
      print('Setting up messages stream for conversation: $conversationId');
      final messagesRef = _database
          .child('conversations')
          .child(conversationId)
          .child('messages');

      List<RealtimeChatMessage> _parseSnapshot(DataSnapshot snapshot) {
        if (!snapshot.exists || snapshot.value == null) {
          print('No messages found for conversation: $conversationId');
          return <RealtimeChatMessage>[];
        }
        final data = snapshot.value;
        if (data is! Map) {
          print('Messages data is not a Map: ${data.runtimeType}');
          return <RealtimeChatMessage>[];
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
        print('Parsed ${messages.length} messages for conversation: $conversationId');
        return messages;
      }

      // Emit an initial snapshot immediately so the UI shows previous messages
      try {
        final initial = await messagesRef.orderByChild('timestamp').get()
            .timeout(const Duration(seconds: 10));
        yield _parseSnapshot(initial);
      } catch (e) {
        print('Initial messages fetch failed for $conversationId: $e');
        // Even if initial fetch fails, still start the live stream
        yield <RealtimeChatMessage>[];
      }

      // Then emit live updates
      yield* messagesRef
          .orderByChild('timestamp')
          .onValue
          .map((event) => _parseSnapshot(event.snapshot))
          .handleError((error, stackTrace) {
            print('Error in messages stream for conversation $conversationId: $error');
            print('Error stack trace: $stackTrace');
            return <RealtimeChatMessage>[];
          });
    } catch (e, stackTrace) {
      print('Error setting up messages stream: $e');
      print('Stack trace: $stackTrace');
      yield <RealtimeChatMessage>[];
    }
  }

  // Get conversation stream
  Stream<RealtimeChatConversation?> getConversationStream(
    String conversationId, {
    String? currentUserId,
  }) {
    try {
      final userId = currentUserId; // Capture for use in closure
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
                    RealtimeChatConversation.fromMap(data, conversationId, currentUserId: userId),
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
      // Reset unread count for this specific user when they open the conversation
      final conversationRef = _database.child('conversations').child(conversationId);
      final conversationSnapshot = await conversationRef.get();
      
      if (conversationSnapshot.exists) {
        final conversationData = conversationSnapshot.value as Map<dynamic, dynamic>;
        final unreadCounts = (conversationData['unreadCounts'] as Map<dynamic, dynamic>? ?? {})
            .map((key, value) => MapEntry(
              key.toString(),
              (value is int) ? value : (int.tryParse(value.toString()) ?? 0),
            ));
        
        // Set this user's unread count to 0
        unreadCounts[userId] = 0;
        
        await conversationRef.update({
          'unreadCounts': unreadCounts,
        });
        print('Marked conversation $conversationId as read for user $userId');
      }
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

  // Set typing status
  Future<void> setTyping(
    String conversationId,
    String userId,
    String userName,
    bool isTyping,
  ) async {
    try {
      print('Setting typing status: conversation=$conversationId, user=$userName ($userId), isTyping=$isTyping');
      final typingRef = _database
          .child('conversations')
          .child(conversationId)
          .child('typing')
          .child(userId);

      if (isTyping) {
        await typingRef.set({
          'userId': userId,
          'userName': userName,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        print('Typing status set successfully');
      } else {
        await typingRef.remove();
        print('Typing status cleared successfully');
      }
    } catch (e) {
      print('Error setting typing status: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  // Get typing status stream
  Stream<Map<String, String>> getTypingStream(String conversationId) {
    try {
      final typingRef = _database
          .child('conversations')
          .child(conversationId)
          .child('typing');

      return typingRef.onValue.map((event) {
        print('Typing stream event received for conversation: $conversationId');
        print('Event snapshot exists: ${event.snapshot.exists}');
        
        if (!event.snapshot.exists || event.snapshot.value == null) {
          print('No typing users found');
          return <String, String>{};
        }

        final data = event.snapshot.value;
        print('Typing data type: ${data.runtimeType}');
        
        if (data is! Map) {
          print('Typing data is not a Map');
          return <String, String>{};
        }

        final typingUsers = <String, String>{};

        data.forEach((userId, value) {
          try {
            if (value is Map) {
              final userName = value['userName']?.toString() ?? '';
              if (userName.isNotEmpty) {
                typingUsers[userId.toString()] = userName;
                print('Found typing user: $userName ($userId)');
              }
            }
          } catch (e) {
            print('Error parsing typing user $userId: $e');
          }
        });

        print('Total typing users: ${typingUsers.length}');
        return typingUsers;
      }).handleError((error) {
        print('Error in typing stream: $error');
        return <String, String>{};
      });
    } catch (e) {
      print('Error getting typing stream: $e');
      return Stream.value(<String, String>{});
    }
  }
}

