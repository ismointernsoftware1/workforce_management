import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../controllers/realtime_chat_controller.dart';
import '../models/realtime_chat_models.dart';
import '../models/user_model.dart';

enum ChatTab { inbox, explore }

class RealtimeChatProvider extends ChangeNotifier {
  RealtimeChatProvider({
    required RealtimeChatController controller,
  }) : _controller = controller;

  final RealtimeChatController _controller;

  bool _isLoading = false;
  ChatTab _activeTab = ChatTab.inbox;
  String? _selectedConversationId;
  RealtimeChatConversation? _selectedConversation;
  List<RealtimeChatConversation> _allConversations = [];
  Stream<List<RealtimeChatMessage>>? _messagesStream;
  StreamSubscription<RealtimeChatConversation?>? _conversationSubscription;
  StreamSubscription<Map<String, String>>? _typingSubscription;
  StreamSubscription<List<RealtimeChatConversation>>? _conversationsStreamSubscription;
  StreamSubscription<List<RealtimeChatMessage>>? _messagesStreamSubscription;
  Map<String, String> _typingUsers = {}; // For selected conversation
  Map<String, Map<String, String>> _allConversationsTyping = {}; // For all conversations
  Map<String, StreamSubscription<Map<String, String>>> _typingSubscriptions = {}; // Track subscriptions

  bool get isLoading => _isLoading;
  ChatTab get activeTab => _activeTab;
  String? get selectedConversationId => _selectedConversationId;
  RealtimeChatConversation? get selectedConversation => _selectedConversation;
  Stream<List<RealtimeChatMessage>> get messagesStream {
    if (_messagesStream == null) {
      return Stream<List<RealtimeChatMessage>>.value(const <RealtimeChatMessage>[]);
    }
    return _messagesStream!;
  }

  String get currentUserId => _controller.currentUserId;

  List<RealtimeChatConversation> get directConversations =>
      _allConversations.where((c) => c.type == ConversationType.direct).toList();

  List<RealtimeChatConversation> get groupConversations =>
      _allConversations.where((c) => c.type == ConversationType.group).toList();

  String conversationTitle(RealtimeChatConversation conversation) {
    if (conversation.type == ConversationType.direct) {
      final otherId = conversation.memberIds
          .firstWhere((id) => id != currentUserId, orElse: () => currentUserId);
      return conversation.memberNames[otherId] ?? conversation.name;
    }
    return conversation.name;
  }

  String get selectedConversationTitle {
    final conversation = _selectedConversation;
    if (conversation == null) return '';
    return conversationTitle(conversation);
  }

  Map<String, String> get typingUsers => _typingUsers;
  
  // Get typing users for a specific conversation
  Map<String, String> getTypingUsersForConversation(String conversationId) {
    return _allConversationsTyping[conversationId] ?? {};
  }

  void setActiveTab(ChatTab tab) {
    if (_activeTab != tab) {
      _activeTab = tab;
      notifyListeners();
    }
  }

  Future<void> loadConversations() async {
    _isLoading = true;
    notifyListeners();

    try {
      final conversations = await _controller.getUserConversations();
      // Update unread counts for current user
      _allConversations = conversations.map((c) {
        return RealtimeChatConversation(
          id: c.id,
          type: c.type,
          name: c.name,
          lastMessage: c.lastMessage,
          lastMessageTime: c.lastMessageTime,
          memberIds: c.memberIds,
          memberNames: c.memberNames,
          unreadCounts: c.unreadCounts,
          unreadCount: c.getUnreadCountForUser(currentUserId),
          createdBy: c.createdBy,
          createdAt: c.createdAt,
        );
      }).toList();
      _isLoading = false;
      
      // Setup real-time listener for conversations
      _setupConversationsStream();
      // Do not auto-select any conversation; wait for user to choose
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setupConversationsStream() {
    // Cancel existing subscription
    _conversationsStreamSubscription?.cancel();
    
    // Listen to all user conversations in real-time
    _conversationsStreamSubscription = _controller
        .getUserConversationsStream()
        .listen(
          (conversations) {
            try {
              // Update conversations list with correct unread counts for current user
              _allConversations = conversations.map((c) {
                return RealtimeChatConversation(
                  id: c.id,
                  type: c.type,
                  name: c.name,
                  lastMessage: c.lastMessage,
                  lastMessageTime: c.lastMessageTime,
                  memberIds: c.memberIds,
                  memberNames: c.memberNames,
                  unreadCounts: c.unreadCounts,
                  unreadCount: c.getUnreadCountForUser(currentUserId),
                  createdBy: c.createdBy,
                  createdAt: c.createdAt,
                );
              }).toList();
              
              // Update selected conversation if it exists
              if (_selectedConversationId != null) {
                try {
                  final updatedConversation = _allConversations.firstWhere(
                    (c) => c.id == _selectedConversationId,
                    orElse: () => _selectedConversation!,
                  );
                  if (updatedConversation.id == _selectedConversationId) {
                    _selectedConversation = updatedConversation;
                  }
                } catch (e) {
                  debugPrint('Error updating selected conversation: $e');
                }
              }
              
              // Set up typing listeners for all conversations (with debounce to avoid excessive calls)
              Future.microtask(() {
                _setupTypingListenersForAllConversations();
              });
              
              notifyListeners();
            } catch (e) {
              debugPrint('Error processing conversations stream: $e');
            }
          },
          onError: (error) {
            debugPrint('Error in conversations stream: $error');
            _isLoading = false;
            notifyListeners();
          },
          cancelOnError: false,
        );
  }

  bool _isSettingUpTypingListeners = false;
  
  // Set up typing listeners for all conversations
  void _setupTypingListenersForAllConversations() {
    // Prevent recursive calls
    if (_isSettingUpTypingListeners) {
      debugPrint('Already setting up typing listeners, skipping...');
      return;
    }
    
    _isSettingUpTypingListeners = true;
    
    try {
      final currentConversationIds = _allConversations.map((c) => c.id).toSet();
      
      // Cancel subscriptions for conversations that no longer exist
      final subscriptionsToRemove = <String>[];
      for (final conversationId in _typingSubscriptions.keys) {
        if (!currentConversationIds.contains(conversationId)) {
          _typingSubscriptions[conversationId]?.cancel();
          subscriptionsToRemove.add(conversationId);
          _allConversationsTyping.remove(conversationId);
        }
      }
      for (final id in subscriptionsToRemove) {
        _typingSubscriptions.remove(id);
      }
      
      // Set up new subscriptions for conversations we don't have yet
      for (final conversation in _allConversations) {
        if (!_typingSubscriptions.containsKey(conversation.id)) {
          final subscription = _controller
              .getTypingStream(conversation.id)
              .listen(
                (typingUsers) {
                  // Filter out current user
                  final filteredUsers = Map<String, String>.from(typingUsers)
                    ..removeWhere((userId, _) => userId == currentUserId);
                  
                  if (filteredUsers.isEmpty) {
                    _allConversationsTyping.remove(conversation.id);
                  } else {
                    _allConversationsTyping[conversation.id] = filteredUsers;
                  }
                  notifyListeners();
                },
                onError: (error) {
                  debugPrint('Error in typing stream for conversation ${conversation.id}: $error');
                  _allConversationsTyping.remove(conversation.id);
                  notifyListeners();
                },
              );
          _typingSubscriptions[conversation.id] = subscription;
        }
      }
    } finally {
      _isSettingUpTypingListeners = false;
    }
  }

  // Load conversations without triggering during build
  void scheduleLoadConversations() {
    // Use a delayed future to avoid blocking the UI thread
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_isLoading) {
        loadConversations();
      }
    });
  }

  void selectConversation(String conversationId) {
    if (_selectedConversationId == conversationId) return;

    // Clear typing status for previous conversation
    if (_selectedConversationId != null) {
      setTyping(false);
    }

    _selectedConversationId = conversationId;
    _conversationSubscription?.cancel();
    _typingUsers = {}; // Clear typing users when switching conversations

    // Listen to conversation updates
    _conversationSubscription = _controller
        .getConversationStream(conversationId)
        .listen((conversation) {
      if (conversation != null) {
        // Ensure unread count is calculated for current user
        _selectedConversation = RealtimeChatConversation(
          id: conversation.id,
          type: conversation.type,
          name: conversation.name,
          lastMessage: conversation.lastMessage,
          lastMessageTime: conversation.lastMessageTime,
          memberIds: conversation.memberIds,
          memberNames: conversation.memberNames,
          unreadCounts: conversation.unreadCounts,
          unreadCount: conversation.getUnreadCountForUser(currentUserId),
          createdBy: conversation.createdBy,
          createdAt: conversation.createdAt,
        );
      } else {
        _selectedConversation = null;
      }
      notifyListeners();

      // Update in all conversations list
      final index = _allConversations.indexWhere((c) => c.id == conversationId);
      if (index != -1 && conversation != null) {
        _allConversations[index] = RealtimeChatConversation(
          id: conversation.id,
          type: conversation.type,
          name: conversation.name,
          lastMessage: conversation.lastMessage,
          lastMessageTime: conversation.lastMessageTime,
          memberIds: conversation.memberIds,
          memberNames: conversation.memberNames,
          unreadCounts: conversation.unreadCounts,
          unreadCount: conversation.getUnreadCountForUser(currentUserId),
          createdBy: conversation.createdBy,
          createdAt: conversation.createdAt,
        );
        notifyListeners();
      }
    });

    // Cancel previous messages stream subscription if exists
    _messagesStreamSubscription?.cancel();
    _messagesStream = null;
    
    // Setup messages stream - create new stream for this conversation
    _messagesStream = _controller.getMessagesStream(conversationId);
    
    // Notify listeners immediately so StreamBuilder can subscribe to new stream
    notifyListeners();

    // Setup typing stream
    _typingSubscription?.cancel();
    _typingUsers = {}; // Clear previous typing users
    _typingSubscription = _controller
        .getTypingStream(conversationId)
        .listen(
          (typingUsers) {
            debugPrint('Typing users received: ${typingUsers.length}');
            // Filter out current user from typing users
            _typingUsers = Map<String, String>.from(typingUsers)
              ..removeWhere((userId, _) => userId == currentUserId);
            debugPrint('Typing users after filter: ${_typingUsers.length}');
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Error in typing stream: $error');
            _typingUsers = {};
            notifyListeners();
          },
        );

    // Mark as read
    _controller.markAsRead(conversationId);

    notifyListeners();
    
    // Force a rebuild after a short delay to ensure stream is connected
    Future.delayed(const Duration(milliseconds: 100), () {
      notifyListeners();
    });
  }

  // Set typing status
  Future<void> setTyping(bool isTyping) async {
    if (_selectedConversationId == null) {
      debugPrint('Cannot set typing: no conversation selected');
      return;
    }
    try {
      debugPrint('Setting typing status: $isTyping for conversation: $_selectedConversationId');
      await _controller.setTyping(_selectedConversationId!, isTyping);
    } catch (e) {
      debugPrint('Error setting typing status: $e');
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _selectedConversationId == null) return;

    try {
      await _controller.sendMessage(_selectedConversationId!, text.trim());
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  Future<void> sendMessageWithFile(
    String text,
    Uint8List fileData,
    String fileName,
  ) async {
    if (_selectedConversationId == null) return;

    try {
      await _controller.sendMessageWithFile(
        _selectedConversationId!,
        text.trim(),
        fileData,
        fileName,
      );
    } catch (e) {
      debugPrint('Error sending message with file: $e');
      rethrow;
    }
  }

  Future<List<UserModel>> getUsers() async {
    try {
      return await _controller.getUsers();
    } catch (e) {
      debugPrint('Error getting users: $e');
      return [];
    }
  }

  Future<String> createDirectConversation(
    String otherUserId,
    String otherUserName,
  ) async {
    try {
      final conversationId = await _controller.createDirectConversation(
        otherUserId,
        otherUserName,
      );
      await loadConversations();
      return conversationId;
    } catch (e) {
      debugPrint('Error creating direct conversation: $e');
      rethrow;
    }
  }

  Future<String> createGroup(
    String groupName,
    List<String> memberIds,
    Map<String, String> memberNames,
  ) async {
    try {
      // Add current user to members
      final allMemberIds = [currentUserId, ...memberIds];
      final allMemberNames = Map<String, String>.from(memberNames);
      allMemberNames[currentUserId] = _controller.currentUserName;

      final conversationId = await _controller.createGroupConversation(
        groupName,
        allMemberIds,
        allMemberNames,
      );
      await loadConversations();
      return conversationId;
    } catch (e) {
      debugPrint('Error creating group: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _conversationSubscription?.cancel();
    _typingSubscription?.cancel();
    _conversationsStreamSubscription?.cancel();
    _messagesStreamSubscription?.cancel();
    // Cancel all typing subscriptions
    for (final subscription in _typingSubscriptions.values) {
      subscription.cancel();
    }
    _typingSubscriptions.clear();
    super.dispose();
  }
}

