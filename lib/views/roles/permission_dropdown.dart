import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';

/// PermissionDropdown - widget for selecting multiple permissions via dropdown
class PermissionDropdown extends StatefulWidget {
  const PermissionDropdown({
    super.key,
    required this.label,
    required this.selectedPermissions,
    required this.onChanged,
  });

  final String label;
  final List<String> selectedPermissions; // List of selected permissions
  final Function(List<String>) onChanged;

  static const List<String> _permissions = [
    'Create',
    'Read',
    'Update',
    'Delete',
  ];

  @override
  State<PermissionDropdown> createState() => _PermissionDropdownState();
}

class _PermissionDropdownState extends State<PermissionDropdown> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        GestureDetector(
          onTap: () {
            setState(() {
              _isOpen = !_isOpen;
            });
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: widget.selectedPermissions.isEmpty
                      ? Text(
                          'Select permission...',
                          style: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        )
                      : Text(
                          widget.selectedPermissions.length == 1
                              ? widget.selectedPermissions.first
                              : '${widget.selectedPermissions.length} selected',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                ),
                Icon(
                  _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_isOpen) ...[
          const SizedBox(height: AppSpacing.xs),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: PermissionDropdown._permissions.map((permission) {
                final isSelected = widget.selectedPermissions.contains(permission);
                return InkWell(
                  onTap: () {
                    final newSelection = List<String>.from(widget.selectedPermissions);
                    if (isSelected) {
                      newSelection.remove(permission);
                    } else {
                      newSelection.add(permission);
                    }
                    widget.onChanged(newSelection);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    color: isSelected
                        ? AppColors.primarySoft.withValues(alpha: 0.2)
                        : Colors.transparent,
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                          size: 20,
                          color: isSelected ? AppColors.primary : AppColors.textMuted,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            permission,
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
