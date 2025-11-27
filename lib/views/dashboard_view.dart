import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/shadcn/shadcn.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../providers/dashboard_provider.dart';
import 'chat/realtime_chat_view.dart';
import 'expenses/expenses_view.dart';
import 'tasks/add_task_view.dart';
import 'tasks/tasks_view.dart';
import 'team/team_view.dart';
import 'widgets/sidebar.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  // Breakpoint for mobile vs desktop
  static const double mobileBreakpoint = 768.0;
  bool _sidebarOpen = true; // Sidebar open by default on web

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        // Check if we're on mobile (width < 768px)
        final isMobile = MediaQuery.of(context).size.width < mobileBreakpoint;
        // On web, sidebar can be toggled
        final showSidebar = isMobile ? false : _sidebarOpen;
        
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Row(
              children: [
                // Sidebar - show on desktop when open, or use drawer on mobile
                if (showSidebar)
                  Sidebar(
                    activeTab: provider.activeTab,
                    onTabChanged: provider.changeTab,
                  ),
                Expanded(
                  child: Column(
                    children: [
                      if (provider.activeTab != DashboardTab.chat) ...[
                      _TopBar(
                        activeTab: provider.activeTab,
                        isMobile: isMobile,
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
                        showHamburger: true, // Always show hamburger
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ],
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
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _buildTab(provider),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMobileSidebar(BuildContext context, DashboardProvider provider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        alignment: Alignment.centerLeft,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: SizedBox(
          width: 280,
          child: Sidebar(
            activeTab: provider.activeTab,
            onTabChanged: (tab) {
              provider.changeTab(tab);
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTab(DashboardProvider provider) {
    switch (provider.activeTab) {
      case DashboardTab.tasks:
        return TasksView(key: ValueKey('tasks-${provider.activeTab}'));
      case DashboardTab.team:
        return const TeamView(key: ValueKey('team'));
      case DashboardTab.chat:
        return const RealtimeChatView(key: ValueKey('chat'));
      case DashboardTab.expenses:
        return ExpensesView(key: ValueKey('expenses-${provider.activeTab}'));
    }
  }
}

class _TopBar extends StatefulWidget {
  const _TopBar({
    required this.activeTab,
    required this.isMobile,
    required this.onMenuTap,
    this.showHamburger = false,
  });

  final DashboardTab activeTab;
  final bool isMobile;
  final VoidCallback onMenuTap;
  final bool showHamburger;

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      // Notify the provider about the search query
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      _performSearch(provider, _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(DashboardProvider provider, String query) {
    switch (widget.activeTab) {
      case DashboardTab.tasks:
        // Search is handled in TasksView
        break;
      case DashboardTab.team:
        provider.filterUsers(query);
        break;
      case DashboardTab.chat:
        // Search is handled in ChatView
        break;
      case DashboardTab.expenses:
        // Search is handled in ExpensesView
        break;
    }
  }

  Future<void> _navigateToAddTask(BuildContext context) async {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddTaskView(),
      ),
    );
    // Refresh tasks after returning from add task page
    await provider.refreshTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isMobile ? AppSpacing.md : AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: widget.activeTab == DashboardTab.chat
          ? const SizedBox.shrink()
          : Row(
              children: [
                if (widget.isMobile || widget.showHamburger) ...[
                  ShadTooltip(
                    message: 'Menu',
                    child: ShadButton(
                      onPressed: widget.onMenuTap,
                      variant: ShadButtonVariant.ghost,
                      size: ShadButtonSize.icon,
                      icon: const Icon(Icons.menu,
                          size: 24, color: AppColors.textPrimary),
                      child: const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: ShadInput(
                    controller: _searchController,
                    hintText: 'Search...',
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.textMuted),
                  ),
                ),
                if (widget.activeTab == DashboardTab.tasks) ...[
                  SizedBox(
                      width: widget.isMobile
                          ? AppSpacing.sm
                          : AppSpacing.md),
                  ShadButton(
                    onPressed: () => _navigateToAddTask(context),
                    variant: ShadButtonVariant.default_,
                    size: widget.isMobile
                        ? ShadButtonSize.sm
                        : ShadButtonSize.md,
                    icon: const Icon(Icons.add, size: 20),
                    child: widget.isMobile
                        ? const SizedBox.shrink()
                        : const Text('Add Task'),
                  ),
                ],
              ],
            ),
    );
  }
}

