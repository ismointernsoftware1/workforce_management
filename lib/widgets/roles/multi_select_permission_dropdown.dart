import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../utils/responsive_utils.dart';

/// Multi-select dropdown for CRUD permissions
class MultiSelectPermissionDropdown extends StatefulWidget {
  const MultiSelectPermissionDropdown({
    super.key,
    required this.label,
    required this.selectedPermissions,
    required this.onChanged,
  });

  final String label;
  final List<String> selectedPermissions;
  final ValueChanged<List<String>> onChanged;

  @override
  State<MultiSelectPermissionDropdown> createState() =>
      _MultiSelectPermissionDropdownState();
}

class _MultiSelectPermissionDropdownState
    extends State<MultiSelectPermissionDropdown> {
  final List<String> _allPermissions = ['Create', 'Read', 'Update', 'Delete'];
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: isMobile ? 13 : (isTablet ? 13.5 : 14),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        GestureDetector(
          onTap: () => setState(() => _isOpen = !_isOpen),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? AppSpacing.sm : AppSpacing.md,
              vertical: isMobile ? AppSpacing.xs : AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.selectedPermissions.isEmpty
                        ? 'Select permissions...'
                        : widget.selectedPermissions.join(', '),
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: widget.selectedPermissions.isEmpty
                          ? AppColors.textMuted.withValues(alpha: 0.6)
                          : AppColors.textPrimary,
                    ),
                    maxLines: isMobile ? 2 : null,
                    overflow: isMobile ? TextOverflow.ellipsis : null,
                  ),
                ),
                Icon(
                  _isOpen
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.textMuted,
                  size: isMobile ? 18 : 20,
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
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: _allPermissions.map((permission) {
                final isSelected = widget.selectedPermissions.contains(permission);
                return InkWell(
                  onTap: () {
                    final newList = List<String>.from(widget.selectedPermissions);
                    if (isSelected) {
                      newList.remove(permission);
                    } else {
                      newList.add(permission);
                    }
                    widget.onChanged(newList);
                  },
                  child: Builder(
                    builder: (context) {
                      final isMobile = ResponsiveUtils.isMobile(context);
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? AppSpacing.sm : AppSpacing.md,
                          vertical: isMobile ? AppSpacing.xs : AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: isMobile ? 18 : 20,
                              height: isMobile ? 18 : 20,
                              child: Checkbox(
                                value: isSelected,
                                onChanged: (value) {
                                  final newList = List<String>.from(widget.selectedPermissions);
                                  if (value == true) {
                                    if (!newList.contains(permission)) {
                                      newList.add(permission);
                                    }
                                  } else {
                                    newList.remove(permission);
                                  }
                                  widget.onChanged(newList);
                                },
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            SizedBox(width: isMobile ? AppSpacing.xs : AppSpacing.sm),
                            Expanded(
                              child: Text(
                                permission,
                                style: TextStyle(
                                  fontSize: isMobile ? 13 : 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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

