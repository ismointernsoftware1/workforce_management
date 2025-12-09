import 'package:flutter/material.dart';
import '../../models/realtime_chat_models.dart';

/// WhatsApp-style message status icon (sent, delivered, seen)
class MessageStatusIcon extends StatelessWidget {
  const MessageStatusIcon({
    super.key,
    required this.status,
  });

  final MessageStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: 14,
          color: Colors.white.withValues(alpha: 0.8),
        );
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 14,
          color: Colors.white.withValues(alpha: 0.8),
        );
      case MessageStatus.seen:
        return Icon(
          Icons.done_all,
          size: 14,
          color: Colors.white, // Blue check for seen
        );
    }
  }
}

