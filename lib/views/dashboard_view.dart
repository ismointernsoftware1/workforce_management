import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/shadcn/shadcn.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../providers/dashboard_provider.dart';
import '../providers/expense_provider.dart';
import '../models/search_result.dart';
import '../models/expense_model.dart';
import '../utils/responsive_utils.dart';
import '../widgets/shadcn/shadcn_widgets.dart';
import 'chat/realtime_chat_view.dart';
import 'expenses/expenses_view.dart';
import 'tasks/tasks_view.dart';
import 'team/team_view.dart';
import 'widgets/sidebar.dart';
import '../features/form_builder/screens/form_builder_screen.dart';

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
        
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  children: [
                    // Sidebar - show on desktop when open, or use drawer on mobile
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
                              if (isMobile) {
                                _showMobileSidebar(context, provider);
                              } else {
                                // Toggle sidebar on web
                                setState(() {
                                  _sidebarOpen = !_sidebarOpen;
                                });
                              }
                            },
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
        );
      },
    );
  }

  void _showMobileSidebar(BuildContext context, DashboardProvider provider) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final dialogWidth = isMobile 
        ? MediaQuery.of(context).size.width * 0.85
        : (ResponsiveUtils.isTablet(context) ? 300.0 : 280.0);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        alignment: Alignment.centerLeft,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: SizedBox(
          width: dialogWidth,
          child: Sidebar(
            activeTab: provider.activeTab,
            onTabChanged: (tab) {
              provider.changeTab(tab);
              Navigator.of(context).pop();
            },
            isSuperAdmin: provider.isSuperAdmin,
          ),
        ),
      ),
    );
  }

  Widget _buildTab(DashboardProvider provider) {
    // Use cached isSuperAdmin value from provider
    final isSuperAdmin = provider.isSuperAdmin ?? false;
    
    // Show loading if RBAC status not yet determined
    if (provider.isSuperAdmin == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Super Admin: Only allow Form Builder
    if (isSuperAdmin && provider.activeTab != DashboardTab.formBuilder) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Access Restricted',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Super Administrators can only access Form Builder.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // Non-Super Admin: Don't allow Form Builder
    if (!isSuperAdmin && provider.activeTab == DashboardTab.formBuilder) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This page is only accessible to Super Administrators.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // Render the appropriate view
    switch (provider.activeTab) {
      case DashboardTab.tasks:
        return TasksView(key: ValueKey('tasks-${provider.activeTab}'));
      case DashboardTab.team:
        return const TeamView(key: ValueKey('team'));
      case DashboardTab.chat:
        return const RealtimeChatView(key: ValueKey('chat'));
      case DashboardTab.expenses:
        return ExpensesView(key: ValueKey('expenses-${provider.activeTab}'));
      case DashboardTab.formBuilder:
        return const FormBuilderScreen(key: ValueKey('form_builder'));
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
  });

  final DashboardTab activeTab;
  final VoidCallback onMenuTap;

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
    // Clear search when tab changes
    if (oldWidget.activeTab != widget.activeTab) {
      _searchController.clear();
      setState(() {
        _showSearchResults = false;
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
            // Always show hamburger menu
            ShadTooltip(
              message: 'Menu',
              child: ShadButton(
                onPressed: widget.onMenuTap,
                variant: ShadButtonVariant.ghost,
                size: ShadButtonSize.icon,
                icon: const Icon(
                  Icons.menu,
                  size: 24,
                  color: AppColors.textPrimary,
                ),
                child: const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: isChat
                  // For chat, header and search are handled inside RealtimeChatView's sidebar,
                  // so we render an empty placeholder here to keep layout consistent.
                  ? const SizedBox.shrink()
                  : ShadInput(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      hintText: 'Search tasks, team, expenses...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textMuted,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
