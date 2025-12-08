import 'package:flutter/foundation.dart';
import 'dart:html' as html;

/// Handle deep links for invite tokens
class DeepLinkHandler {
  /// Get invite token from URL parameters
  /// Works for web: ?token=XYZ
  static String? getInviteTokenFromUrl() {
    if (kIsWeb) {
      final uri = Uri.parse(html.window.location.href);
      return uri.queryParameters['token'];
    }
    // For mobile, you would use Firebase Dynamic Links or uni_links package
    // For now, return null for non-web platforms
    return null;
  }

  /// Clear invite token from URL (web only)
  static void clearInviteTokenFromUrl() {
    if (kIsWeb) {
      final uri = Uri.parse(html.window.location.href);
      final newUri = uri.replace(queryParameters: {});
      html.window.history.replaceState(null, '', newUri.toString());
    }
  }
}

