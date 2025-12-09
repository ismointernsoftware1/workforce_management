import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/realtime_chat_models.dart';
import 'message_status_icon.dart';

/// WhatsApp-style message bubble widget (handles both incoming and outgoing)
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.onImageTap,
    this.onVideoTap,
    this.onFileTap,
  });

  final RealtimeChatMessage message;
  final bool isMine;
  final VoidCallback? onImageTap;
  final VoidCallback? onVideoTap;
  final VoidCallback? onFileTap;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('HH:mm');
    final time = DateTime.fromMillisecondsSinceEpoch(message.timestamp);

    // Modern professional colors
    final sentBubbleColor = const Color(0xFF2563EB); // Blue for sent messages
    final receivedBubbleColor = const Color(0xFFFFFFFF); // White for received
    final sentTextColor = Colors.white; // White text on blue
    final receivedTextColor = const Color(0xFF0F172A); // Dark text on white
    final timestampColor = const Color(0xFF64748B); // Muted grey timestamp

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.5),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          margin: EdgeInsets.only(
            bottom: 1,
            right: isMine ? 6 : 60,
            left: isMine ? 60 : 6,
            top: 1,
          ),
          padding: const EdgeInsets.only(
            left: 7,
            right: 7,
            top: 6,
            bottom: 6,
          ),
          decoration: BoxDecoration(
            color: isMine ? sentBubbleColor : receivedBubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(7.5),
              topRight: const Radius.circular(7.5),
              bottomLeft: Radius.circular(isMine ? 7.5 : 0),
              bottomRight: Radius.circular(isMine ? 0 : 7.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sender name for group chats (only show for received messages)
              if (!isMine) ...[
                Text(
                  message.senderName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: const Color(0xFF2563EB), // Blue accent
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              // Message text
              if (message.text.isNotEmpty) ...[
                Text(
                  message.text,
                  style: TextStyle(
                    color: isMine ? sentTextColor : receivedTextColor,
                    fontSize: 14.2,
                    height: 1.3,
                    letterSpacing: 0.1,
                  ),
                ),
                if (message.attachmentUrl != null) const SizedBox(height: 6),
              ],
              // Attachment (image, video, or file)
              if (message.attachmentUrl != null) ...[
                if (message.text.isNotEmpty) const SizedBox(height: 6),
                _buildAttachment(context, isMine),
              ],
              // Timestamp and status
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatter.format(time),
                    style: TextStyle(
                      color: isMine
                          ? Colors.white.withValues(alpha: 0.8)
                          : timestampColor,
                      fontSize: 11.5,
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    MessageStatusIcon(status: message.status),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachment(BuildContext context, bool isMine) {
    switch (message.type) {
      case MessageType.image:
        return GestureDetector(
          onTap: onImageTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              message.attachmentUrl!,
              width: 250,
              height: 250,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 250,
                  height: 250,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 250,
                  height: 250,
                  color: Colors.grey[200],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      case MessageType.video:
        return GestureDetector(
          onTap: onVideoTap,
          child: Container(
            width: 200,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.play_circle_filled,
                  size: 48,
                  color: isMine ? Colors.white : const Color(0xFF64748B),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'VIDEO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case MessageType.file:
        return GestureDetector(
          onTap: onFileTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMine
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.insert_drive_file,
                  size: 24,
                  color: isMine ? Colors.white : const Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.fileName ?? 'File',
                      style: TextStyle(
                        color: isMine ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (message.fileSize != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatFileSize(message.fileSize!),
                        style: TextStyle(
                          color: isMine
                              ? Colors.white.withValues(alpha: 0.8)
                              : const Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

