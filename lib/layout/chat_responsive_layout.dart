import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/responsive_utils.dart';
import '../widgets/mobile_bottom_nav.dart';
import '../providers/dashboard_provider.dart';
import 'chat_desktop_view.dart';
import 'chat_tablet_view.dart';
import 'chat_mobile_view.dart';

/// Responsive layout wrapper for chat module
class ChatResponsiveLayout extends StatelessWidget {
  const ChatResponsiveLayout({
    super.key,
    required this.chatListWidget,
    required this.chatWindowWidget,
    required this.onBackPressed,
    required this.showChatList,
  });

  final Widget chatListWidget;
  final Widget chatWindowWidget;
  final VoidCallback onBackPressed;
  final bool showChatList;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    // Get current tab from provider
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

    Widget content;
    
    if (isDesktop) {
      // Desktop: Full sidebar + Chat List + Chat Window
      content = ChatDesktopView(
        chatListWidget: chatListWidget,
        chatWindowWidget: chatWindowWidget,
      );
    } else if (isTablet) {
      // Tablet: Sidebar drawer + Chat List + Chat Window + Bottom Nav
      content = ChatTabletView(
        chatListWidget: chatListWidget,
        chatWindowWidget: chatWindowWidget,
      );
    } else {
      // Mobile: One screen at a time + Bottom Nav
      content = ChatMobileView(
        chatListWidget: chatListWidget,
        chatWindowWidget: chatWindowWidget,
        showChatList: showChatList,
        onBackPressed: onBackPressed,
      );
    }

    // Add bottom navigation for mobile and tablet
    if (isMobile || isTablet) {
      return Scaffold(
        body: content,
        bottomNavigationBar: MobileBottomNav(
          currentTab: dashboardProvider.activeTab,
          onTabChanged: (tab) {
            dashboardProvider.changeTab(tab);
          },
        ),
      );
    }

    return content;
  }
}

