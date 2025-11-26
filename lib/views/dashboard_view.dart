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

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Row(
              children: [
                Sidebar(
                  activeTab: provider.activeTab,
                  onTabChanged: provider.changeTab,
                ),
                Expanded(
                  child: Column(
                    children: [
                      _TopBar(activeTab: provider.activeTab),
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
        return const TasksView();
      case DashboardTab.team:
        return const TeamView();
      case DashboardTab.chat:
        return const ChatView();
      case DashboardTab.expenses:
        return const ExpensesView();
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.activeTab});

  final DashboardTab activeTab;

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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 320,
            child: ShadInput(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
            ),
          ),
          const Spacer(),
          ShadButton(
            onPressed: () {},
            variant: ShadButtonVariant.ghost,
            size: ShadButtonSize.icon,
            icon: const Icon(Icons.notifications_none_rounded, size: 20),
            child: const SizedBox.shrink(),
          ),
          const SizedBox(width: AppSpacing.sm),
          ShadButton(
            onPressed: () {},
            variant: ShadButtonVariant.outline,
            size: ShadButtonSize.sm,
            icon: const Icon(Icons.filter_list_rounded, size: 18),
            child: const Text('Filters'),
          ),
          if (activeTab == DashboardTab.tasks) ...[
            const SizedBox(width: AppSpacing.md),
            ShadButton(
              onPressed: () => _navigateToAddTask(context),
              variant: ShadButtonVariant.default_,
              size: ShadButtonSize.md,
              icon: const Icon(Icons.add, size: 20),
              child: const Text('Add Task'),
            ),
          ],
        ],
      ),
    );
  }
}

