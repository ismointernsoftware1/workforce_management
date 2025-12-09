import 'package:flutter/material.dart';

/// Mobile layout: One screen at a time (Chat List OR Chat Window)
class ChatMobileView extends StatelessWidget {
  const ChatMobileView({
    super.key,
    required this.chatListWidget,
    required this.chatWindowWidget,
    required this.showChatList,
    required this.onBackPressed,
  });

  final Widget chatListWidget;
  final Widget chatWindowWidget;
  final bool showChatList;
  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
      child: showChatList
          ? Container(
              key: const ValueKey('chatList'),
              color: Colors.white,
              child: chatListWidget,
            )
          : Container(
              key: const ValueKey('chatWindow'),
              color: const Color(0xFFF5F6FA),
              child: chatWindowWidget,
            ),
    );
  }
}

