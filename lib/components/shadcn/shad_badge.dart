import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';

enum ShadBadgeVariant {
  default_,
  secondary,
  destructive,
  outline,
}

class ShadBadge extends StatelessWidget {
  const ShadBadge({
    super.key,
    required this.label,
    this.variant = ShadBadgeVariant.default_,
  });

  final String label;
  final ShadBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final style = _getVariantStyle(variant);
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        border: style.border,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: style.textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _BadgeStyle _getVariantStyle(ShadBadgeVariant variant) {
    switch (variant) {
      case ShadBadgeVariant.default_:
        return _BadgeStyle(
          backgroundColor: AppColors.primary,
          textColor: Colors.white,
          border: null,
        );
      case ShadBadgeVariant.secondary:
        return _BadgeStyle(
          backgroundColor: AppColors.surfaceAlt,
          textColor: AppColors.textSecondary,
          border: null,
        );
      case ShadBadgeVariant.destructive:
        return _BadgeStyle(
          backgroundColor: AppColors.danger,
          textColor: Colors.white,
          border: null,
        );
      case ShadBadgeVariant.outline:
        return _BadgeStyle(
          backgroundColor: Colors.transparent,
          textColor: AppColors.textPrimary,
          border: Border.all(color: AppColors.border),
        );
    }
  }
}

class _BadgeStyle {
  final Color backgroundColor;
  final Color textColor;
  final Border? border;

  _BadgeStyle({
    required this.backgroundColor,
    required this.textColor,
    this.border,
  });
}

