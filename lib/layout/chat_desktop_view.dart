import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../views/widgets/sidebar.dart';

/// Desktop layout: Sidebar + Chat List + Chat Window
class ChatDesktopView extends StatelessWidget {
  const ChatDesktopView({
    super.key,
    required this.chatListWidget,
    required this.chatWindowWidget,
  });

  final Widget chatListWidget;
  final Widget chatWindowWidget;

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    return Row(
      children: [
        // Left sidebar
        Sidebar(
          activeTab: dashboardProvider.activeTab,
          onTabChanged: (tab) {
            dashboardProvider.changeTab(tab);
          },
        ),
        // Chat list panel
        Container(
          width: 400,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(
                color: Color(0xFFE4E7EC),
                width: 0.5,
              ),
            ),
          ),
          child: chatListWidget,
        ),
        // Chat window
        Expanded(
          child: Container(
            color: const Color(0xFFF5F6FA),
            child: chatWindowWidget,
          ),
        ),
      ],
    );
  }
}

