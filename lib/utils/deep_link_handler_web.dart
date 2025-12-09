import 'dart:html' as html;

/// Web implementation for deep link handling
class DeepLinkHandler {
  /// Get invite token from URL parameters
  /// Works for web: ?token=XYZ
  static String? getInviteTokenFromUrl() {
    final uri = Uri.parse(html.window.location.href);
    return uri.queryParameters['token'];
  }

  /// Clear invite token from URL (web only)
  static void clearInviteTokenFromUrl() {
    final uri = Uri.parse(html.window.location.href);
    final newUri = uri.replace(queryParameters: {});
    html.window.history.replaceState(null, '', newUri.toString());
  }
}


