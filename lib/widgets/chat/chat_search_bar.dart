import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// WhatsApp-style chat search bar widget
class ChatSearchBar extends StatelessWidget {
  const ChatSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.hintText = 'Search or start new chat',
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppColors.textMuted.withValues(alpha: 0.7),
            fontSize: 14.5,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: AppColors.textMuted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
