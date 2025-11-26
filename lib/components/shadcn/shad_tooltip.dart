import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

/// Enhanced tooltip component with shadcn-style design
class ShadTooltip extends StatelessWidget {
  const ShadTooltip({
    super.key,
    required this.message,
    required this.child,
    this.placement = ShadTooltipPlacement.top,
    this.waitDuration = const Duration(milliseconds: 300),
  });

  final String message;
  final Widget child;
  final ShadTooltipPlacement placement;
  final Duration waitDuration;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      waitDuration: waitDuration,
      preferBelow: placement == ShadTooltipPlacement.bottom,
      verticalOffset: placement == ShadTooltipPlacement.top ? 8 : -8,
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: child,
    );
  }
}

enum ShadTooltipPlacement {
  top,
  bottom,
  left,
  right,
}

