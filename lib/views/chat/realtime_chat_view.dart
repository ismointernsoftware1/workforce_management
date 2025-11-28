import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../components/shadcn/shadcn.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/realtime_chat_models.dart';
import '../../providers/realtime_chat_provider.dart';
import '../../utils/responsive_utils.dart';
import 'create_group_dialog.dart';
import 'group_members_view.dart';
import 'new_direct_message_dialog.dart';

class RealtimeChatView extends StatefulWidget {
  const RealtimeChatView({super.key});

  @override
  State<RealtimeChatView> createState() => _RealtimeChatViewState();
}

class _RealtimeChatViewState extends State<RealtimeChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showMembers = false;
  bool _showConversationList = true;

  @override
  void initState() {
    super.initState();
    // Load conversations after the first frame using microtask to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<RealtimeChatProvider>();
        provider.scheduleLoadConversations();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    
    // On mobile, show either conversation list OR chat view, not both
    if (isMobile) {
      if (_showConversationList) {
        return Padding(
          padding: ResponsiveUtils.getPadding(context),
          child: _buildConversationList(context),
        );
      } else {
        return Padding(
          padding: ResponsiveUtils.getPadding(context),
          child: _buildChatView(context, isMobile),
        );
      }
    }
    
    // Desktop/Tablet: Show both side by side
    return Padding(
      padding: ResponsiveUtils.getPadding(context),
      child: Row(
        children: [
          // Left sidebar with conversations
          SizedBox(
            width: isTablet ? 240.0 : 280.0,
            child: _buildConversationList(context),
          ),
          const SizedBox(width: AppSpacing.md),
          // Main chat area
          Expanded(
            child: _buildChatView(context, isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList(BuildContext context) {
    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            // Search bar
            SizedBox(
              width: double.infinity,
              child: ShadInput(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Tabs
            Consumer<RealtimeChatProvider>(
              builder: (context, provider, _) {
                final isInbox = provider.activeTab == ChatTab.inbox;
                return Row(
                  children: [
                    Expanded(
                      child: _TabButton(
                        icon: Icons.message,
                        label: 'Messages',
                        isActive: isInbox,
                        onTap: () {
                          provider.setActiveTab(ChatTab.inbox);
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _TabButton(
                        icon: Icons.group,
                        label: 'Group',
                        isActive: !isInbox,
                        onTap: () {
                          provider.setActiveTab(ChatTab.explore);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            // Conversations list
            Expanded(
              child: Consumer<RealtimeChatProvider>(
                builder: (context, provider, _) {
                  final conversations = provider.activeTab == ChatTab.inbox
                      ? provider.directConversations
                      : provider.groupConversations;

                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (conversations.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            provider.activeTab == ChatTab.inbox
                                ? Icons.inbox_outlined
                                : Icons.group_outlined,
                            size: 32,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            provider.activeTab == ChatTab.inbox
                                ? 'No messages'
                                : 'No groups',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      final isSelected =
                          conversation.id == provider.selectedConversationId;
                      final displayName =
                          provider.conversationTitle(conversation);
                      return RealtimeConversationTile(
                        conversation: conversation,
                        displayName: displayName,
                        isSelected: isSelected,
                        onTap: () {
                          provider.selectConversation(conversation.id);
                          // On mobile, hide conversation list after selection
                          if (ResponsiveUtils.isMobile(context)) {
                            setState(() {
                              _showConversationList = false;
                            });
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Action buttons
            Consumer<RealtimeChatProvider>(
              builder: (context, provider, _) {
                if (provider.activeTab == ChatTab.explore) {
                  return ShadButton(
                    onPressed: () => _showCreateGroupDialog(context, provider),
                    variant: ShadButtonVariant.default_,
                    size: ShadButtonSize.sm,
                    icon: const Icon(Icons.add, size: 16),
                    width: double.infinity,
                    child: const Text(
                      'Create Group',
                      style: TextStyle(fontSize: 13),
                    ),
                  );
                } else {
                  return ShadButton(
                    onPressed: () => _showNewDirectMessageDialog(context, provider),
                    variant: ShadButtonVariant.default_,
                    size: ShadButtonSize.sm,
                    icon: const Icon(Icons.add, size: 16),
                    width: double.infinity,
                    child: const Text(
                      'New conversation',
                      style: TextStyle(fontSize: 13),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatView(BuildContext context, bool isMobile) {
    return Consumer<RealtimeChatProvider>(
      builder: (context, provider, _) {
        final selectedConversation = provider.selectedConversation;

        if (selectedConversation == null) {
          return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.chat_bubble_outline,
                              size: ResponsiveUtils.getFontSize(
                                context,
                                mobile: 48,
                                tablet: 56,
                                desktop: 64,
                              ),
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            'Select a conversation',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: ResponsiveUtils.getFontSize(
                                context,
                                mobile: 20,
                                tablet: 22,
                                desktop: 24,
                              ),
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            isMobile
                                ? 'Tap the menu to view conversations'
                                : 'Choose a conversation from the sidebar to start chatting',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: ResponsiveUtils.getFontSize(
                                context,
                                mobile: 14,
                                tablet: 15,
                                desktop: 15,
                              ),
                              height: 1.5,
                            ),
                          ),
                          if (isMobile) ...[
                            const SizedBox(height: AppSpacing.xl),
                            ShadButton(
                              onPressed: () {
                                setState(() {
                                  _showConversationList = true;
                                });
                              },
                              variant: ShadButtonVariant.default_,
                              size: ShadButtonSize.md,
                              icon: const Icon(Icons.message, size: 18),
                              child: const Text('View Conversations'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
        }

        final isGroupConversation =
            selectedConversation.type == ConversationType.group;
        if (_showMembers && !isGroupConversation) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _showMembers = false);
            }
          });
        }
        final showMembersPanel = _showMembers && isGroupConversation;

        return Container(
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppColors.border.withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Back button on mobile
                                  if (isMobile)
                                    ShadButton(
                                      onPressed: () {
                                        setState(() {
                                          _showConversationList = true;
                                        });
                                      },
                                      variant: ShadButtonVariant.ghost,
                                      size: ShadButtonSize.icon,
                                      icon: const Icon(Icons.arrow_back, size: 18),
                                      child: const SizedBox.shrink(),
                                    ),
                                  if (isMobile) const SizedBox(width: AppSpacing.xs),
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.primary.withValues(alpha: 0.2),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        provider.selectedConversationTitle
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          provider.selectedConversationTitle,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: ResponsiveUtils.getFontSize(
                                              context,
                                              mobile: 15,
                                              tablet: 16,
                                              desktop: 16,
                                            ),
                                            color: AppColors.textPrimary,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        if (isGroupConversation)
                                          Text(
                                            '${selectedConversation.memberIds.length} members',
                                            style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: ResponsiveUtils.getFontSize(
                                                context,
                                                mobile: 10,
                                                tablet: 11,
                                                desktop: 11,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // 3-dot menu for group conversations only
                                  if (isGroupConversation) ...[
                                    const SizedBox(width: AppSpacing.xs),
                                    ShadButton(
                                      onPressed: () {
                                        if (isMobile) {
                                          // Navigate to members page on mobile
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => GroupMembersView(
                                                conversation: selectedConversation,
                                              ),
                                            ),
                                          );
                                        } else {
                                          // Toggle members panel on desktop
                                          setState(() {
                                            _showMembers = !_showMembers;
                                          });
                                        }
                                      },
                                      variant: ShadButtonVariant.ghost,
                                      size: ShadButtonSize.icon,
                                      icon: const Icon(Icons.more_horiz, size: 18),
                                      child: const SizedBox.shrink(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Messages
                            Expanded(
                              child: StreamBuilder<List<RealtimeChatMessage>>(
                                stream: provider.messagesStream,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                          ConnectionState.waiting &&
                                      !snapshot.hasData &&
                                      !snapshot.hasError) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  if (snapshot.hasError) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            size: 48,
                                            color: AppColors.textMuted,
                                          ),
                                          const SizedBox(height: AppSpacing.md),
                                          Text(
                                            'Error loading messages',
                                            style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: AppSpacing.sm),
                                          Text(
                                            snapshot.error.toString(),
                                            style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 12,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  final messages = snapshot.data ?? [];

                                  if (messages.isEmpty) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.chat_bubble_outline,
                                            size: 48,
                                            color: AppColors.textMuted,
                                          ),
                                          const SizedBox(height: AppSpacing.md),
                                          Text(
                                            'No messages yet',
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: AppSpacing.sm),
                                          Text(
                                            'Start the conversation!',
                                            style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    _scrollToBottom();
                                  });

                                  return ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg,
                                      vertical: AppSpacing.md,
                                    ),
                                    itemCount: messages.length,
                                    itemBuilder: (context, index) {
                                      final message = messages[index];
                                      final isMine = message.senderId ==
                                          provider.currentUserId;
                                      return RealtimeMessageBubble(
                                        message: message,
                                        isMine: isMine,
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            // Input area
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: AppColors.border),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: AppColors.border.withValues(alpha: 0.5),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.02),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: TextField(
                                        controller: _messageController,
                                        decoration: const InputDecoration(
                                          hintText: 'Type a message...',
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 12,
                                          ),
                                          hintStyle: TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 15,
                                          ),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                          height: 1.4,
                                        ),
                                        maxLines: null,
                                        textInputAction: TextInputAction.newline,
                                        onSubmitted: (_) => _sendMessage(provider),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _sendMessage(provider),
                                        borderRadius: BorderRadius.circular(24),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          child: const Icon(
                                            Icons.send_rounded,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isMobile)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          width: showMembersPanel ? 260 : 0,
                          child: showMembersPanel
                              ? _MembersPanel(
                                  conversation: selectedConversation,
                                  onClose: () =>
                                      setState(() => _showMembers = false),
                                )
                              : null,
                        ),
                    ],
                  ),
                );
      },
    );
  }

  void _sendMessage(RealtimeChatProvider provider) {
    final text = _messageController.text.trim();
    if (text.isEmpty || provider.selectedConversationId == null) return;

    // Clear input immediately for better UX
    _messageController.clear();
    
    // Send message and handle errors
    provider.sendMessage(text).then((_) {
      // Message sent successfully, scroll to bottom
      _scrollToBottom();
    }).catchError((error) {
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: ${error.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
        // Restore text if there was an error
        _messageController.text = text;
      }
    });
  }

  void _showCreateGroupDialog(
    BuildContext context,
    RealtimeChatProvider provider,
  ) async {
    try {
      final users = await provider.getUsers();
      if (!mounted) return;

      if (users.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No other members available to add.'),
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => CreateGroupDialog(
          users: users,
          provider: provider,
          onGroupCreated: (groupId) {
            provider.loadConversations();
            provider.selectConversation(groupId);
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load members: $e')),
      );
    }
  }

  void _showNewDirectMessageDialog(
    BuildContext context,
    RealtimeChatProvider provider,
  ) async {
    try {
      final users = await provider.getUsers();
      if (!mounted) return;

      if (users.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No other users available. Add more team members first.'),
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => NewDirectMessageDialog(
          users: users,
          provider: provider,
          onConversationCreated: (conversationId) {
            provider.loadConversations();
            provider.selectConversation(conversationId);
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load users: $e')),
      );
    }
  }

}

class _MembersPanel extends StatelessWidget {
  const _MembersPanel({
    required this.conversation,
    required this.onClose,
  });

  final RealtimeChatConversation conversation;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final members = conversation.memberNames.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          left: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${conversation.name} members',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${members.length}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: members.isEmpty
                ? const Center(
                    child: Text(
                      'No members yet',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: members.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final entry = members[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          child: Text(
                            entry.value.isNotEmpty
                                ? entry.value.substring(0, 1).toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(
                          entry.value,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class RealtimeConversationTile extends StatelessWidget {
  const RealtimeConversationTile({
    super.key,
    required this.conversation,
    required this.displayName,
    required this.isSelected,
    required this.onTap,
  });

  final RealtimeChatConversation conversation;
  final String displayName;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('h:mm a');
    final time = DateTime.fromMillisecondsSinceEpoch(conversation.lastMessageTime);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Text(
                  displayName.isNotEmpty
                      ? displayName.substring(0, 2).toUpperCase()
                      : '--',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      conversation.lastMessage,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatter.format(time),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                  if (conversation.unreadCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          conversation.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RealtimeMessageBubble extends StatelessWidget {
  const RealtimeMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
  });

  final RealtimeChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('HH:mm');
    final time = DateTime.fromMillisecondsSinceEpoch(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          margin: EdgeInsets.only(
            bottom: 4,
            right: isMine ? 0 : 8,
            left: isMine ? 8 : 0,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isMine ? AppColors.primary : AppColors.surface,
            border: isMine
                ? null
                : Border.all(
                    color: AppColors.border.withValues(alpha: 0.5),
                    width: 1,
                  ),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
            boxShadow: isMine
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMine) ...[
                Text(
                  message.senderName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                message.text,
                style: TextStyle(
                  color: isMine ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.4,
                  letterSpacing: 0.1,
                ),
              ),
              if (message.attachmentUrl != null) ...[
                const SizedBox(height: 6),
                if (message.type == MessageType.image)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      message.attachmentUrl!,
                      width: 160,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isMine
                          ? Colors.white.withValues(alpha: 0.2)
                          : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isMine
                            ? Colors.white.withValues(alpha: 0.3)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getFileIcon(message.fileName),
                          color: isMine ? Colors.white : AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message.fileName ?? 'File',
                              style: TextStyle(
                                color: isMine ? Colors.white : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            if (message.fileSize != null)
                              Text(
                                _formatFileSize(message.fileSize!),
                                style: TextStyle(
                                  color: isMine
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : AppColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 4),
              Text(
                formatter.format(time),
                style: TextStyle(
                  color: isMine
                      ? Colors.white.withValues(alpha: 0.8)
                      : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String? fileName) {
    if (fileName == null) return Icons.insert_drive_file;
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primarySoft
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? AppColors.primary : AppColors.textMuted,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

