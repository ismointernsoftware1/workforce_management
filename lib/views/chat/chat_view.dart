import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:shadcn_ui/shadcn_ui.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/chat_widgets.dart';
import '../../widgets/shadcn/shadcn_widgets.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final selectedConversation = provider.selectedConversation;
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Padding(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.xl),
      child: isMobile
          ? _buildMobileLayout(context, provider, selectedConversation)
          : _buildDesktopLayout(context, provider, selectedConversation),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    DashboardProvider provider,
    selectedConversation,
  ) {
    if (provider.selectedConversationId == null || provider.selectedConversationId!.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Messages',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.8,
                height: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppSearchInput(
              controller: _searchController,
              placeholder: 'Search conversations...',
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView.builder(
                itemCount: _getFilteredConversations(provider).length,
                itemBuilder: (context, index) {
                  final conversation = _getFilteredConversations(provider)[index];
                  return ConversationTile(
                    conversation: conversation,
                    isSelected: conversation.id == provider.selectedConversationId,
                    onTap: () => provider.selectConversation(conversation.id),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              onPressed: () {},
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 20),
                  SizedBox(width: 4),
                  Text('New conversation'),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Back button
        Row(
          children: [
            ShadIconButton(
              onPressed: () {
                // Clear selection by selecting empty string
                provider.selectConversation('');
              },
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text(
              'Back to Messages',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: _buildChatView(context, provider, selectedConversation),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    DashboardProvider provider,
    selectedConversation,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 280,
          child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppSearchInput(
                  controller: _searchController,
                  placeholder: 'Search conversations...',
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: ListView.builder(
                    itemCount: _getFilteredConversations(provider).length,
                    itemBuilder: (context, index) {
                      final conversation = _getFilteredConversations(provider)[index];
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
                AppButton(
                  onPressed: () {},
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 20),
                      SizedBox(width: 4),
                      Text('New conversation'),
                    ],
                  ),
                ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: _buildChatView(context, provider, selectedConversation),
          ),
        ],
      );
  }

  Widget _buildChatView(
    BuildContext context,
    DashboardProvider provider,
    selectedConversation,
  ) {
    return AppCard(
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(32),
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
                          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                          child: Text(
                            (selectedConversation?.topic ?? '--')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
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
                        ShadIconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.call, color: AppColors.textMuted),
                        ),
                        ShadIconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.videocam_rounded, color: AppColors.textMuted),
                        ),
                        ShadIconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.more_horiz, color: AppColors.textMuted),
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
                        ShadIconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.attach_file, color: AppColors.textMuted),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _send(provider),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        ShadIconButton(
                          onPressed: () => _send(provider),
                          icon: const Icon(Icons.send, color: Colors.white),
                        ),
                      ],
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

  List<dynamic> _getFilteredConversations(DashboardProvider provider) {
    if (_searchQuery.isEmpty) {
      return provider.conversations;
    }
    
    final query = _searchQuery.toLowerCase();
    return provider.conversations.where((conversation) {
      return conversation.topic.toLowerCase().contains(query) ||
          conversation.preview.toLowerCase().contains(query) ||
          conversation.members.any((memberId) => 
              memberId.toLowerCase().contains(query));
    }).toList();
  }
}

