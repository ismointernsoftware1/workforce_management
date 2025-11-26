import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/shadcn/shadcn.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/task_card.dart';
import 'add_task_view.dart';
import 'task_templates_view.dart';

class TasksView extends StatefulWidget {
  const TasksView({super.key});

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> {
  @override
  void initState() {
    super.initState();
    // Refresh tasks when view becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshTasks();
    });
  }

  Future<void> _refreshTasks() async {
    if (!mounted) return;
    final provider = context.read<DashboardProvider>();
    // Always refresh to ensure latest data is loaded
    await provider.refreshTasks();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              maxWidth: constraints.maxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Text(
            'Tasks & Workflow',
            style: TextStyle(
              fontSize: isMobile ? 24 : 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Manage your team\'s tasks and deadlines',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: isMobile ? 13 : 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: ShadInput(
                  hintText: 'Search tasks...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                  onTap: () {},
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ShadButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TaskTemplatesView(),
                    ),
                  );
                },
                variant: ShadButtonVariant.outline,
                size: ShadButtonSize.md,
                icon: const Icon(Icons.content_copy, size: 20),
                child: const Text('Templates'),
              ),
              const SizedBox(width: AppSpacing.sm),
              ShadButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddTaskView(),
                    ),
                  );
                  // Refresh tasks after returning from add task page
                  await provider.refreshTasks();
                },
                variant: ShadButtonVariant.default_,
                size: ShadButtonSize.md,
                icon: const Icon(Icons.add, size: 20),
                child: const Text('Add Task'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          isMobile
              ? Column(
                  children: [
                    StatCard(
                      title: 'Total',
                      value: provider.totalTasks.toString(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    StatCard(
                      title: 'In Progress',
                      value: provider.inProgressCount.toString(),
                      badge: _coloredBadge('Active', AppColors.warning),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    StatCard(
                      title: 'Completed',
                      value: provider.completedCount.toString(),
                      badge: _coloredBadge('Done', AppColors.success),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Total',
                        value: provider.totalTasks.toString(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: StatCard(
                        title: 'In Progress',
                        value: provider.inProgressCount.toString(),
                        badge: _coloredBadge('Active', AppColors.warning),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: StatCard(
                        title: 'Completed',
                        value: provider.completedCount.toString(),
                        badge: _coloredBadge('Done', AppColors.success),
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: DashboardProvider.taskFilters.map(
              (filter) {
                final isSelected = provider.taskFilter == filter;
                return ShadButton(
                  onPressed: () => provider.changeTaskFilter(filter),
                  variant: isSelected
                      ? ShadButtonVariant.default_
                      : ShadButtonVariant.outline,
                  size: ShadButtonSize.sm,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      if (isSelected) const SizedBox(width: AppSpacing.xs),
                      Text(filter),
                    ],
                  ),
                );
              },
            ).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          if (provider.filteredTasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl * 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.task_alt_outlined,
                      size: 64,
                      color: AppColors.textMuted.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'No tasks found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      provider.taskFilter == 'All'
                          ? 'Get started by creating your first task'
                          : 'No ${provider.taskFilter.toLowerCase()} tasks',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                    if (provider.taskFilter == 'All') ...[
                      const SizedBox(height: AppSpacing.xl),
                      ShadButton(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AddTaskView(),
                            ),
                          );
                          await provider.refreshTasks();
                        },
                        variant: ShadButtonVariant.default_,
                        icon: const Icon(Icons.add, size: 20),
                        child: const Text('Add Your First Task'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            ...provider.filteredTasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: TaskCard(task: task),
              ),
            ),
        ],
            ),
          ),
        );
      },
    );
  }

  static Widget _coloredBadge(String label, Color color) {
    ShadBadgeVariant variant;
    if (color == AppColors.success) {
      variant = ShadBadgeVariant.default_;
    } else if (color == AppColors.warning) {
      variant = ShadBadgeVariant.secondary;
    } else {
      variant = ShadBadgeVariant.secondary;
    }
    
    return ShadBadge(
      label: label,
      variant: variant,
    );
  }
}

