import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../components/shadcn/shadcn.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/realtime_chat_models.dart';
import '../../models/user_model.dart';
import '../../providers/realtime_chat_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../utils/responsive_utils.dart';
import '../widgets/sidebar.dart';
import 'create_group_dialog.dart';

class RealtimeChatView extends StatefulWidget {
  const RealtimeChatView({super.key});

  @override
  State<RealtimeChatView> createState() => _RealtimeChatViewState();
}

class _RealtimeChatViewState extends State<RealtimeChatView> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showMembers = false;
  bool _showConversationList = true;
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoadingUsers = false;
  String _searchQuery = '';
  String? _creatingConversationWithUserId;
  Timer? _typingTimer;
  bool _isTyping = false;
  RealtimeChatProvider? _providerRef;
  Map<String, bool> _mutedConversations = {}; // Track muted conversations

  @override
  void initState() {
    super.initState();
    // Load conversations after the first frame using delayed callback to avoid blocking UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Use a small delay to ensure UI is fully rendered before loading data
        Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        final provider = context.read<RealtimeChatProvider>();
        _providerRef = provider;
        provider.scheduleLoadConversations();
        _loadUsers();
          }
        });
      }
    });
    _searchController.addListener(_onSearchChanged);
    _messageController.addListener(_onMessageChanged);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _messageController.removeListener(_onMessageChanged);
    // Clear typing status on dispose if still typing
    if (_isTyping && _providerRef != null) {
      _providerRef!.setTyping(false);
    }
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onMessageChanged() {
    if (!mounted) return;
    
    final provider = _providerRef ?? context.read<RealtimeChatProvider>();
    if (provider.selectedConversationId == null) {
      debugPrint('Cannot set typing: no conversation selected');
      return;
    }

    // Cancel existing timer
    _typingTimer?.cancel();

    final text = _messageController.text.trim();
    
    // If text is empty, clear typing status immediately
    if (text.isEmpty) {
      if (_isTyping) {
        debugPrint('Clearing typing status (text is empty)');
        _isTyping = false;
        provider.setTyping(false);
      }
      return;
    }

    // If user is typing and not already marked as typing
    if (!_isTyping) {
      debugPrint('Setting typing status to true');
      _isTyping = true;
      provider.setTyping(true);
    }

    // Set timer to clear typing status after 3 seconds of inactivity
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (_isTyping && mounted) {
        debugPrint('Clearing typing status (3 seconds inactivity)');
        _isTyping = false;
        provider.setTyping(false);
      }
    });
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    setState(() => _isLoadingUsers = true);
    try {
      final provider = context.read<RealtimeChatProvider>();
      final users = await provider.getUsers();
      // Filter out the current user
      final currentUserId = provider.currentUserId;
      _allUsers = users.where((user) => user.id != currentUserId).toList();
      _filteredUsers = _allUsers;
    } catch (e) {
      debugPrint('Error loading users: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredUsers = _allUsers.where((user) {
          return user.name.toLowerCase().contains(lowerQuery) ||
              user.email.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  // Group messages by date and return a list with date separators
  List<dynamic> _groupMessagesByDate(List<RealtimeChatMessage> messages) {
    if (messages.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final grouped = <dynamic>[];
    DateTime? currentDate;

    for (final message in messages) {
      final messageDate = DateTime.fromMillisecondsSinceEpoch(message.timestamp);
      final messageDay = DateTime(messageDate.year, messageDate.month, messageDate.day);

      // Check if we need to add a date separator
      if (currentDate == null || !currentDate.isAtSameMomentAs(messageDay)) {
        currentDate = messageDay;
        
        String dateLabel;
        if (messageDay.isAtSameMomentAs(today)) {
          dateLabel = 'Today';
        } else if (messageDay.isAtSameMomentAs(yesterday)) {
          dateLabel = 'Yesterday';
        } else {
          // Format as "MMM dd, yyyy" (e.g., "Jun 21, 2024")
          dateLabel = DateFormat('MMM dd, yyyy').format(messageDate);
        }
        
        grouped.add(dateLabel);
      }

      grouped.add(message);
    }

    return grouped;
  }

  Future<void> _startConversationWithUser(BuildContext context, UserModel user) async {
    // Prevent multiple clicks
    if (_creatingConversationWithUserId == user.id) return;
    
    if (!mounted) return;
    setState(() {
      _creatingConversationWithUserId = user.id;
    });

    try {
      // Clear search first
      _searchController.clear();
      setState(() {
        _searchQuery = '';
      });
      
      // Start conversation with this user
      final provider = context.read<RealtimeChatProvider>();
      
      // Create conversation - this will also reload conversations
      final conversationId = await provider.createDirectConversation(
        user.id,
        user.name,
      );
      
      if (!mounted) return;
      
      // Use a microtask to ensure state updates happen after the async operation
      await Future.microtask(() {
        if (!mounted) return;
        
        // Select the conversation
        provider.selectConversation(conversationId);
        
        // On mobile, switch to chat view
        if (ResponsiveUtils.isMobile(context)) {
          setState(() {
            _showConversationList = false;
          });
        }
      });
    } catch (e) {
      debugPrint('Error starting conversation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start conversation: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _creatingConversationWithUserId = null;
        });
      }
    }
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

  void _showMobileSidebar(BuildContext context) {
    final dashboardProvider = context.read<DashboardProvider>();
    final isMobile = ResponsiveUtils.isMobile(context);
    
    // Show sidebar dialog - responsive width
    final dialogWidth = isMobile 
        ? MediaQuery.of(context).size.width * 0.85
        : (ResponsiveUtils.isTablet(context) ? 300.0 : 280.0);
    
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        alignment: Alignment.centerLeft,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: SizedBox(
          width: dialogWidth,
          child: Sidebar(
            activeTab: dashboardProvider.activeTab,
            onTabChanged: (tab) {
              dashboardProvider.changeTab(tab);
              Navigator.of(dialogContext).pop();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    // For desktop/tablet we want the chat layout to be full-width with no
    // outer margins; on mobile we keep a small horizontal padding.
    final EdgeInsets pagePadding = isMobile
        ? EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
      AppSpacing.lg,
          )
        : EdgeInsets.zero;
    
    // On mobile, show either conversation list OR chat view, not both
    if (isMobile) {
      if (_showConversationList) {
        return Padding(
          padding: pagePadding,
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 
                MediaQuery.of(context).padding.top - 
                MediaQuery.of(context).padding.bottom - 
                (pagePadding.top + pagePadding.bottom),
          child: _buildConversationList(context),
          ),
        );
      } else {
        return Padding(
          padding: pagePadding,
          child: _buildChatView(context, isMobile),
        );
      }
    }
    
    // Desktop/Tablet: Show both side by side
    return Padding(
      padding: pagePadding,
      child: Row(
        children: [
          // Left sidebar with conversations - responsive width
          SizedBox(
            width: ResponsiveUtils.isDesktop(context) 
                ? 320.0 
                : (isTablet ? 280.0 : 260.0),
            child: _buildConversationList(context),
          ),
          // Remove visual gap between sidebar and chat area
          const SizedBox(width: 0),
          // Main chat area
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                // Rounded only on the outer right side so it joins the
                // sidebar without any visible gap.
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
              ),
              child: _buildChatView(context, isMobile),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    return LayoutBuilder(
      builder: (context, constraints) {
    return Container(
          height: isMobile ? constraints.maxHeight : null,
      decoration: BoxDecoration(
        color: AppColors.surface,
            // Rounded only on the outer left side so it sits flush against
            // the conversation panel with no gap in between.
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            // Chat header inside sidebar with hamburger menu
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.xs,
                right: AppSpacing.xs,
                bottom: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  // Hamburger menu button - visible on all screen sizes
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showMobileSidebar(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isMobile ? Colors.transparent : AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.menu,
                          size: 24,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Chat title
                  Expanded(
                    child: Text(
                      'Chat',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getFontSize(
                          context,
                          mobile: 18,
                          tablet: 20,
                          desktop: 22,
                        ),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Search bar
            SizedBox(
              width: double.infinity,
              child: ShadInput(
                controller: _searchController,
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textMuted),
              ),
            ),
            // Show search results if there's a query
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: _buildSearchResults(context),
              ),
            ] else ...[
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
              // Create Group button (only show in Group tab)
              Consumer<RealtimeChatProvider>(
                builder: (context, provider, _) {
                  if (provider.activeTab == ChatTab.explore) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ShadButton(
                        onPressed: () => _showCreateGroupDialog(context, provider),
                        variant: ShadButtonVariant.default_,
                        size: ShadButtonSize.sm,
                        icon: const Icon(Icons.group_add, size: 18),
                        child: const Text('Create Group'),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
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
                        final typingUsers = provider.getTypingUsersForConversation(conversation.id);
                        final isTyping = typingUsers.isNotEmpty;
                        return RealtimeConversationTile(
                          conversation: conversation,
                          displayName: displayName,
                          isSelected: isSelected,
                          currentUserId: provider.currentUserId,
                          isTyping: isTyping,
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
              // Action buttons removed (\"New conversation\" / \"Create Group\") per design request
            ],
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    if (_isLoadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 32,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No users found',
              style: const TextStyle(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        final isCreating = _creatingConversationWithUserId == user.id;
        return Material(
          color: Colors.transparent,
          child: InkWell(
          onTap: isCreating ? null : () => _startConversationWithUser(context, user),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.xs,
            ),
            child: Row(
              children: [
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
                      user.name.isNotEmpty
                          ? user.name.substring(0, 1).toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isCreating)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
              ],
            ),
            ),
          ),
        );
      },
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
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            // Header bar with conversation info
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: AppColors.border),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Back button for mobile
                                  if (isMobile)
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _showConversationList = true;
                                        });
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  if (isMobile) const SizedBox(width: AppSpacing.xs),
                                  // Avatar
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
                                        provider.selectedConversationTitle.isNotEmpty
                                            ? provider.selectedConversationTitle
                                                .substring(0, 1)
                                                .toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  // Conversation name and member count
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          provider.selectedConversationTitle,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (isGroupConversation) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            '${selectedConversation.memberIds.length} members',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // Silent / notifications toggle button
                                  IconButton(
                                    icon: Icon(
                                      _mutedConversations[selectedConversation.id] == true
                                          ? Icons.notifications_off_outlined
                                          : Icons.notifications_none_outlined,
                                      size: 18,
                                      color: _mutedConversations[selectedConversation.id] == true
                                          ? AppColors.textMuted
                                          : AppColors.textPrimary,
                                    ),
                                    tooltip: _mutedConversations[selectedConversation.id] == true
                                        ? 'Unmute notifications'
                                        : 'Mute notifications',
                                    onPressed: () {
                                      _toggleMuteConversation(provider, selectedConversation.id);
                                    },
                                  ),
                                  // Menu button
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textPrimary),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 8,
                                    color: AppColors.surface,
                                    onSelected: (value) {
                                      if (value == 'info') {
                                        _showConversationInfo(context, provider, selectedConversation);
                                      } else if (value == 'mute') {
                                        _toggleMuteConversation(provider, selectedConversation.id);
                                      } else if (value == 'members' && isGroupConversation) {
                                        setState(() {
                                          _showMembers = !_showMembers;
                                        });
                                      } else if (value == 'delete') {
                                        _showDeleteConfirmation(context, provider, selectedConversation);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      // Only show Conversation Info for direct conversations
                                      if (!isGroupConversation)
                                        PopupMenuItem(
                                          value: 'info',
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.md,
                                            vertical: AppSpacing.sm,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Icon(
                                                  Icons.info_outline,
                                                  size: 16,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                              const SizedBox(width: AppSpacing.sm),
                                              const Text(
                                                'Conversation Info',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      PopupMenuItem(
                                        value: 'mute',
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.md,
                                          vertical: AppSpacing.sm,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Icon(
                                                _mutedConversations[selectedConversation.id] == true
                                                    ? Icons.notifications
                                                    : Icons.notifications_off_outlined,
                                                size: 16,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.sm),
                                            Text(
                                              _mutedConversations[selectedConversation.id] == true
                                                  ? 'Unmute Notifications'
                                                  : 'Mute Notifications',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isGroupConversation)
                                        PopupMenuItem(
                                          value: 'members',
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.md,
                                            vertical: AppSpacing.sm,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Icon(
                                                  Icons.group_outlined,
                                                  size: 16,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                              const SizedBox(width: AppSpacing.sm),
                                              const Text(
                                                'View Members',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      const PopupMenuDivider(
                                        height: 1,
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.md,
                                          vertical: AppSpacing.sm,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: AppColors.danger.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Icon(
                                                Icons.delete_outline,
                                                size: 16,
                                                color: AppColors.danger,
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.sm),
                                            const Text(
                                              'Delete Conversation',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.danger,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Messages
                            Expanded(
                              child: StreamBuilder<List<RealtimeChatMessage>>(
                                key: ValueKey(provider.selectedConversationId),
                                stream: provider.messagesStream,
                                builder: (context, snapshot) {
                                  // Debug logging
                                  debugPrint('StreamBuilder state: connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}, hasError=${snapshot.hasError}, dataLength=${snapshot.data?.length ?? 0}');

                                  // Show loading ONLY if we're actively waiting AND don't have data yet
                                  // The stream emits empty list immediately, then updates with real data
                                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                                    // Still waiting for first data - show loading briefly
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  
                                  // If we have data (even if empty), proceed to show it
                                  if (!snapshot.hasData && snapshot.connectionState != ConnectionState.done) {
                                    // Still waiting
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  
                                  // At this point, we have data (even if empty) or are in active/done state
                                  // Proceed to show the data

                                  if (snapshot.hasError) {
                                    debugPrint('StreamBuilder error: ${snapshot.error}');
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
                                  debugPrint('Displaying ${messages.length} messages');

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

                                  // Group messages by date
                                  final groupedMessages = _groupMessagesByDate(messages);

                                  return Column(
                                    children: [
                                      Expanded(
                                        child: ListView.builder(
                                          controller: _scrollController,
                                          padding: EdgeInsets.only(
                                            left: AppSpacing.lg,
                                            right: AppSpacing.lg,
                                            bottom: AppSpacing.md,
                                            top: AppSpacing.sm,
                                          ),
                                          itemCount: groupedMessages.length,
                                          itemBuilder: (context, index) {
                                            final item = groupedMessages[index];
                                            if (item is String) {
                                              // Date separator
                                              return _DateSeparator(dateLabel: item);
                                            } else {
                                              // Message
                                              final message = item as RealtimeChatMessage;
                                            final isMine = message.senderId ==
                                                provider.currentUserId;
                                            return RealtimeMessageBubble(
                                              message: message,
                                              isMine: isMine,
                                            );
                                            }
                                          },
                                        ),
                                      ),
                                      // Typing indicator with WhatsApp-style animation (only dots)
                                      Consumer<RealtimeChatProvider>(
                                        builder: (context, provider, _) {
                                          final typingUsers = provider.typingUsers;
                                          if (typingUsers.isEmpty) {
                                            return const SizedBox.shrink();
                                          }

                                          return Padding(
                                            padding: EdgeInsets.only(
                                              left: AppSpacing.lg,
                                              right: AppSpacing.lg,
                                              bottom: AppSpacing.sm,
                                              top: AppSpacing.xs,
                                            ),
                                            child: Align(
                                            alignment: Alignment.centerLeft,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.surface,
                                                  border: Border.all(
                                                    color: AppColors.border.withValues(alpha: 0.5),
                                                    width: 1,
                                                  ),
                                                  borderRadius: const BorderRadius.only(
                                                    topLeft: Radius.circular(12),
                                                    topRight: Radius.circular(12),
                                                    bottomLeft: Radius.circular(4),
                                                    bottomRight: Radius.circular(12),
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.03),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 1),
                                                    ),
                                                  ],
                                                ),
                                                child: const _TypingDots(),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
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
                                        textInputAction: TextInputAction.send,
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

  Future<void> _showCreateGroupDialog(
    BuildContext context,
    RealtimeChatProvider provider,
  ) async {
    try {
      // Load users if not already loaded
      if (_allUsers.isEmpty) {
        setState(() {
          _isLoadingUsers = true;
        });
        final users = await provider.getUsers();
        if (mounted) {
          setState(() {
            _allUsers = users;
            _isLoadingUsers = false;
          });
        }
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => CreateGroupDialog(
          users: _allUsers,
          provider: provider,
          onGroupCreated: (groupId) {
            // Select the newly created group
            provider.selectConversation(groupId);
            // On mobile, hide conversation list after selection
            if (ResponsiveUtils.isMobile(context)) {
              setState(() {
                _showConversationList = false;
              });
            }
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _sendMessage(RealtimeChatProvider provider) {
    final text = _messageController.text.trim();
    if (text.isEmpty || provider.selectedConversationId == null) return;

    // Clear typing status
    _typingTimer?.cancel();
    if (_isTyping) {
      _isTyping = false;
      provider.setTyping(false);
    }

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

  void _showConversationInfo(
    BuildContext context,
    RealtimeChatProvider provider,
    RealtimeChatConversation conversation,
  ) {
    final isGroup = conversation.type == ConversationType.group;
    final memberCount = conversation.memberIds.length;
    final memberNames = conversation.memberNames.values.toList()..sort();
    final isMobile = ResponsiveUtils.isMobile(context);

      showDialog(
        context: context,
      builder: (context) => AlertDialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 40,
          vertical: isMobile ? 20 : 80,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
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
                  provider.conversationTitle(conversation).isNotEmpty
                      ? provider.conversationTitle(conversation).substring(0, 1).toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
        ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    provider.conversationTitle(conversation),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isGroup) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$memberCount members',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isGroup && memberNames.isNotEmpty) ...[
                const Text(
                  'Members:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...memberNames.take(10).map((name) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                )),
                if (memberNames.length > 10)
                  Text(
                    'and ${memberNames.length - 10} more...',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ] else ...[
                const Text(
                  'Direct conversation',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
      );
  }

  void _toggleMuteConversation(
    RealtimeChatProvider provider,
    String conversationId,
  ) {
    setState(() {
      _mutedConversations[conversationId] = !(_mutedConversations[conversationId] ?? false);
    });
  }

  void _showDeleteConfirmation(
    BuildContext context,
    RealtimeChatProvider provider,
    RealtimeChatConversation conversation,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('Delete Conversation'),
        content: Text(
          'Are you sure you want to delete this conversation? This action cannot be undone.',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete conversation functionality
              if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
                    content: Text('Delete conversation functionality coming soon'),
          ),
        );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
        ),
            child: const Text('Delete'),
          ),
        ],
      ),
      );
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
    this.currentUserId,
    this.isTyping = false,
  });

  final RealtimeChatConversation conversation;
  final String displayName;
  final bool isSelected;
  final VoidCallback onTap;
  final String? currentUserId;
  final bool isTyping;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('h:mm a');
    final time = DateTime.fromMillisecondsSinceEpoch(conversation.lastMessageTime);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: Colors.transparent,
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
                    if (isTyping)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _TypingDots(),
                        ],
                      )
                    else
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
                  Builder(
                    builder: (context) {
                      final unreadCount = currentUserId != null 
                          ? conversation.getUnreadCountForUser(currentUserId!)
                          : conversation.unreadCount;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatter.format(time),
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 260),
          margin: EdgeInsets.only(
            bottom: 2,
            right: isMine ? 4 : 8,
            left: isMine ? 8 : 4,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
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
                    fontSize: 11,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                message.text,
                style: TextStyle(
                  color: isMine ? Colors.white : AppColors.textPrimary,
                  fontSize: 13,
                  height: 1.3,
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
                  fontSize: 10,
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

// Date separator widget
class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.dateLabel});

  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: AppColors.border.withValues(alpha: 0.5),
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                dateLabel,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: AppColors.border.withValues(alpha: 0.5),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// Static typing dots (no animation)
class _TypingDots extends StatelessWidget {
  const _TypingDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.textMuted,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
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
      ),
    );
  }
}

