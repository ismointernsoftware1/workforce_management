class RealtimeChatMessage {
  const RealtimeChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.type = MessageType.text,
    this.attachmentUrl,
    this.fileName,
    this.fileSize,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final int timestamp;
  final MessageType type;
  final String? attachmentUrl;
  final String? fileName;
  final int? fileSize;

  factory RealtimeChatMessage.fromMap(Map<dynamic, dynamic> data, String id) {
    return RealtimeChatMessage(
      id: id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      text: data['text'] as String? ?? '',
      timestamp: data['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      type: MessageType.values.firstWhere(
        (e) => e.name == (data['type'] as String? ?? 'text'),
        orElse: () => MessageType.text,
      ),
      attachmentUrl: data['attachmentUrl'] as String?,
      fileName: data['fileName'] as String?,
      fileSize: data['fileSize'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'timestamp': timestamp,
        'type': type.name,
        if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
        if (fileName != null) 'fileName': fileName,
        if (fileSize != null) 'fileSize': fileSize,
      };
}

enum MessageType {
  text,
  image,
  file,
}

class RealtimeChatConversation {
  const RealtimeChatConversation({
    required this.id,
    required this.type,
    required this.name,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.memberIds,
    required this.memberNames,
    this.unreadCounts = const {},
    this.unreadCount = 0, // Legacy support - will be calculated from unreadCounts
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final ConversationType type;
  final String name;
  final String lastMessage;
  final int lastMessageTime;
  final List<String> memberIds;
  final Map<String, String> memberNames; // userId -> name
  final Map<String, int> unreadCounts; // userId -> unread count
  final int unreadCount; // Legacy - calculated from unreadCounts for current user
  final String? createdBy;
  final int? createdAt;
  
  // Get unread count for a specific user
  int getUnreadCountForUser(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  factory RealtimeChatConversation.fromMap(
    Map<dynamic, dynamic> data,
    String id, {
    String? currentUserId,
  }) {
    final memberIdsList = data['memberIds'] as List<dynamic>? ?? [];
    final memberNamesMap = data['memberNames'] as Map<dynamic, dynamic>? ?? {};
    
    // Parse unreadCounts map (per-user unread counts)
    final unreadCountsMap = data['unreadCounts'] as Map<dynamic, dynamic>? ?? {};
    final unreadCounts = Map<String, int>.from(
      unreadCountsMap.map((key, value) => MapEntry(
        key.toString(),
        (value is int) ? value : (int.tryParse(value.toString()) ?? 0),
      )),
    );
    
    // Calculate unread count for current user (for backward compatibility)
    final unreadCount = currentUserId != null 
        ? (unreadCounts[currentUserId] ?? 0)
        : (data['unreadCount'] as int? ?? 0); // Fallback to legacy field
    
    return RealtimeChatConversation(
      id: id,
      type: ConversationType.values.firstWhere(
        (e) => e.name == (data['type'] as String? ?? 'direct'),
        orElse: () => ConversationType.direct,
      ),
      name: data['name'] as String? ?? '',
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageTime: data['lastMessageTime'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      memberIds: memberIdsList.map((e) => e.toString()).toList(),
      memberNames: Map<String, String>.from(
        memberNamesMap.map((key, value) => MapEntry(key.toString(), value.toString())),
      ),
      unreadCounts: unreadCounts,
      unreadCount: unreadCount,
      createdBy: data['createdBy'] as String?,
      createdAt: data['createdAt'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'name': name,
        'lastMessage': lastMessage,
        'lastMessageTime': lastMessageTime,
        'memberIds': memberIds,
        'memberNames': memberNames,
        'unreadCounts': unreadCounts,
        if (createdBy != null) 'createdBy': createdBy,
        if (createdAt != null) 'createdAt': createdAt,
      };
}

enum ConversationType {
  direct,
  group,
}

