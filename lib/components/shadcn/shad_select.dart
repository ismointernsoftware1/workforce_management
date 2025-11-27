import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';

class ShadSelect<T> extends StatelessWidget {
  const ShadSelect({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.hint,
    this.label,
    this.prefixIcon,
    this.enabled = true,
    this.validator,
  });

  final List<ShadSelectItem<T>> items;
  final ValueChanged<T?> onChanged;
  final T? value;
  final String? hint;
  final String? label;
  final Widget? prefixIcon;
  final bool enabled;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    final dropdown = DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: enabled ? AppColors.surface : AppColors.surfaceAlt,
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item.value,
          child: item.child ?? Text(item.label),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      validator: validator,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
      ),
      dropdownColor: AppColors.surface,
      icon: const Icon(
        Icons.expand_more_rounded,
        color: AppColors.textMuted,
      ),
      isExpanded: false, // Set to false to allow natural sizing
    );

    // Wrap dropdown to provide width constraints when used in Row
    // Use Flexible approach that works in both constrained and unconstrained contexts
    final constrainedDropdown = LayoutBuilder(
      builder: (context, constraints) {
        // If width is unbounded (e.g., in a Row without Expanded), provide a default
        if (constraints.maxWidth == double.infinity) {
          return SizedBox(
            width: 200, // Default width when unbounded
            child: dropdown,
          );
        }
        // Otherwise, use available space
        return SizedBox(
          width: constraints.maxWidth,
          child: dropdown,
        );
      },
    );

    if (label != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          constrainedDropdown,
        ],
      );
    }

    return constrainedDropdown;
  }
}

class ShadSelectItem<T> {
  const ShadSelectItem({
    required this.value,
    required this.label,
    this.child,
  });

  final T value;
  final String label;
  final Widget? child;
}

