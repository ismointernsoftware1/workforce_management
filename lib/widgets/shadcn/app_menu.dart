import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';

/// Menu item model
class AppMenuItem {
  const AppMenuItem({
    required this.value,
    required this.label,
    this.icon,
    this.isDestructive = false,
    this.onTap,
  });

  final String value;
  final String label;
  final IconData? icon;
  final bool isDestructive;
  final VoidCallback? onTap;
}

/// ShadCN-style dropdown menu
class AppMenu extends StatelessWidget {
  const AppMenu({
    super.key,
    required this.items,
    this.child,
    this.icon,
    this.onSelected,
  });

  final List<AppMenuItem> items;
  final Widget? child;
  final IconData? icon;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: icon != null
          ? Icon(icon, color: AppColors.textMuted)
          : child ?? const Icon(Icons.more_vert, color: AppColors.textMuted),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 8,
      color: Colors.white,
      padding: EdgeInsets.zero,
      offset: const Offset(0, 8),
      onSelected: (value) {
        final item = items.firstWhere((item) => item.value == value);
        item.onTap?.call();
        onSelected?.call(value);
      },
      itemBuilder: (context) => items.map((item) {
        return PopupMenuItem<String>(
          value: item.value,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(
                  item.icon,
                  size: 18,
                  color: item.isDestructive
                      ? AppColors.danger
                      : AppColors.textPrimary,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  color: item.isDestructive
                      ? AppColors.danger
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

