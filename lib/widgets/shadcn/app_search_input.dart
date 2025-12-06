import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../constants/app_colors.dart';

/// Generic reusable search input widget
class AppSearchInput extends StatefulWidget {
  const AppSearchInput({
    super.key,
    required this.controller,
    this.placeholder = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.icon,
    this.width,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final IconData? icon;
  final double? width;
  final bool enabled;

  @override
  State<AppSearchInput> createState() => _AppSearchInputState();
}

class _AppSearchInputState extends State<AppSearchInput> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _clear() {
    widget.controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    Widget input = ShadInput(
      controller: widget.controller,
      placeholder: Text(widget.placeholder),
      leading: Icon(
        widget.icon ?? Icons.search,
        color: AppColors.textMuted,
        size: 20,
      ),
      trailing: _hasText
          ? IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: _clear,
            )
          : null,
      onChanged: widget.enabled ? (value) {
        widget.onChanged?.call(value);
      } : null,
      onSubmitted: widget.enabled && widget.onSubmitted != null ? (value) {
        widget.onSubmitted?.call(value);
      } : null,
      readOnly: !widget.enabled,
    );

    if (widget.width != null) {
      return SizedBox(width: widget.width, child: input);
    }
    return input;
  }
}

