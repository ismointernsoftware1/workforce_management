import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart' as spacing;

enum ShadAlertVariant {
  default_,
  destructive,
  success,
  warning,
}

class ShadAlert extends StatelessWidget {
  const ShadAlert({
    super.key,
    required this.title,
    this.description,
    this.variant = ShadAlertVariant.default_,
    this.icon,
    this.actions,
  });

  final String title;
  final String? description;
  final ShadAlertVariant variant;
  final Widget? icon;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final style = _getVariantStyle(variant);
    final defaultIcon = _getDefaultIcon(variant);

    return Container(
      padding: const EdgeInsets.all(spacing.AppSpacing.md),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        border: Border.all(color: style.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon ?? defaultIcon,
          const SizedBox(width: spacing.AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: style.titleColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: spacing.AppSpacing.xs),
                  Text(
                    description!,
                    style: TextStyle(
                      color: style.descriptionColor,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (actions != null && actions!.isNotEmpty) ...[
                  const SizedBox(height: spacing.AppSpacing.sm),
                  Wrap(
                    spacing: spacing.AppSpacing.sm,
                    children: actions!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  _AlertStyle _getVariantStyle(ShadAlertVariant variant) {
    switch (variant) {
      case ShadAlertVariant.default_:
        return _AlertStyle(
          backgroundColor: AppColors.primarySoft,
          borderColor: AppColors.primary.withValues(alpha: 0.3),
          titleColor: AppColors.primary,
          descriptionColor: AppColors.textSecondary,
        );
      case ShadAlertVariant.destructive:
        return _AlertStyle(
          backgroundColor: AppColors.danger.withValues(alpha: 0.1),
          borderColor: AppColors.danger.withValues(alpha: 0.3),
          titleColor: AppColors.danger,
          descriptionColor: AppColors.textSecondary,
        );
      case ShadAlertVariant.success:
        return _AlertStyle(
          backgroundColor: AppColors.success.withValues(alpha: 0.1),
          borderColor: AppColors.success.withValues(alpha: 0.3),
          titleColor: AppColors.success,
          descriptionColor: AppColors.textSecondary,
        );
      case ShadAlertVariant.warning:
        return _AlertStyle(
          backgroundColor: AppColors.warning.withValues(alpha: 0.1),
          borderColor: AppColors.warning.withValues(alpha: 0.3),
          titleColor: AppColors.warning,
          descriptionColor: AppColors.textSecondary,
        );
    }
  }

  Widget _getDefaultIcon(ShadAlertVariant variant) {
    IconData iconData;
    Color iconColor;

    switch (variant) {
      case ShadAlertVariant.default_:
        iconData = Icons.info_outline_rounded;
        iconColor = AppColors.primary;
        break;
      case ShadAlertVariant.destructive:
        iconData = Icons.error_outline_rounded;
        iconColor = AppColors.danger;
        break;
      case ShadAlertVariant.success:
        iconData = Icons.check_circle_outline_rounded;
        iconColor = AppColors.success;
        break;
      case ShadAlertVariant.warning:
        iconData = Icons.warning_amber_rounded;
        iconColor = AppColors.warning;
        break;
    }

    return Icon(iconData, color: iconColor, size: 20);
  }
}

class _AlertStyle {
  final Color backgroundColor;
  final Color borderColor;
  final Color titleColor;
  final Color descriptionColor;

  _AlertStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.titleColor,
    required this.descriptionColor,
  });
}

