import '../models/chat_models.dart';
import '../services/firebase_service.dart';

class ChatController {
  const ChatController(this._service);

  final FirebaseService _service;

  Future<List<Conversation>> fetchConversations() =>
      _service.fetchConversations();

  Future<void> sendMessage(
    String conversationId,
    ChatMessage message,
  ) =>
      _service.sendMessage(conversationId, message);
}

