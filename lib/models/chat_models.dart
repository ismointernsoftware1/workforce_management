import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.body,
    required this.sentAt,
    required this.isMine,
  });

  final String id;
  final String sender;
  final String body;
  final DateTime sentAt;
  final bool isMine;

  factory ChatMessage.fromMap(Map<String, dynamic> data, {String? id}) {
    return ChatMessage(
      id: id ?? data['id'] as String? ?? '',
      sender: data['sender'] as String? ?? '',
      body: data['body'] as String? ?? '',
      sentAt: (data['sentAt'] is Timestamp)
          ? (data['sentAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['sentAt']?.toString() ?? '') ??
              DateTime.now(),
      isMine: data['isMine'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'sender': sender,
        'body': body,
        'sentAt': Timestamp.fromDate(sentAt),
        'isMine': isMine,
      };
}

class Conversation {
  const Conversation({
    required this.id,
    required this.topic,
    required this.preview,
    required this.updatedAt,
    required this.unreadCount,
    required this.members,
    required this.messages,
  });

  final String id;
  final String topic;
  final String preview;
  final DateTime updatedAt;
  final int unreadCount;
  final List<String> members;
  final List<ChatMessage> messages;

  factory Conversation.fromMap(Map<String, dynamic> data, {String? id}) {
    return Conversation(
      id: id ?? data['id'] as String? ?? '',
      topic: data['topic'] as String? ?? '',
      preview: data['preview'] as String? ?? '',
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['updatedAt']?.toString() ?? '') ??
              DateTime.now(),
      unreadCount: (data['unreadCount'] as num?)?.toInt() ?? 0,
      members: (data['members'] as List<dynamic>? ?? [])
          .map((m) => m.toString())
          .toList(),
      messages: (data['messages'] as List<dynamic>? ?? [])
          .map(
            (m) => ChatMessage.fromMap(
              Map<String, dynamic>.from(m as Map),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'topic': topic,
        'preview': preview,
        'updatedAt': Timestamp.fromDate(updatedAt),
        'unreadCount': unreadCount,
        'members': members,
        'messages': messages.map((m) => m.toMap()).toList(),
      };
}

