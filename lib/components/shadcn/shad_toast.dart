import 'package:flutter/material.dart';

import '../../components/shadcn/shad_alert.dart';

/// Toast notification wrapper with shadcn-style design
class ShadToast {
  static void show(
    BuildContext context, {
    required String title,
    String? description,
    ShadToastVariant variant = ShadToastVariant.default_,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ShadAlert(
          title: title,
          description: description,
          variant: _mapVariant(variant),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: const EdgeInsets.all(16),
        behavior: SnackBarBehavior.floating,
        duration: duration,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static ShadAlertVariant _mapVariant(ShadToastVariant variant) {
    switch (variant) {
      case ShadToastVariant.default_:
        return ShadAlertVariant.default_;
      case ShadToastVariant.success:
        return ShadAlertVariant.success;
      case ShadToastVariant.error:
        return ShadAlertVariant.destructive;
      case ShadToastVariant.warning:
        return ShadAlertVariant.warning;
      case ShadToastVariant.info:
        return ShadAlertVariant.info;
    }
  }
}

enum ShadToastVariant {
  default_,
  success,
  error,
  warning,
  info,
}

