import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../constants/app_spacing.dart';

/// Button variant types
enum AppButtonVariant {
  primary,
  outline,
  destructive,
  ghost,
  link,
}

/// Button size types
enum AppButtonSize {
  small,
  medium,
  large,
}

/// Generic reusable button widget
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    this.label,
    this.child,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.width,
    this.fullWidth = false,
    this.disabled = false,
  }) : assert(label != null || child != null, 'Either label or child must be provided');

  final String? label;
  final Widget? child;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final double? width;
  final bool fullWidth;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || isLoading || onPressed == null;

    Widget button;

    final buttonChild = isLoading
        ? SizedBox(
            height: _getIconSize(),
            width: _getIconSize(),
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : child != null
            ? child!
            : Row(
                mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: _getIconSize()),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(label ?? ''),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Icon(trailingIcon, size: _getIconSize()),
                  ],
                ],
              );

    switch (variant) {
      case AppButtonVariant.primary:
        button = ShadButton(
          onPressed: isDisabled ? null : onPressed,
          child: buttonChild,
        );
        break;
      case AppButtonVariant.outline:
        button = ShadButton.outline(
          onPressed: isDisabled ? null : onPressed,
          child: buttonChild,
        );
        break;
      case AppButtonVariant.destructive:
        button = ShadButton.destructive(
          onPressed: isDisabled ? null : onPressed,
          child: buttonChild,
        );
        break;
      case AppButtonVariant.ghost:
        button = ShadButton.ghost(
          onPressed: isDisabled ? null : onPressed,
          child: buttonChild,
        );
        break;
      case AppButtonVariant.link:
        button = ShadButton.ghost(
          onPressed: isDisabled ? null : onPressed,
          child: buttonChild,
        );
        break;
    }

    if (width != null) {
      return SizedBox(width: width, child: button);
    }
    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return 14;
      case AppButtonSize.medium:
        return 16;
      case AppButtonSize.large:
        return 18;
    }
  }
}

