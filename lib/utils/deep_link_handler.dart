// Conditional imports for web vs mobile
import 'deep_link_handler_stub.dart'
    if (dart.library.html) 'deep_link_handler_web.dart' as implementation;

/// Handle deep links for invite tokens
class DeepLinkHandler {
  /// Get invite token from URL parameters
  /// Works for web: ?token=XYZ
  /// For mobile, returns null (would need Firebase Dynamic Links or uni_links)
  static String? getInviteTokenFromUrl() {
    return implementation.DeepLinkHandler.getInviteTokenFromUrl();
  }

  /// Clear invite token from URL (web only)
  static void clearInviteTokenFromUrl() {
    implementation.DeepLinkHandler.clearInviteTokenFromUrl();
  }
}

