/// Stub implementation for mobile platforms
class DeepLinkHandler {
  /// Get invite token from URL parameters
  /// Returns null on mobile (would need Firebase Dynamic Links or uni_links)
  static String? getInviteTokenFromUrl() {
    // For mobile, you would use Firebase Dynamic Links or uni_links package
    // For now, return null for non-web platforms
    return null;
  }

  /// Clear invite token from URL (web only)
  /// No-op on mobile
  static void clearInviteTokenFromUrl() {
    // No-op on mobile
  }
}







