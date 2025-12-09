import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';

/// Generic select option model
class SelectOption<T> {
  const SelectOption({
    required this.value,
    required this.label,
    this.icon,
    this.description,
    this.disabled = false,
  });

  final T value;
  final String label;
  final IconData? icon;
  final String? description;
  final bool disabled;

  /// Create from a map
  factory SelectOption.fromMap(Map<String, dynamic> map) {
    return SelectOption<T>(
      value: map['value'] as T,
      label: map['label'] as String,
      icon: map['icon'] as IconData?,
      description: map['description'] as String?,
      disabled: map['disabled'] as bool? ?? false,
    );
  }

  /// Create from enum
  static List<SelectOption<T>> fromEnum<T extends Enum>(
    List<T> values,
    String Function(T) labelBuilder,
  ) {
    return values.map((e) => SelectOption<T>(
      value: e,
      label: labelBuilder(e),
    )).toList();
  }

  /// Create from string list
  static List<SelectOption<String>> fromStringList(List<String> values) {
    return values.map((e) => SelectOption<String>(
      value: e,
      label: e,
    )).toList();
  }

  /// Create from map with custom label
  static List<SelectOption<T>> fromMapList<T>(
    List<Map<String, dynamic>> maps,
    T Function(Map<String, dynamic>) valueExtractor,
    String Function(Map<String, dynamic>) labelExtractor,
  ) {
    return maps.map((map) => SelectOption<T>(
      value: valueExtractor(map),
      label: labelExtractor(map),
      icon: map['icon'] as IconData?,
      description: map['description'] as String?,
    )).toList();
  }
}

/// Generic reusable select widget
class AppSelect<T> extends StatelessWidget {
  const AppSelect({
    super.key,
    required this.options,
    required this.selectedOptionBuilder,
    required this.onChanged,
    this.placeholder,
    this.value,
    this.width,
    this.height,
    this.enabled = true,
    this.showSearch = false,
    this.groupLabel,
  });

  /// List of select options
  final List<SelectOption<T>> options;

  /// Builder for selected option display
  final Widget Function(BuildContext, T?) selectedOptionBuilder;

  /// Callback when selection changes
  final ValueChanged<T?> onChanged;

  /// Placeholder text
  final String? placeholder;

  /// Current selected value
  final T? value;

  /// Optional width constraint
  final double? width;

  /// Optional height constraint
  final double? height;

  /// Whether the select is enabled
  final bool enabled;

  /// Show search functionality
  final bool showSearch;

  /// Optional group label (like "Fruits" in the example)
  final String? groupLabel;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    
    // Build options list with optional group label
    final optionWidgets = <Widget>[];
    
    if (groupLabel != null) {
      optionWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            groupLabel!,
            style: theme.textTheme.muted.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.popoverForeground,
            ),
            textAlign: TextAlign.start,
          ),
        ),
      );
    }

    optionWidgets.addAll(
      options.map((option) {
        return ShadOption(
          value: option.value,
          child: _buildOptionChild(option),
        );
      }),
    );

    Widget select = ShadSelect<T>(
      placeholder: placeholder != null ? Text(placeholder!) : null,
      options: optionWidgets,
      selectedOptionBuilder: selectedOptionBuilder,
      onChanged: enabled ? onChanged : null,
    );

    if (width != null || height != null) {
      return SizedBox(
        width: width,
        height: height,
        child: select,
      );
    }
    return select;
  }

  Widget _buildOptionChild(SelectOption<T> option) {
    if (option.icon != null || option.description != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (option.icon != null) ...[
                Icon(option.icon, size: 16),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Text(option.label),
              ),
            ],
          ),
          if (option.description != null) ...[
            const SizedBox(height: 2),
            Text(
              option.description!,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      );
    }
    return Text(option.label);
  }
}

