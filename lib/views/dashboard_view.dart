import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../providers/dashboard_provider.dart';
import '../providers/expense_provider.dart';
import '../models/search_result.dart';
import '../models/expense_model.dart';
import '../utils/responsive_utils.dart';
import '../utils/rbac_utils.dart';
import '../widgets/shadcn/shadcn_widgets.dart';
import '../widgets/mobile_bottom_nav.dart';
import '../services/auth_service.dart';
import 'chat/realtime_chat_view.dart';
import 'expenses/expenses_view.dart';
import 'tasks/tasks_view.dart';
import 'team/team_view.dart';
import 'roles/role_list_page.dart';
import 'widgets/sidebar.dart';
import '../features/form_builder/screens/form_builder_screen.dart';
import '../features/form_builder/screens/task_form_builder_screen.dart';
import '../features/form_builder/screens/expense_form_builder_screen.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
bool _sidebarOpen = true; // Sidebar open by default on web


  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        final isMobile = ResponsiveUtils.isMobile(context);
        // On mobile, sidebar is hidden by default (shown via drawer)
        // On desktop, sidebar can be toggled
        final showSidebar = isMobile ? false : _sidebarOpen;
        
        return FutureBuilder<Map<String, bool>>(
          future: _getAvailableTabs(context),
          builder: (context, snapshot) {
            final availableTabs = snapshot.data ?? {};
            final tabsList = _getTabsList(availableTabs, provider.isSuperAdmin ?? false);
            
            return Scaffold(
              backgroundColor: AppColors.background,
              body: SafeArea(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      children: [
                        // Sidebar - show on desktop when open
                        if (showSidebar)
                          Sidebar(
                            activeTab: provider.activeTab,
                            onTabChanged: provider.changeTab,
                            isSuperAdmin: provider.isSuperAdmin,
                          ),
                        Expanded(
                          child: Column(
                            children: [
                              _TopBar(
                                activeTab: provider.activeTab,
                                onMenuTap: () {
                                  if (!isMobile) {
                                    // Toggle sidebar on web
                                    setState(() {
                                      _sidebarOpen = !_sidebarOpen;
                                    });
                                  }
                                },
                                showMenuButton: !isMobile,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              if (provider.isLoading)
                                const Expanded(
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                    ),
                                  ),
                                )
                              else
                                Expanded(
                                  child: _buildTab(provider),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                // Search results overlay - positioned above all content
                // This must be a direct child of Stack for Positioned to work
                Consumer<DashboardProvider>(
                  builder: (context, provider, _) {
                    final isChat = provider.activeTab == DashboardTab.chat;
                    if (isChat || provider.globalSearchQuery.trim().isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = ResponsiveUtils.isMobile(context);
                        final topBarHeight = 80.0;
                        final horizontalPadding = isMobile ? AppSpacing.md : AppSpacing.xl;
                        
                        return Positioned(
                          top: topBarHeight + 56,
                          left: horizontalPadding + 48,
                          right: horizontalPadding,
                          child: Material(
                            elevation: 12,
                            borderRadius: BorderRadius.circular(8),
                            shadowColor: Colors.black.withValues(alpha: 0.2),
                            child: _buildSearchResultsOverlay(context, provider),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          bottomNavigationBar: isMobile && tabsList.isNotEmpty
              ? MobileBottomNav(
                  currentTab: provider.activeTab,
                  onTabChanged: provider.changeTab,
                  availableTabs: tabsList,
                )
              : null,
        );
          },
        );
      },
    );
  }

  Future<Map<String, bool>> _getAvailableTabs(BuildContext context) async {
    final permissions = <String, bool>{};
    permissions['team'] = await RBACUtils.canRead('team');
    permissions['chat'] = await RBACUtils.canRead('chat');
    permissions['tasks'] = await RBACUtils.canRead('task');
    permissions['expenses'] = await RBACUtils.canRead('expense');
    permissions['admin'] = await RBACUtils.isAdmin();
    return permissions;
  }

  List<DashboardTab> _getTabsList(Map<String, bool> permissions, bool isSuperAdmin) {
    if (isSuperAdmin) {
      return [
        DashboardTab.tasks,
        DashboardTab.team,
        DashboardTab.chat,
        DashboardTab.expenses,
        DashboardTab.roles,
      ];
    }
    
    final tabs = <DashboardTab>[];
    if (permissions['tasks'] == true) tabs.add(DashboardTab.tasks);
    if (permissions['team'] == true) tabs.add(DashboardTab.team);
    if (permissions['chat'] == true) tabs.add(DashboardTab.chat);
    if (permissions['expenses'] == true) tabs.add(DashboardTab.expenses);
    if (permissions['admin'] == true) tabs.add(DashboardTab.roles);
    
    return tabs;
  }


  Widget _buildTab(DashboardProvider provider) {
    // Show loading if RBAC status not yet determined
    if (provider.isSuperAdmin == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Render the appropriate view (tabs are already filtered in sidebar)
    switch (provider.activeTab) {
      case DashboardTab.tasks:
        return TasksView(key: ValueKey('tasks-${provider.activeTab}'));
      case DashboardTab.team:
        return const TeamView(key: ValueKey('team'));
      case DashboardTab.chat:
        return const RealtimeChatView(key: ValueKey('chat'));
      case DashboardTab.expenses:
        return ExpensesView(key: ValueKey('expenses-${provider.activeTab}'));
      case DashboardTab.roles:
        return const RoleListPage(key: ValueKey('roles'));
      case DashboardTab.formBuilder:
        return const FormBuilderScreen(key: ValueKey('form_builder'));
      case DashboardTab.taskFormBuilder:
        return const TaskFormBuilderScreen(key: ValueKey('task_form_builder'));
      case DashboardTab.expenseFormBuilder:
        return const ExpenseFormBuilderScreen(key: ValueKey('expense_form_builder'));
    }
  }

  // Helper method to build search results overlay
  Widget _buildSearchResultsOverlay(BuildContext context, DashboardProvider provider) {
    final query = provider.globalSearchQuery.trim();
    
    if (query.isEmpty) {
      return const SizedBox.shrink();
    }

    if (provider.globalSearchResults.isEmpty) {
      return Container(
        constraints: const BoxConstraints(maxHeight: 200),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text(
            'No results found for "$query"',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search Suggestions Header
          if (provider.globalSearchResults.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
              child: Row(
                children: [
                  Text(
                    'Search Suggestions',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: provider.globalSearchResults.length,
              itemBuilder: (context, index) {
                final result = provider.globalSearchResults[index];
                return _buildSearchResultItem(context, result, provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(BuildContext context, SearchResult result, DashboardProvider provider) {
    IconData icon;
    Color iconColor;
    String categoryLabel;

    switch (result.type) {
      case SearchResultType.task:
        icon = Icons.task_alt;
        iconColor = AppColors.primary;
        categoryLabel = 'Task';
        break;
      case SearchResultType.teamMember:
        icon = result.icon ?? Icons.person;
        iconColor = result.icon == Icons.groups ? AppColors.primary : AppColors.success;
        categoryLabel = result.icon == Icons.groups ? 'Team' : 'Team Member';
        break;
      case SearchResultType.expense:
        icon = Icons.receipt;
        iconColor = AppColors.warning;
        categoryLabel = 'Expense';
        break;
      case SearchResultType.conversation:
        icon = Icons.chat_bubble_outline;
        iconColor = AppColors.primary;
        categoryLabel = 'Conversation';
        break;
    }

    // For team members, show avatar with initials
    final showAvatar = result.type == SearchResultType.teamMember && result.avatarText != null;

    return InkWell(
      onTap: () {
        _handleSearchResultTap(context, result, provider);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: AppColors.border.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar or Icon
            if (showAvatar)
              CircleAvatar(
                radius: 20,
                backgroundColor: iconColor.withValues(alpha: 0.15),
                child: Text(
                  result.avatarText!,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (result.email != null && result.role != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${result.email} • ${result.role}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else if (result.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      result.subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    categoryLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: iconColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSearchResultTap(BuildContext context, SearchResult result, DashboardProvider provider) {
    switch (result.type) {
      case SearchResultType.task:
        provider.changeTab(DashboardTab.tasks);
        break;
      case SearchResultType.teamMember:
        provider.changeTab(DashboardTab.team);
        break;
      case SearchResultType.expense:
        provider.changeTab(DashboardTab.expenses);
        break;
      case SearchResultType.conversation:
        provider.changeTab(DashboardTab.chat);
        provider.selectConversation(result.id);
        break;
    }
    
    // Clear search
    provider.performGlobalSearch('');
  }
}

class _TopBar extends StatefulWidget {
  const _TopBar({
    required this.activeTab,
    required this.onMenuTap,
    this.showMenuButton = true,
  });

  final DashboardTab activeTab;
  final VoidCallback onMenuTap;
  final bool showMenuButton;

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
  }

  void _onSearchChanged() {
    if (!mounted) return;
    
    final query = _searchController.text.trim();
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    
    // Perform global search
    if (query.isNotEmpty) {
      // Get expenses from ExpenseProvider if available
      List<ExpenseModel>? expenses;
      try {
        final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
        expenses = expenseProvider.expenses;
      } catch (e) {
        // ExpenseProvider might not be available, search without expenses
        expenses = null;
      }
      provider.performGlobalSearch(query, expenses: expenses);
      
      setState(() {
        _showSearchResults = true;
      });
    } else {
      provider.performGlobalSearch('');
      setState(() {
        _showSearchResults = false;
      });
    }
  }

  void _onFocusChanged() {
    if (!_searchFocusNode.hasFocus) {
      // Delay closing to allow tap on results
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
          setState(() {
            _showSearchResults = false;
          });
        }
      });
    } else {
      // Show results when focused if there's text
      if (_searchController.text.isNotEmpty && mounted) {
        setState(() {
          _showSearchResults = true;
        });
      }
    }
  }

  @override
  void didUpdateWidget(_TopBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear search when tab changes - defer to avoid calling during build
    if (oldWidget.activeTab != widget.activeTab) {
      Future.microtask(() {
        if (mounted) {
          _searchController.clear();
          setState(() {
            _showSearchResults = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isChat = widget.activeTab == DashboardTab.chat;

    // For Chat tab, we want the chat layout to be truly full-screen with no
    // extra header padding at the top, so we skip rendering this header row.
    if (isChat) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        // Close search results when tapping outside
        if (_showSearchResults) {
          _searchFocusNode.unfocus();
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // Show hamburger menu only if showMenuButton is true
            if (widget.showMenuButton)
              ShadTooltip(
                builder: (context) => const Text('Menu'),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onMenuTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.menu,
                        size: 24,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.showMenuButton) const SizedBox(width: AppSpacing.md),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: isChat
                  // For chat, header and search are handled inside RealtimeChatView's sidebar,
                  // so we render an empty placeholder here to keep layout consistent.
                  ? const SizedBox.shrink()
                  : AppSearchInput(
                      controller: _searchController,
                      placeholder: 'Search tasks, team, expenses...',
                      onChanged: (value) {
                        // Search functionality handled by controller
                      },
                    ),
            ),
            // Profile menu button for mobile view
            if (isMobile && !isChat) ...[
              const SizedBox(width: AppSpacing.md),
              _buildProfileMenu(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenu(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const SizedBox.shrink();
    }

    final displayName = user.displayName ?? user.email?.split('@')[0] ?? 'User';
    final initials = _getInitials(user.displayName, user.email);

    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 8,
      color: Colors.white,
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
          child: Text(
            initials,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
      itemBuilder: (context) => [
        // User info header
        PopupMenuItem<String>(
          enabled: false,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email ?? '',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Divider
        const PopupMenuDivider(
          height: 1,
        ),
        // Logout option
        PopupMenuItem<String>(
          value: 'logout',
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'logout') {
          _handleLogout(context);
        }
      },
    );
  }

  String _getInitials(String? name, String? email) {
    if (name != null && name.isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    if (email != null && email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return 'U';
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Sign Out'),
        child: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          AppButton(
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppButton(
            variant: AppButtonVariant.destructive,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        // Clear RBAC cache before logout
        RBACUtils.clearCache();
        
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.signOut();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: ${e.toString()}'),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}
