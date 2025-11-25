import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/chat_widgets.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final selectedConversation = provider.selectedConversation;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search conversations...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = provider.conversations[index];
                      return ConversationTile(
                        conversation: conversation,
                        isSelected:
                            conversation.id == provider.selectedConversationId,
                        onTap: () =>
                            provider.selectConversation(conversation.id),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('New conversation'),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.2),
                          child: Text(
                            (selectedConversation?.topic ?? '--')
                                .substring(0, 1)
                                .toUpperCase(),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedConversation?.topic ?? 'Select chat',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${selectedConversation?.members.length ?? 0} members',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.call),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.videocam_rounded),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.more_horiz),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      itemCount: selectedConversation?.messages.length ?? 0,
                      itemBuilder: (context, index) {
                        final message =
                            selectedConversation!.messages[index];
                        return MessageBubble(message: message);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.attach_file),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                            ),
                            onSubmitted: (_) => _send(provider),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(AppSpacing.md),
                          ),
                          onPressed: () => _send(provider),
                          child: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _send(DashboardProvider provider) {
    final text = _controller.text;
    provider.sendMessage(text);
    _controller.clear();
  }
}

