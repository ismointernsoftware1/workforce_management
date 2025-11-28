import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/shadcn/shadcn.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/task_model.dart';
import '../../providers/dashboard_provider.dart';
import '../../utils/responsive_utils.dart';
import '../widgets/stat_card.dart';
import '../widgets/task_card.dart';
import 'add_task_view.dart';

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

  void _openAddTask(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddTaskView(),
      ),
    ).then((_) {
      // Refresh tasks after returning from add task view
      _refreshTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final isMobile = ResponsiveUtils.isMobile(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: ResponsiveUtils.getPadding(context),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              maxWidth: constraints.maxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          // Header Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tasks & Workflow',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getFontSize(
                        context,
                        mobile: 28,
                        tablet: 32,
                        desktop: 36,
                      ),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Manage your team\'s tasks and deadlines',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: ResponsiveUtils.getFontSize(
                        context,
                        mobile: 14,
                        tablet: 15,
                        desktop: 16,
                      ),
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              if (!isMobile)
                ShadButton(
                  onPressed: () => _openAddTask(context),
                  variant: ShadButtonVariant.default_,
                  size: ShadButtonSize.md,
                  icon: const Icon(Icons.add, size: 20),
                  child: const Text('New Task'),
                )
              else
                ShadButton(
                  onPressed: () => _openAddTask(context),
                  variant: ShadButtonVariant.default_,
                  size: ShadButtonSize.sm,
                  icon: const Icon(Icons.add, size: 18),
                  child: const SizedBox.shrink(),
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
          if (_getFilteredTasks(provider).isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl * 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.task_alt_outlined,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'No tasks found',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    provider.taskSearchQuery.isNotEmpty
                        ? 'No tasks match your search'
                        : 'Get started by creating your first task',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._getFilteredTasks(provider).map(
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

  List<TaskModel> _getFilteredTasks(DashboardProvider provider) {
    var filtered = provider.filteredTasks;
    
    // Apply search filter from provider
    if (provider.taskSearchQuery.isNotEmpty) {
      final query = provider.taskSearchQuery.toLowerCase();
      filtered = filtered.where((task) {
        return task.title.toLowerCase().contains(query) ||
            task.description.toLowerCase().contains(query) ||
            task.assignedTo.toLowerCase().contains(query);
      }).toList();
    }
    
    return filtered;
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

