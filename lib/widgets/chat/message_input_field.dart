import 'package:flutter/material.dart';

/// WhatsApp-style message input field widget
class MessageInputField extends StatelessWidget {
  const MessageInputField({
    super.key,
    required this.controller,
    required this.onSend,
    this.onAttachmentTap,
    this.onEmojiTap,
    this.hintText = 'Type a message',
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onAttachmentTap;
  final VoidCallback? onEmojiTap;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), // Light background
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE4E7EC).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Emoji button
          IconButton(
            icon: const Icon(
              Icons.emoji_emotions_outlined,
              size: 24,
              color: Color(0xFF2563EB), // Blue text
            ),
            onPressed: onEmojiTap ?? () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          // Text input
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 100),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(21),
              ),
              child: TextField(
                controller: controller,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF0F172A), // Dark text
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(
                    color: const Color(0xFF667781).withValues(alpha: 0.7),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Attachment button
          IconButton(
            icon: const Icon(
              Icons.attach_file,
              size: 24,
              color: Color(0xFF2563EB), // Blue text
            ),
            onPressed: onAttachmentTap ?? () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          // Send button
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB), // Blue send button
              shape: BoxShape.circle,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onSend,
                child: const Icon(
                  Icons.send_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
