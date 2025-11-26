import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/shadcn/shadcn.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../providers/dashboard_provider.dart';
import 'chat/chat_view.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Breakpoint for mobile vs desktop
  static const double mobileBreakpoint = 768.0;

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        // Check if we're on mobile (width < 768px)
        final isMobile = MediaQuery.of(context).size.width < mobileBreakpoint;
        
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          drawer: isMobile
              ? Drawer(
                  width: 280,
                  child: Sidebar(
                    activeTab: provider.activeTab,
                    onTabChanged: (tab) {
                      provider.changeTab(tab);
                      _scaffoldKey.currentState?.closeDrawer();
                    },
                  ),
                )
              : null,
          body: SafeArea(
            child: Row(
              children: [
                // Sidebar - only show on desktop
                if (!isMobile)
                  Sidebar(
                    activeTab: provider.activeTab,
                    onTabChanged: provider.changeTab,
                  ),
                Expanded(
                  child: Column(
                    children: [
                      _TopBar(
                        activeTab: provider.activeTab,
                        isMobile: isMobile,
                        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (provider.isLoading)
                        const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(),
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

  Widget _buildTab(DashboardProvider provider) {
    switch (provider.activeTab) {
      case DashboardTab.tasks:
        return TasksView(key: ValueKey('tasks-${provider.activeTab}'));
      case DashboardTab.team:
        return const TeamView(key: ValueKey('team'));
      case DashboardTab.chat:
        return const ChatView(key: ValueKey('chat'));
      case DashboardTab.expenses:
        return ExpensesView(key: ValueKey('expenses-${provider.activeTab}'));
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.activeTab,
    required this.isMobile,
    required this.onMenuTap,
  });

  final DashboardTab activeTab;
  final bool isMobile;
  final VoidCallback onMenuTap;

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
        horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // Hamburger menu button for mobile
          if (isMobile) ...[
            ShadTooltip(
              message: 'Menu',
              child: ShadButton(
                onPressed: onMenuTap,
                variant: ShadButtonVariant.ghost,
                size: ShadButtonSize.icon,
                icon: const Icon(Icons.menu, size: 24, color: AppColors.textPrimary),
                child: const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          // Search bar - responsive width
          Expanded(
            child: ShadInput(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
            ),
          ),
          // Right side buttons - hide some on mobile
          if (!isMobile) ...[
            const SizedBox(width: AppSpacing.md),
            ShadTooltip(
              message: 'Notifications',
              child: ShadButton(
                onPressed: () {},
                variant: ShadButtonVariant.ghost,
                size: ShadButtonSize.icon,
                icon: const Icon(Icons.notifications_none_rounded, size: 20),
                child: const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ShadButton(
              onPressed: () {},
              variant: ShadButtonVariant.outline,
              size: ShadButtonSize.sm,
              icon: const Icon(Icons.filter_list_rounded, size: 18),
              child: const Text('Filters'),
            ),
          ] else ...[
            const SizedBox(width: AppSpacing.sm),
            ShadButton(
              onPressed: () {},
              variant: ShadButtonVariant.ghost,
              size: ShadButtonSize.icon,
              icon: const Icon(Icons.notifications_none_rounded, size: 20),
              child: const SizedBox.shrink(),
            ),
          ],
          // Add Task button - responsive
          if (activeTab == DashboardTab.tasks) ...[
            SizedBox(width: isMobile ? AppSpacing.sm : AppSpacing.md),
            ShadButton(
              onPressed: () => _navigateToAddTask(context),
              variant: ShadButtonVariant.default_,
              size: isMobile ? ShadButtonSize.sm : ShadButtonSize.md,
              icon: const Icon(Icons.add, size: 20),
              child: isMobile ? const SizedBox.shrink() : const Text('Add Task'),
            ),
          ],
        ],
      ),
    );
  }
}

