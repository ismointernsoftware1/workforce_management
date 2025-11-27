import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/shadcn/shadcn.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/task_model.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/task_card.dart';
import 'add_task_view.dart';

class TasksView extends StatefulWidget {
  const TasksView({super.key});

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    // Refresh tasks when view becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshTasks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          Container(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tasks & Workflow',
                  style: TextStyle(
                    fontSize: isMobile ? 28 : 36,
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
                    fontSize: isMobile ? 14 : 16,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (isMobile) ...[
            ShadInput(
              controller: _searchController,
              hintText: 'Search tasks...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
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
              width: double.infinity,
              icon: const Icon(Icons.add, size: 18),
              child: const Text('Add Task'),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: ShadInput(
                    controller: _searchController,
                    hintText: 'Search tasks...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                  ),
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
          ],
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
                    _searchQuery.isNotEmpty
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
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
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

