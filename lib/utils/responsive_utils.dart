import 'package:flutter/material.dart';

/// Responsive breakpoints for the application
class ResponsiveBreakpoints {
  /// Mobile breakpoint: < 768px
  static const double mobile = 768.0;
  
  /// Tablet breakpoint: 768px - 1024px
  static const double tablet = 1024.0;
  
  /// Desktop breakpoint: > 1024px
  static const double desktop = 1024.0;
}

/// Responsive utility class for common responsive operations
class ResponsiveUtils {
  /// Check if current screen is mobile (< 768px)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < ResponsiveBreakpoints.mobile;
  }
  
  /// Check if current screen is tablet (768px - 1024px)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= ResponsiveBreakpoints.mobile && 
           width < ResponsiveBreakpoints.tablet;
  }
  
  /// Check if current screen is desktop (> 1024px)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= ResponsiveBreakpoints.desktop;
  }
  
  /// Get responsive padding based on screen size
  static EdgeInsets getPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }
  
  /// Get responsive horizontal padding
  static EdgeInsets getHorizontalPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24);
    } else {
      return const EdgeInsets.symmetric(horizontal: 32);
    }
  }
  
  /// Get responsive font size
  static double getFontSize(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile * 1.2;
    } else {
      return desktop ?? tablet ?? mobile * 1.4;
    }
  }
  
  /// Get responsive grid cross axis count
  static int getGridCrossAxisCount(BuildContext context, {
    required int mobile,
    int? tablet,
    int? desktop,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile + 1;
    } else {
      return desktop ?? tablet ?? mobile + 2;
    }
  }
  
  /// Get responsive width factor (0.0 to 1.0)
  static double getWidthFactor(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return desktop ?? tablet ?? 1.0;
    }
  }
}

/// Extension methods for BuildContext to easily access responsive utilities
extension ResponsiveExtension on BuildContext {
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);
  
  EdgeInsets get responsivePadding => ResponsiveUtils.getPadding(this);
  EdgeInsets get responsiveHorizontalPadding => ResponsiveUtils.getHorizontalPadding(this);
}

