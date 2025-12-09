import 'package:flutter/material.dart';

/// Tablet layout: Sidebar drawer + Chat List + Chat Window
class ChatTabletView extends StatefulWidget {
  const ChatTabletView({
    super.key,
    required this.chatListWidget,
    required this.chatWindowWidget,
  });

  final Widget chatListWidget;
  final Widget chatWindowWidget;

  @override
  State<ChatTabletView> createState() => _ChatTabletViewState();
}

class _ChatTabletViewState extends State<ChatTabletView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        width: 280,
        child: Container(
          color: const Color(0xFF1F2937),
          // TODO: Add sidebar content here
        ),
      ),
      body: Row(
        children: [
          // Chat list panel
          Container(
            width: 350,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(
                  color: Color(0xFFE4E7EC),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              children: [
                // Hamburger menu button
                Container(
                  padding: const EdgeInsets.all(16),
                  child: IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                ),
                Expanded(child: widget.chatListWidget),
              ],
            ),
          ),
          // Chat window
          Expanded(
            child: Container(
              color: const Color(0xFFF5F6FA),
              child: widget.chatWindowWidget,
            ),
          ),
        ],
      ),
    );
  }
}

