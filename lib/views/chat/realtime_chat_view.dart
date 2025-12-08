import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../widgets/shadcn/shadcn_widgets.dart';
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
    
    // On mobile, show either conversation list OR chat view, not both
    if (isMobile) {
      if (_showConversationList) {
        return Container(
          color: Colors.white,
          child: _buildConversationList(context),
        );
      } else {
        return Container(
          color: const Color(0xFFF5F6FA), // Modern light background
          child: _buildChatView(context, isMobile),
        );
      }
    }
    
    // Desktop/Tablet: Show both side by side - Modern chat layout
    return Container(
      color: const Color(0xFFF8FAFC), // Modern sidebar background
      child: Row(
        children: [
          // Left sidebar with conversations - Modern chat width
          Container(
            width: ResponsiveUtils.isDesktop(context) 
                ? 400.0 
                : (isTablet ? 350.0 : 320.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(
                  color: const Color(0xFFE4E7EC),
                  width: 0.5,
                ),
              ),
            ),
            child: _buildConversationList(context),
          ),
          // Main chat area - Modern style
          Expanded(
            child: Container(
              color: const Color(0xFFF5F6FA), // Modern light background
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
      decoration: const BoxDecoration(
        color: Colors.white,
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
                bottom: AppSpacing.md,
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
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.3),
                            width: 1,
                        ),
                        ),
                        child: const Icon(
                          Icons.menu,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Chat title
                  Expanded(
                    child: Text(
                      'Chat',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getFontSize(
                          context,
                          mobile: 20,
                          tablet: 22,
                          desktop: 24,
                        ),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Search bar - Modern style
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF111B21),
                ),
                decoration: InputDecoration(
                  hintText: 'Search or start new chat',
                  hintStyle: TextStyle(
                    color: const Color(0xFF667781).withValues(alpha: 0.7),
                    fontSize: 14.5,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: const Color(0xFF64748B), // Muted text
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
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
              // Create Group button at bottom (only show in Group tab)
              Consumer<RealtimeChatProvider>(
                builder: (context, provider, _) {
                  if (provider.activeTab == ChatTab.explore) {
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: AppButton(
                        onPressed: () => _showCreateGroupDialog(context, provider),
                        fullWidth: true,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.group_add, size: 18),
                            SizedBox(width: AppSpacing.xs),
                            Text('Create Group'),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
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
                    color: const Color(0xFFF5F6FA), // Modern light background
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F2F5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.chat_bubble_outline,
                              size: ResponsiveUtils.getFontSize(
                                context,
                                mobile: 64,
                                tablet: 72,
                                desktop: 80,
                              ),
                              color: const Color(0xFF54656F),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Keep your phone connected',
                            style: TextStyle(
                              color: const Color(0xFF111B21),
                              fontSize: ResponsiveUtils.getFontSize(
                                context,
                                mobile: 18,
                                tablet: 20,
                                desktop: 22,
                              ),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48),
                            child: Text(
                            isMobile
                                ? 'Tap the menu to view conversations'
                                  : 'Connect to sync messages. To reduce data usage, connect to Wi-Fi.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: const Color(0xFF667781),
                              fontSize: ResponsiveUtils.getFontSize(
                                context,
                                mobile: 14,
                                  tablet: 14.5,
                                  desktop: 14.5,
                              ),
                                height: 1.4,
                              ),
                            ),
                          ),
                          if (isMobile) ...[
                            const SizedBox(height: 32),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB), // Blue accent
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(24),
                                  onTap: () {
                                setState(() {
                                  _showConversationList = true;
                                });
                              },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                        Icon(Icons.message, size: 18, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          'View Conversations',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                ],
                                    ),
                                  ),
                                ),
                              ),
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
                  decoration: const BoxDecoration(
                  color: const Color(0xFFF5F6FA), // Modern chat background
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            // Header bar with conversation info - Modern style
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: const BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                border: Border(
                                  bottom: BorderSide(
                                    color: const Color(0xFFE4E7EC),
                                    width: 0.5,
                                  ),
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
                                  // Avatar - Modern style
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFFDBEAFE), // Light blue avatar
                                      child: Text(
                                        provider.selectedConversationTitle.isNotEmpty
                                            ? provider.selectedConversationTitle
                                                .substring(0, 1)
                                                .toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                        color: const Color(0xFF2563EB), // Blue text
                                        fontWeight: FontWeight.w500,
                                        fontSize: 18,
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
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF0F172A), // Dark text
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (isGroupConversation) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            '${selectedConversation.memberIds.length} members',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: const Color(0xFF64748B), // Muted text
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // Silent / notifications toggle button
                                  ShadIconButton.ghost(
                                    onPressed: () {
                                      _toggleMuteConversation(provider, selectedConversation.id);
                                    },
                                    icon: Icon(
                                      _mutedConversations[selectedConversation.id] == true
                                          ? Icons.notifications_off_outlined
                                          : Icons.notifications_none_outlined,
                                      size: 18,
                                      color: _mutedConversations[selectedConversation.id] == true
                                          ? AppColors.textMuted
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  // Menu button
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textMuted),
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

                                  // Show loading ONLY if we're actively waiting for the first data
                                  // The onValue listener fires immediately with current data, so this should be brief
                                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  
                                  // If we have data (even if empty), proceed to show it
                                  // The stream emits data immediately via onValue listener
                                  if (!snapshot.hasData) {
                                    // If no data after waiting, show empty state
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  
                                  // At this point, we have data (even if empty)
                                  // Proceed to show the messages

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
                                          padding: const EdgeInsets.only(
                                            left: 16,
                                            right: 16,
                                            bottom: 8,
                                            top: 8,
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
                                      // Typing indicator with modern animation (only dots)
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
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: const BorderRadius.only(
                                                    topLeft: Radius.circular(7.5),
                                                    topRight: Radius.circular(7.5),
                                                    bottomLeft: Radius.circular(0),
                                                    bottomRight: Radius.circular(7.5),
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.08),
                                                      blurRadius: 3,
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
                            // Input area - Modern style
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC), // Light background
                                border: Border(
                                  top: BorderSide(
                                    color: const Color(0xFFE4E7EC).withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.emoji_emotions_outlined,
                                      size: 24,
                                      color: const Color(0xFF2563EB), // Blue text
                                    ),
                                    onPressed: () {
                                      // Emoji picker - placeholder
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Container(
                                      constraints: const BoxConstraints(maxHeight: 100),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(21),
                                      ),
                                      child: TextField(
                                        controller: _messageController,
                                        maxLines: null,
                                        textInputAction: TextInputAction.newline,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: const Color(0xFF0F172A), // Dark text
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Type a message',
                                          hintStyle: TextStyle(
                                            color: const Color(0xFF667781).withValues(alpha: 0.7),
                                            fontSize: 15,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 9,
                                        ),
                                        ),
                                        onSubmitted: (_) => _sendMessage(provider),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.attach_file,
                                      size: 24,
                                      color: const Color(0xFF2563EB), // Blue text
                                    ),
                                    onPressed: () => _showAttachmentOptions(context, provider),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      color: const Color(0xFF2563EB), // Blue send button
                                      shape: BoxShape.circle,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () => _sendMessage(provider),
                                          child: const Icon(
                                            Icons.send_rounded,
                                            size: 20,
                                            color: Colors.white,
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
        barrierColor: Colors.black54,
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

  void _showAttachmentOptions(BuildContext context, RealtimeChatProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AttachmentOption(
              icon: Icons.image,
              label: 'Photo',
              color: const Color(0xFF2563EB), // Blue accent
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(provider);
              },
            ),
            _AttachmentOption(
              icon: Icons.video_library,
              label: 'Video',
              color: const Color(0xFF2563EB), // Blue accent
              onTap: () {
                Navigator.pop(context);
                _pickAndSendVideo(provider);
              },
            ),
            _AttachmentOption(
              icon: Icons.insert_drive_file,
              label: 'Document',
              color: const Color(0xFF2563EB), // Blue accent
              onTap: () {
                Navigator.pop(context);
                _pickAndSendDocument(provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage(RealtimeChatProvider provider) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null && provider.selectedConversationId != null) {
        final fileData = result.files.single.bytes!;
        final fileName = result.files.single.name;

        // Show loading
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uploading image...')),
          );
        }

        await provider.sendMessageWithFile(
          '',
          fileData,
          fileName,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image sent')),
          );
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending image: $e')),
        );
      }
    }
  }

  Future<void> _pickAndSendVideo(RealtimeChatProvider provider) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null && provider.selectedConversationId != null) {
        final fileData = result.files.single.bytes!;
        final fileName = result.files.single.name;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uploading video...')),
          );
        }

        await provider.sendMessageWithFile(
          '',
          fileData,
          fileName,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video sent')),
          );
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending video: $e')),
        );
      }
    }
  }

  Future<void> _pickAndSendDocument(RealtimeChatProvider provider) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null && provider.selectedConversationId != null) {
        final fileData = result.files.single.bytes!;
        final fileName = result.files.single.name;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uploading document...')),
          );
        }

        await provider.sendMessageWithFile(
          '',
          fileData,
          fileName,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document sent')),
          );
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending document: $e')),
        );
      }
    }
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

    // Modern professional colors
    final selectedBg = const Color(0xFFE0E7FF); // Light blue for selected
    final unreadBg = const Color(0xFF2563EB); // Blue for unread badge
    final timestampColor = const Color(0xFF64748B);
    final nameColor = const Color(0xFF0F172A);
    final messageColor = const Color(0xFF64748B);

    return Material(
        color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: isSelected ? selectedBg : Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFDBEAFE), // Light blue avatar
                child: Text(
                  displayName.isNotEmpty
                      ? displayName.substring(0, 1).toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2563EB), // Blue text
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                      displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 17,
                              color: nameColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatter.format(time),
                          style: TextStyle(
                            color: timestampColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: isTyping
                              ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _TypingDots(),
                        ],
                      )
                              : Text(
                      conversation.lastMessage,
                                  style: TextStyle(
                                    color: messageColor,
                                    fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ),
                  Builder(
                    builder: (context) {
                      final unreadCount = currentUserId != null 
                          ? conversation.getUnreadCountForUser(currentUserId!)
                          : conversation.unreadCount;
                            if (unreadCount > 0) {
                              return Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                  color: unreadBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                    fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      );
                            }
                            return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ],
          ),
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

    // Modern professional colors
    final sentBubbleColor = const Color(0xFF2563EB); // Blue for sent messages
    final receivedBubbleColor = const Color(0xFFFFFFFF); // White for received
    final sentTextColor = Colors.white; // White text on blue
    final receivedTextColor = const Color(0xFF0F172A); // Dark text on white
    final timestampColor = const Color(0xFF64748B); // Muted grey timestamp

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.5),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          margin: EdgeInsets.only(
            bottom: 1,
            right: isMine ? 6 : 60,
            left: isMine ? 60 : 6,
            top: 1,
          ),
          padding: const EdgeInsets.only(
            left: 7,
            right: 7,
            top: 6,
            bottom: 6,
          ),
          decoration: BoxDecoration(
            color: isMine ? sentBubbleColor : receivedBubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(7.5),
              topRight: const Radius.circular(7.5),
              bottomLeft: Radius.circular(isMine ? 7.5 : 0),
              bottomRight: Radius.circular(isMine ? 0 : 7.5),
            ),
            boxShadow: [
                    BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 3,
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
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: const Color(0xFF2563EB), // Blue accent
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              if (message.text.isNotEmpty) ...[
              Text(
                message.text,
                style: TextStyle(
                    color: isMine ? sentTextColor : receivedTextColor,
                    fontSize: 14.2,
                  height: 1.3,
                  letterSpacing: 0.1,
                ),
              ),
                if (message.attachmentUrl != null) const SizedBox(height: 6),
              ],
              if (message.attachmentUrl != null) ...[
                if (message.text.isEmpty) const SizedBox(height: 0) else const SizedBox(height: 6),
                if (message.type == MessageType.image)
                  GestureDetector(
                    onTap: () => _showFullScreenImage(context, message.attachmentUrl!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      message.attachmentUrl!,
                        width: 250,
                        height: 250,
                      fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 250,
                            height: 250,
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 250,
                            height: 250,
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else if (message.type == MessageType.video)
                  GestureDetector(
                    onTap: () => _showVideoPlayer(context, message.attachmentUrl!),
                    child: Container(
                      width: 200,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Video thumbnail placeholder
                          Icon(
                            Icons.play_circle_filled,
                            size: 48,
                            color: isMine ? Colors.white : const Color(0xFF64748B),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'VIDEO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: isMine
                            ? Colors.white.withValues(alpha: 0.3)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getFileIcon(message.fileName),
                          color: isMine ? sentTextColor : const Color(0xFF64748B),
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
                                color: isMine ? sentTextColor : receivedTextColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            if (message.fileSize != null)
                              Text(
                                _formatFileSize(message.fileSize!),
                                style: TextStyle(
                                  color: timestampColor,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
              Text(
                formatter.format(time),
                style: TextStyle(
                      color: timestampColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.normal,
                      letterSpacing: 0.1,
                ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 3),
                    _buildStatusIcon(message.status),
                  ],
                ],
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

  Widget _buildStatusIcon(MessageStatus status) {
    // Modern message status ticks
    final timestampColor = const Color(0xFF64748B);
    final color = status == MessageStatus.seen
        ? const Color(0xFF2563EB) // Blue for seen
        : timestampColor; // Grey for sent/delivered
    
    if (status == MessageStatus.sent) {
      // Single grey tick
      return Icon(
        Icons.done,
        size: 14,
        color: color,
      );
    } else {
      // Double tick (delivered or seen)
      return Icon(
        Icons.done_all,
        size: 14,
        color: color,
      );
    }
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(imageUrl),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoPlayer(BuildContext context, String videoUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle_filled, size: 64, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text(
                    'Video playback',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      // Open video URL in browser/player
                      // You can use url_launcher here
                    },
                    child: const Text(
                      'Open Video',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Attachment option widget
class _AttachmentOption extends StatelessWidget {
  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111B21),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Date separator widget - Modern style
class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.dateLabel});

  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: const Color(0xFFE4E7EC).withValues(alpha: 0.5),
              thickness: 0.5,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                dateLabel,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: const Color(0xFFE4E7EC).withValues(alpha: 0.5),
              thickness: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Static typing dots (no animation) - Modern style
class _TypingDots extends StatelessWidget {
  const _TypingDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: const Color(0xFF667781),
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm - 2,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFF0F9FF)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? AppColors.primary : AppColors.textMuted,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
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

