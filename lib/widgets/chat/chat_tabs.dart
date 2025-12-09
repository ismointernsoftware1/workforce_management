import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../providers/realtime_chat_provider.dart';

/// WhatsApp-style chat tabs widget (Messages/Group)
class ChatTabs extends StatelessWidget {
  const ChatTabs({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
  });

  final ChatTab activeTab;
  final ValueChanged<ChatTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final isInbox = activeTab == ChatTab.inbox;
    
    return Row(
      children: [
        Expanded(
          child: _TabButton(
            icon: Icons.message,
            label: 'Messages',
            isActive: isInbox,
            onTap: () => onTabChanged(ChatTab.inbox),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _TabButton(
            icon: Icons.group,
            label: 'Group',
            isActive: !isInbox,
            onTap: () => onTabChanged(ChatTab.explore),
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? AppColors.primary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
