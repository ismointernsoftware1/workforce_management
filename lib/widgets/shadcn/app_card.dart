import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';

/// Generic reusable card widget
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.showShadow = true,
    this.borderRadius,
    this.border,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final bool showShadow;
  final BorderRadiusGeometry? borderRadius;
  final Border? border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: border ??
            Border.all(
              color: AppColors.border.withValues(alpha: 0.5),
              width: 1,
            ),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      final radius = borderRadius is BorderRadius 
          ? borderRadius as BorderRadius 
          : BorderRadius.circular(12);
      return InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: card,
      );
    }

    return card;
  }
}

