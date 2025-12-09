import 'dart:async';
import 'dart:typed_data';

import '../models/realtime_chat_models.dart';
import '../models/user_model.dart';
import '../services/realtime_chat_service.dart';
import '../services/storage_service.dart';

class RealtimeChatController {
  RealtimeChatController({
    required RealtimeChatService service,
    required String currentUserId,
    required String currentUserName,
    StorageService? storageService,
  })  : _service = service,
        _currentUserId = currentUserId,
        _currentUserName = currentUserName,
        _storageService = storageService ?? StorageService();

  final RealtimeChatService _service;
  final String _currentUserId;
  final String _currentUserName;
  final StorageService _storageService;

  String get currentUserId => _currentUserId;
  String get currentUserName => _currentUserName;

  // Get all users (excludes current user)
  Future<List<UserModel>> getUsers() => _service.getUsers(excludeUserId: _currentUserId);

  // Get user by ID
  Future<UserModel?> getUserById(String userId) => _service.getUserById(userId);

  // Create direct conversation
  Future<String> createDirectConversation(
    String otherUserId,
    String otherUserName,
  ) async {
    return await _service.createDirectConversation(
      _currentUserId,
      otherUserId,
      _currentUserName,
      otherUserName,
    );
  }

  // Create group conversation
  Future<String> createGroupConversation(
    String groupName,
    List<String> memberIds,
    Map<String, String> memberNames,
  ) async {
    return await _service.createGroupConversation(
      groupName,
      _currentUserId,
      _currentUserName,
      memberIds,
      memberNames,
    );
  }

  // Send message
  Future<void> sendMessage(
    String conversationId,
    String text, {
    String? attachmentUrl,
    String? fileName,
    int? fileSize,
    MessageType type = MessageType.text,
  }) async {
    final message = RealtimeChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _currentUserId,
      senderName: _currentUserName,
      text: text,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      type: type,
      attachmentUrl: attachmentUrl,
      fileName: fileName,
      fileSize: fileSize,
    );

    await _service.sendMessage(conversationId, message);
  }

  // Upload file and send message
  Future<void> sendMessageWithFile(
    String conversationId,
    String text,
    Uint8List fileData,
    String fileName,
  ) async {
    try {
      // Upload file to Firebase Storage
      final attachmentUrl = await _storageService.uploadChatAttachment(
        conversationId: conversationId,
        fileData: fileData,
        fileName: fileName,
      );

      // Determine message type based on file extension
      final fileExtension = fileName.split('.').last.toLowerCase();
      MessageType messageType = MessageType.file;
      if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExtension)) {
        messageType = MessageType.image;
      } else if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(fileExtension)) {
        messageType = MessageType.video;
      }

      // Send message with attachment
      await sendMessage(
        conversationId,
        text.isEmpty ? '📎 $fileName' : text,
        attachmentUrl: attachmentUrl,
        fileName: fileName,
        fileSize: fileData.length,
        type: messageType,
      );
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  // Get user conversations
  Future<List<RealtimeChatConversation>> getUserConversations() =>
      _service.getUserConversations(_currentUserId);

  // Get user conversations stream
  Stream<List<RealtimeChatConversation>> getUserConversationsStream() =>
      _service.getUserConversationsStream(_currentUserId);

  // Get messages stream
  Stream<List<RealtimeChatMessage>> getMessagesStream(String conversationId) =>
      _service.getMessagesStream(conversationId);

  // Get conversation stream
  Stream<RealtimeChatConversation?> getConversationStream(
    String conversationId,
  ) =>
      _service.getConversationStream(conversationId, currentUserId: _currentUserId);

  // Mark as read (also marks messages as seen)
  Future<void> markAsRead(String conversationId) =>
      _service.markAsRead(conversationId, _currentUserId);
  
  // Mark messages as seen
  Future<void> markMessagesAsSeen(String conversationId) =>
      _service.markMessagesAsSeen(conversationId, _currentUserId);

  // Update group members
  Future<void> updateGroupMembers(
    String conversationId,
    List<String> memberIds,
    Map<String, String> memberNames,
  ) =>
      _service.updateGroupMembers(conversationId, memberIds, memberNames);

  // Set typing status
  Future<void> setTyping(
    String conversationId,
    bool isTyping,
  ) async {
    await _service.setTyping(
      conversationId,
      _currentUserId,
      _currentUserName,
      isTyping,
    );
  }

  // Get typing stream
  Stream<Map<String, String>> getTypingStream(String conversationId) =>
      _service.getTypingStream(conversationId);
}

