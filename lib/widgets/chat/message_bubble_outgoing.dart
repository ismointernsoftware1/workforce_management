import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_spacing.dart';
import '../../models/realtime_chat_models.dart';

/// Outgoing message bubble (right-aligned, blue background)
class MessageBubbleOutgoing extends StatelessWidget {
  const MessageBubbleOutgoing({
    super.key,
    required this.message,
    this.onImageTap,
    this.onVideoTap,
  });

  final RealtimeChatMessage message;
  final VoidCallback? onImageTap;
  final VoidCallback? onVideoTap;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('HH:mm');
    final time = DateTime.fromMillisecondsSinceEpoch(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.5),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          margin: const EdgeInsets.only(
            bottom: 1,
            right: 6,
            left: 60,
            top: 1,
          ),
          padding: const EdgeInsets.only(
            left: 12,
            right: 12,
            top: 8,
            bottom: 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF3174F3), // WhatsApp blue
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.text.isNotEmpty) ...[
                Text(
                  message.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    height: 1.3,
                    letterSpacing: 0.1,
                  ),
                ),
                if (message.attachmentUrl != null) const SizedBox(height: 6),
              ],
              if (message.attachmentUrl != null) ...[
                _buildAttachment(context),
                const SizedBox(height: 4),
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatter.format(time),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildStatusIcon(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachment(BuildContext context) {
    switch (message.type) {
      case MessageType.image:
        return GestureDetector(
          onTap: onImageTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
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
                  color: Colors.black.withValues(alpha: 0.2),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 250,
                  height: 250,
                  color: Colors.black.withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.white70,
                    size: 48,
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
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.play_circle_filled,
                  size: 48,
                  color: Colors.white,
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
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
        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.insert_drive_file,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.fileName ?? 'File',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (message.fileSize != null)
                    Text(
                      _formatFileSize(message.fileSize!),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStatusIcon() {
    switch (message.status) {
      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: 16,
          color: Colors.white.withValues(alpha: 0.8),
        );
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 16,
          color: Colors.white.withValues(alpha: 0.8),
        );
      case MessageStatus.seen:
        return const Icon(
          Icons.done_all,
          size: 16,
          color: Colors.white,
        );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

