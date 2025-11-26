import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';

enum ShadButtonVariant {
  default_,
  outline,
  ghost,
  link,
  destructive,
}

enum ShadButtonSize {
  sm,
  md,
  lg,
  icon,
}

class ShadButton extends StatelessWidget {
  const ShadButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = ShadButtonVariant.default_,
    this.size = ShadButtonSize.md,
    this.disabled = false,
    this.width,
    this.icon,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ShadButtonVariant variant;
  final ShadButtonSize size;
  final bool disabled;
  final double? width;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || onPressed == null;
    
    final buttonStyle = _getButtonStyle(variant, isDisabled);
    final sizeStyle = _getSizeStyle(size);
    
    Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          icon!,
          const SizedBox(width: AppSpacing.sm),
        ],
        child,
      ],
    );

    if (size == ShadButtonSize.icon) {
      buttonChild = icon ?? child;
    }

    final button = _buildButton(buttonStyle, sizeStyle, buttonChild, isDisabled);

    if (width != null) {
      return SizedBox(width: width, child: button);
    }

    return button;
  }

  Widget _buildButton(
    ButtonStyle style,
    EdgeInsets padding,
    Widget child,
    bool isDisabled,
  ) {
    switch (variant) {
      case ShadButtonVariant.outline:
        return OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: style.copyWith(
            padding: WidgetStateProperty.all(padding),
          ),
          child: child,
        );
      case ShadButtonVariant.ghost:
      case ShadButtonVariant.link:
        return TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: style.copyWith(
            padding: WidgetStateProperty.all(padding),
          ),
          child: child,
        );
      case ShadButtonVariant.destructive:
      case ShadButtonVariant.default_:
        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: style.copyWith(
            padding: WidgetStateProperty.all(padding),
          ),
          child: child,
        );
    }
  }

  ButtonStyle _getButtonStyle(ShadButtonVariant variant, bool isDisabled) {
    final disabledStyle = isDisabled
        ? Colors.grey.withValues(alpha: 0.5)
        : null;

    switch (variant) {
      case ShadButtonVariant.default_:
        return ElevatedButton.styleFrom(
          backgroundColor: disabledStyle ?? AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );

      case ShadButtonVariant.outline:
        return OutlinedButton.styleFrom(
          foregroundColor: disabledStyle ?? AppColors.textPrimary,
          side: BorderSide(
            color: disabledStyle ?? AppColors.border,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );

      case ShadButtonVariant.ghost:
        return TextButton.styleFrom(
          foregroundColor: disabledStyle ?? AppColors.textPrimary,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(
            AppColors.surfaceAlt,
          ),
        );

      case ShadButtonVariant.link:
        return TextButton.styleFrom(
          foregroundColor: disabledStyle ?? AppColors.primary,
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ).copyWith(
          overlayColor: WidgetStateProperty.all(Colors.transparent),
        );

      case ShadButtonVariant.destructive:
        return ElevatedButton.styleFrom(
          backgroundColor: disabledStyle ?? AppColors.danger,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
    }
  }

  EdgeInsets _getSizeStyle(ShadButtonSize size) {
    switch (size) {
      case ShadButtonSize.sm:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 8,
        );
      case ShadButtonSize.md:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 10,
        );
      case ShadButtonSize.lg:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: 12,
        );
      case ShadButtonSize.icon:
        return const EdgeInsets.all(10);
    }
  }
}

