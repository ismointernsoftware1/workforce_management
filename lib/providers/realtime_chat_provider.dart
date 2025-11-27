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

  bool get isLoading => _isLoading;
  ChatTab get activeTab => _activeTab;
  String? get selectedConversationId => _selectedConversationId;
  RealtimeChatConversation? get selectedConversation => _selectedConversation;
  Stream<List<RealtimeChatMessage>> get messagesStream =>
      _messagesStream ??
      Stream<List<RealtimeChatMessage>>.value(const <RealtimeChatMessage>[]);

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
      _allConversations = await _controller.getUserConversations();
      _isLoading = false;
      if (_selectedConversationId == null && _allConversations.isNotEmpty) {
        selectConversation(_allConversations.first.id);
      } else {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load conversations without triggering during build
  void scheduleLoadConversations() {
    Future.microtask(() => loadConversations());
  }

  void selectConversation(String conversationId) {
    if (_selectedConversationId == conversationId) return;

    _selectedConversationId = conversationId;
    _conversationSubscription?.cancel();

    // Listen to conversation updates
    _conversationSubscription = _controller
        .getConversationStream(conversationId)
        .listen((conversation) {
      _selectedConversation = conversation;
      notifyListeners();

      // Update in all conversations list
      final index = _allConversations.indexWhere((c) => c.id == conversationId);
      if (index != -1 && conversation != null) {
        _allConversations[index] = conversation;
        notifyListeners();
      }
    });

    // Setup messages stream
    _messagesStream = _controller.getMessagesStream(conversationId);

    // Mark as read
    _controller.markAsRead(conversationId);

    notifyListeners();
    
    // Force a rebuild after a short delay to ensure stream is connected
    Future.delayed(const Duration(milliseconds: 100), () {
      notifyListeners();
    });
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
    super.dispose();
  }
}

