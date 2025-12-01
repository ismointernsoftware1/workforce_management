import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../components/shadcn/shadcn.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/task_model.dart';
import '../../models/team_member.dart';
import '../../providers/dashboard_provider.dart';
import '../../controllers/task_screen_controller.dart';
import '../../utils/responsive_utils.dart';
import 'add_task_view.dart';
import 'edit_task_view.dart';
import 'task_detail_view.dart';
import 'calendar_view.dart';

// Helper function to find assignee by matching name from "name - role" format or direct name
TeamMember _findAssigneeFromTask(DashboardProvider provider, String assignedTo) {
  if (assignedTo.isEmpty) {
    return TeamMember(
      id: '',
      name: '',
      email: '',
      role: '',
      department: '',
      isOnline: false,
    );
  }

  // Try to find by exact match first
  try {
    return provider.members.firstWhere(
      (m) => m.name == assignedTo,
    );
  } catch (e) {
    // If not found, try to extract name from "name - role" format
    final nameParts = assignedTo.split(' - ');
    final nameOnly = nameParts.isNotEmpty ? nameParts[0].trim() : assignedTo;
    
    try {
      return provider.members.firstWhere(
        (m) => m.name == nameOnly || assignedTo.contains(m.name),
      );
    } catch (e) {
      // If still not found, return a fallback with the assigned name
      return TeamMember(
        id: '',
        name: nameOnly,
        email: '',
        role: nameParts.length > 1 ? nameParts[1].trim() : '',
        department: '',
        isOnline: false,
      );
    }
  }
}

class TaskScreenView extends StatefulWidget {
  const TaskScreenView({super.key});

  @override
  State<TaskScreenView> createState() => _TaskScreenViewState();
}

class _TaskScreenViewState extends State<TaskScreenView> {
  late TaskScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TaskScreenController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshTasks();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refreshTasks() async {
    if (!mounted) return;
    final provider = context.read<DashboardProvider>();
    await provider.refreshTasks();
  }

  void _openAddTask(BuildContext context) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const AddTaskView(),
      ),
    )
        .then((_) {
      _refreshTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();

    final isMobile = ResponsiveUtils.isMobile(context);
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: AppColors.background,
        floatingActionButton: isMobile
            ? FloatingActionButton(
                onPressed: () => _openAddTask(context),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        body: Column(
          children: [
            // Navigation Tabs
            _buildNavigationTabs(),
            // Filter Section
            _buildFilterSection(provider),
            // Content Area
            Expanded(
              child: Consumer<TaskScreenController>(
                builder: (context, controller, _) {
                  if (controller.currentView == TaskViewMode.list) {
                    return _buildListView(provider);
                  } else if (controller.currentView == TaskViewMode.board) {
                    return _buildBoardView(provider);
                  } else if (controller.currentView == TaskViewMode.calendar) {
                    return _buildCalendarView(provider);
                  } else if (controller.currentView == TaskViewMode.overview) {
                    return _buildOverviewView(provider);
                  } else {
                    return _buildPlaceholderView(controller.currentView);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationTabs() {
    return Consumer<TaskScreenController>(
      builder: (context, controller, _) {
        final isMobile = ResponsiveUtils.isMobile(context);
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: AppColors.border.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? AppSpacing.sm : AppSpacing.lg),
                  child: Row(
                    children: [
                      _buildTab(
                        'Overview',
                        TaskViewMode.overview,
                        controller.currentView == TaskViewMode.overview,
                        () => controller.setView(TaskViewMode.overview),
                        isMobile: isMobile,
                      ),
                      _buildTab(
                        'List',
                        TaskViewMode.list,
                        controller.currentView == TaskViewMode.list,
                        () => controller.setView(TaskViewMode.list),
                        isMobile: isMobile,
                      ),
                      _buildTab(
                        'Board',
                        TaskViewMode.board,
                        controller.currentView == TaskViewMode.board,
                        () => controller.setView(TaskViewMode.board),
                        isMobile: isMobile,
                      ),
                      _buildTab(
                        'Calendar',
                        TaskViewMode.calendar,
                        controller.currentView == TaskViewMode.calendar,
                        () => controller.setView(TaskViewMode.calendar),
                        isMobile: isMobile,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isMobile) Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: ShadButton(
                  onPressed: () => _openAddTask(context),
                  variant: ShadButtonVariant.default_,
                  size: ShadButtonSize.md,
                  icon: const Icon(Icons.add, size: 18),
                  child: const Text('+ Add New'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(String label, TaskViewMode mode, bool isActive, VoidCallback onTap, {bool isMobile = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? AppSpacing.md : AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 13 : 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(DashboardProvider provider) {
    return Consumer<TaskScreenController>(
      builder: (context, controller, _) {
        final isMobile = ResponsiveUtils.isMobile(context);
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? AppSpacing.md : AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: AppColors.border.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Due Date Filter
                    _buildFilterDropdown(
                      label: _getDueDateLabel(controller),
                      items: ['This Week', 'This Month', 'Custom'],
                      onSelected: (value) {
                        if (value == 'Custom') {
                          _showDateRangePicker(context, controller);
                        } else {
                          controller.setDueDateFilter(value);
                        }
                      },
                      isMobile: true,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Assignee Filter
                    _buildFilterDropdown(
                      label: controller.selectedAssigneeFilter ?? 'All',
                      items: ['All', ...provider.members.map((m) => m.name)],
                      onSelected: (value) {
                        controller.setAssigneeFilter(value == 'All' ? null : value);
                      },
                      isMobile: true,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Priority Filter
                    _buildFilterDropdown(
                      label: controller.selectedPriorityFilter ?? 'All',
                      items: ['All', 'High', 'Medium', 'Low'],
                      onSelected: (value) {
                        controller.setPriorityFilter(value == 'All' ? null : value);
                      },
                      isMobile: true,
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Due Date Filter
                    _buildFilterDropdown(
                      label: _getDueDateLabel(controller),
                      items: ['This Week', 'This Month', 'Custom'],
                      onSelected: (value) {
                        if (value == 'Custom') {
                          _showDateRangePicker(context, controller);
                        } else {
                          controller.setDueDateFilter(value);
                        }
                      },
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Assignee Filter
                    _buildFilterDropdown(
                      label: controller.selectedAssigneeFilter ?? 'All',
                      items: ['All', ...provider.members.map((m) => m.name)],
                      onSelected: (value) {
                        controller.setAssigneeFilter(value == 'All' ? null : value);
                      },
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Priority Filter
                    _buildFilterDropdown(
                      label: controller.selectedPriorityFilter ?? 'All',
                      items: ['All', 'High', 'Medium', 'Low'],
                      onSelected: (value) {
                        controller.setPriorityFilter(value == 'All' ? null : value);
                      },
                    ),
                  ],
                ),
        );
      },
    );
  }

  String _getDueDateLabel(TaskScreenController controller) {
    if (controller.startDate != null && controller.endDate != null) {
      final start = DateFormat('MMM d').format(controller.startDate!);
      final end = DateFormat('MMM d').format(controller.endDate!);
      return '$start - $end';
    }
    return controller.selectedDueDateFilter ?? 'Due Date';
  }

  Widget _buildFilterDropdown({
    required String label,
    required List<String> items,
    required Function(String?) onSelected,
    bool isMobile = false,
  }) {
    return PopupMenuButton<String>(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        width: isMobile ? double.infinity : null,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
      itemBuilder: (context) => items.map((item) {
        return PopupMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onSelected: onSelected,
    );
  }

  Future<void> _showDateRangePicker(
    BuildContext context,
    TaskScreenController controller,
  ) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: controller.startDate != null && controller.endDate != null
          ? DateTimeRange(start: controller.startDate!, end: controller.endDate!)
          : null,
    );
    if (picked != null) {
      controller.setDateRange(picked.start, picked.end);
    }
  }

  Widget _buildListView(DashboardProvider provider) {
    return Consumer<TaskScreenController>(
      builder: (context, controller, _) {
        final isMobile = ResponsiveUtils.isMobile(context);
        final filteredTasks = controller.filterTasks(
          provider.tasks,
          members: provider.members,
        );
        final grouped = controller.groupTasksByStatus(filteredTasks);

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildListSection(
                'Pending',
                TaskStatus.pending,
                grouped[TaskStatus.pending] ?? [],
                Colors.grey,
                Icons.radio_button_unchecked,
              ),
              SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),
              _buildListSection(
                'In Progress',
                TaskStatus.inProgress,
                grouped[TaskStatus.inProgress] ?? [],
                AppColors.warning,
                Icons.access_time,
              ),
              SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),
              _buildListSection(
                'Completed',
                TaskStatus.completed,
                grouped[TaskStatus.completed] ?? [],
                AppColors.success,
                Icons.check_circle,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListSection(
    String title,
    TaskStatus status,
    List<TaskModel> tasks,
    Color color,
    IconData icon,
  ) {
    return _ListSection(
      title: title,
      status: status,
      tasks: tasks,
      color: color,
      icon: icon,
      onTaskTap: (task) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TaskDetailView(task: task),
          ),
        );
      },
    );
  }

  Widget _buildBoardView(DashboardProvider provider) {
    return Consumer<TaskScreenController>(
      builder: (context, controller, _) {
        final isMobile = ResponsiveUtils.isMobile(context);
        final filteredTasks = controller.filterTasks(
          provider.tasks,
          members: provider.members,
        );
        final grouped = controller.groupTasksByStatus(filteredTasks);

        if (isMobile) {
          // Horizontal scrollable board on mobile
          return Container(
            color: AppColors.background,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.85,
                    child: _buildBoardColumn(
                      'Pending',
                      TaskStatus.pending,
                      grouped[TaskStatus.pending] ?? [],
                      Colors.grey,
                      Icons.radio_button_unchecked,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.85,
                    child: _buildBoardColumn(
                      'In Progress',
                      TaskStatus.inProgress,
                      grouped[TaskStatus.inProgress] ?? [],
                      AppColors.warning,
                      Icons.access_time,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.85,
                    child: _buildBoardColumn(
                      'Completed',
                      TaskStatus.completed,
                      grouped[TaskStatus.completed] ?? [],
                      AppColors.success,
                      Icons.check_circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Desktop: 3 columns side by side
        return Container(
          color: AppColors.background,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildBoardColumn(
                  'Pending',
                  TaskStatus.pending,
                  grouped[TaskStatus.pending] ?? [],
                  Colors.grey,
                  Icons.radio_button_unchecked,
                ),
              ),
              Expanded(
                child: _buildBoardColumn(
                  'In Progress',
                  TaskStatus.inProgress,
                  grouped[TaskStatus.inProgress] ?? [],
                  AppColors.warning,
                  Icons.access_time,
                ),
              ),
              Expanded(
                child: _buildBoardColumn(
                  'Completed',
                  TaskStatus.completed,
                  grouped[TaskStatus.completed] ?? [],
                  AppColors.success,
                  Icons.check_circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBoardColumn(
    String title,
    TaskStatus status,
    List<TaskModel> tasks,
    Color color,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${tasks.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  icon: const Icon(Icons.add, size: 18, color: AppColors.textMuted),
                  onPressed: () => _openAddTask(context),
                  tooltip: 'Add Task',
                ),
              ],
            ),
          ),
          // Tasks
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        'No tasks',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      return _BoardTaskCard(
                        task: tasks[index],
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TaskDetailView(task: tasks[index]),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderView(TaskViewMode mode) {
    return Center(
      child: Text(
        '${mode.name.toUpperCase()} view coming soon',
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildOverviewView(DashboardProvider provider) {
    return Consumer<TaskScreenController>(
      builder: (context, controller, _) {
        // Use all tasks for overview statistics, not filtered
        final allTasks = provider.tasks;
        final filteredTasks = controller.filterTasks(
          provider.tasks,
          members: provider.members,
        );
        final grouped = controller.groupTasksByStatus(filteredTasks);
        
        // Calculate statistics
        final totalTasks = filteredTasks.length;
        final pendingCount = grouped[TaskStatus.pending]?.length ?? 0;
        final inProgressCount = grouped[TaskStatus.inProgress]?.length ?? 0;
        final completedCount = grouped[TaskStatus.completed]?.length ?? 0;
        final overdueCount = filteredTasks.where((task) => 
          task.dueDate.isBefore(DateTime.now()) && 
          task.status != TaskStatus.completed
        ).length;
        
        // Priority distribution
        final highPriorityCount = filteredTasks.where((t) => t.priority == TaskPriority.high).length;
        final mediumPriorityCount = filteredTasks.where((t) => t.priority == TaskPriority.medium).length;
        final lowPriorityCount = filteredTasks.where((t) => t.priority == TaskPriority.low).length;
        
        // Completion rate
        final completionRate = totalTasks > 0 ? (completedCount / totalTasks * 100).round() : 0;
        
        // Recent tasks (last 10, sorted by updatedAt or createdAt)
        final recentTasks = filteredTasks.toList()
          ..sort((a, b) {
            final aDate = b.updatedAt ?? b.createdAt ?? DateTime(1970);
            final bDate = a.updatedAt ?? a.createdAt ?? DateTime(1970);
            return bDate.compareTo(aDate);
          });
        final recentTasksList = recentTasks.take(10).toList();
        
        // Upcoming deadlines (this week + overdue tasks)
        // Use ALL tasks, not filtered, to show all upcoming deadlines
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        // Calculate start of current week (Monday)
        final weekday = today.weekday; // 1 = Monday, 7 = Sunday
        final daysFromMonday = weekday - 1;
        final startOfWeek = today.subtract(Duration(days: daysFromMonday));
        
        // Calculate end of current week (Sunday)
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        
        final upcomingTasks = allTasks.where((task) {
          // Exclude completed tasks
          if (task.status == TaskStatus.completed) return false;
          
          // Normalize task due date to just year/month/day (remove time component)
          final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
          
          // Include:
          // 1. Overdue tasks (past due) - show last 30 days of overdue
          // 2. Tasks due this week (from Monday to Sunday of current week)
          final thirtyDaysAgo = today.subtract(const Duration(days: 30));
          final isOverdue = taskDate.compareTo(today) < 0 && taskDate.compareTo(thirtyDaysAgo) >= 0;
          // Include tasks from start of week to end of week (inclusive)
          final isDueThisWeek = taskDate.compareTo(startOfWeek) >= 0 && taskDate.compareTo(endOfWeek) <= 0;
          
          // Show overdue tasks
          if (isOverdue) return true;
          // Show tasks due this week
          if (isDueThisWeek) return true;
          
          return false;
        }).toList()
          ..sort((a, b) {
            // Sort: overdue first (most overdue first), then due today, then upcoming (earliest first)
            final aDate = DateTime(a.dueDate.year, a.dueDate.month, a.dueDate.day);
            final bDate = DateTime(b.dueDate.year, b.dueDate.month, b.dueDate.day);
            final aIsOverdue = aDate.compareTo(today) < 0;
            final bIsOverdue = bDate.compareTo(today) < 0;
            final aIsDueToday = aDate.compareTo(today) == 0;
            final bIsDueToday = bDate.compareTo(today) == 0;
            
            // Overdue tasks first
            if (aIsOverdue && !bIsOverdue) return -1;
            if (!aIsOverdue && bIsOverdue) return 1;
            // Then tasks due today
            if (aIsDueToday && !bIsDueToday) return -1;
            if (!aIsDueToday && bIsDueToday) return 1;
            // Then sort by date
            return aDate.compareTo(bDate);
          });
        
        // Team performance
        final tasksByAssignee = <String, int>{};
        for (final task in filteredTasks) {
          if (task.assignedTo.isNotEmpty) {
            tasksByAssignee[task.assignedTo] = (tasksByAssignee[task.assignedTo] ?? 0) + 1;
          }
        }
        final sortedAssignees = tasksByAssignee.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        // This week's progress
        final weekStart = DateTime(now.year, now.month, now.day - now.weekday % 7);
        final thisWeekCompleted = filteredTasks.where((task) {
          if (task.status != TaskStatus.completed || task.updatedAt == null) return false;
          return task.updatedAt!.isAfter(weekStart);
        }).length;
        
        // This month's progress
        final monthStart = DateTime(now.year, now.month, 1);
        final thisMonthCompleted = filteredTasks.where((task) {
          if (task.status != TaskStatus.completed || task.updatedAt == null) return false;
          return task.updatedAt!.isAfter(monthStart);
        }).length;

        final isMobile = ResponsiveUtils.isMobile(context);
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistics Cards Row
              isMobile
                  ? Column(
                      children: [
                        _buildStatCard('Total Tasks', totalTasks.toString(), Icons.task, AppColors.primary),
                        const SizedBox(height: AppSpacing.md),
                        _buildStatCard('Pending', pendingCount.toString(), Icons.pending, Colors.grey, 
                          subtitle: totalTasks > 0 ? '${((pendingCount / totalTasks) * 100).round()}%' : '0%'),
                        const SizedBox(height: AppSpacing.md),
                        _buildStatCard('In Progress', inProgressCount.toString(), Icons.access_time, AppColors.warning,
                          subtitle: totalTasks > 0 ? '${((inProgressCount / totalTasks) * 100).round()}%' : '0%'),
                        const SizedBox(height: AppSpacing.md),
                        _buildStatCard('Completed', completedCount.toString(), Icons.check_circle, AppColors.success,
                          subtitle: totalTasks > 0 ? '${((completedCount / totalTasks) * 100).round()}%' : '0%'),
                        const SizedBox(height: AppSpacing.md),
                        _buildStatCard('Overdue', overdueCount.toString(), Icons.warning, AppColors.danger),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _buildStatCard('Total Tasks', totalTasks.toString(), Icons.task, AppColors.primary)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: _buildStatCard('Pending', pendingCount.toString(), Icons.pending, Colors.grey,
                          subtitle: totalTasks > 0 ? '${((pendingCount / totalTasks) * 100).round()}%' : '0%')),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: _buildStatCard('In Progress', inProgressCount.toString(), Icons.access_time, AppColors.warning,
                          subtitle: totalTasks > 0 ? '${((inProgressCount / totalTasks) * 100).round()}%' : '0%')),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: _buildStatCard('Completed', completedCount.toString(), Icons.check_circle, AppColors.success,
                          subtitle: totalTasks > 0 ? '${((completedCount / totalTasks) * 100).round()}%' : '0%')),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: _buildStatCard('Overdue', overdueCount.toString(), Icons.warning, AppColors.danger)),
                      ],
                    ),
              
              SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),
              
              // Second Row: Priority Distribution, Completion Rate, Quick Actions
              isMobile
                  ? Column(
                      children: [
                        _buildPriorityDistribution(highPriorityCount, mediumPriorityCount, lowPriorityCount, totalTasks),
                        const SizedBox(height: AppSpacing.lg),
                        _buildCompletionRate(completionRate, totalTasks, completedCount),
                        const SizedBox(height: AppSpacing.lg),
                        _buildQuickActions(context),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildPriorityDistribution(highPriorityCount, mediumPriorityCount, lowPriorityCount, totalTasks),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          flex: 2,
                          child: _buildCompletionRate(completionRate, totalTasks, completedCount),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          flex: 1,
                          child: _buildQuickActions(context),
                        ),
                      ],
                    ),
              
              SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),
              
              // Third Row: Recent Tasks and Upcoming Deadlines
              isMobile
                  ? Column(
                      children: [
                        _buildRecentTasks(context, recentTasksList, provider),
                        const SizedBox(height: AppSpacing.lg),
                        _buildUpcomingDeadlines(context, upcomingTasks, provider),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildRecentTasks(context, recentTasksList, provider),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: _buildUpcomingDeadlines(context, upcomingTasks, provider),
                        ),
                      ],
                    ),
              
              SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),
              
              // Fourth Row: Team Performance and Summary Widgets
              isMobile
                  ? Column(
                      children: [
                        _buildTeamPerformance(context, sortedAssignees, provider),
                        const SizedBox(height: AppSpacing.lg),
                        _buildSummaryWidgets(thisWeekCompleted, thisMonthCompleted, totalTasks),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildTeamPerformance(context, sortedAssignees, provider),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          flex: 1,
                          child: _buildSummaryWidgets(thisWeekCompleted, thisMonthCompleted, totalTasks),
                        ),
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriorityDistribution(int high, int medium, int low, int total) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Priority Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (total == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'No tasks available',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else ...[
            _buildPriorityBar('High Priority', high, total, AppColors.danger),
            const SizedBox(height: AppSpacing.md),
            _buildPriorityBar('Medium Priority', medium, total, AppColors.warning),
            const SizedBox(height: AppSpacing.md),
            _buildPriorityBar('Low Priority', low, total, AppColors.success),
          ],
        ],
      ),
    );
  }

  Widget _buildPriorityBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$count (${(percentage * 100).toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionRate(int rate, int total, int completed) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Completion Rate',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: rate / 100,
                        strokeWidth: 12,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '$rate%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '$completed / $total',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ShadButton(
            onPressed: () => _openAddTask(context),
            variant: ShadButtonVariant.default_,
            size: ShadButtonSize.md,
            width: double.infinity,
            icon: const Icon(Icons.add, size: 18),
            child: const Text('Add New Task'),
          ),
          const SizedBox(height: AppSpacing.sm),
          ShadButton(
            onPressed: () {
              final controller = context.read<TaskScreenController>();
              controller.setView(TaskViewMode.list);
            },
            variant: ShadButtonVariant.outline,
            size: ShadButtonSize.md,
            width: double.infinity,
            icon: const Icon(Icons.list, size: 18),
            child: const Text('View All Tasks'),
          ),
          const SizedBox(height: AppSpacing.sm),
          ShadButton(
            onPressed: () {
              // Navigate to list view with filter for overdue
              final controller = context.read<TaskScreenController>();
              controller.setView(TaskViewMode.list);
            },
            variant: ShadButtonVariant.outline,
            size: ShadButtonSize.md,
            width: double.infinity,
            icon: const Icon(Icons.warning, size: 18),
            child: const Text('View Overdue'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTasks(BuildContext context, List<TaskModel> tasks, DashboardProvider provider) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (tasks.length > 5)
                TextButton(
                  onPressed: () {
                    context.read<TaskScreenController>().setView(TaskViewMode.list);
                  },
                  child: const Text('View All'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (tasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'No recent tasks',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            ...tasks.take(5).map((task) {
              final assignee = _findAssigneeFromTask(provider, task.assignedTo);
              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TaskDetailView(task: task),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: task.status == TaskStatus.completed
                              ? AppColors.success
                              : task.status == TaskStatus.inProgress
                                  ? AppColors.warning
                                  : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (assignee.name.isNotEmpty)
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 8,
                                        backgroundColor: AppColors.primarySoft,
                                        child: Text(
                                          assignee.name[0].toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        assignee.name,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (assignee.name.isNotEmpty) const SizedBox(width: AppSpacing.sm),
                                Icon(Icons.calendar_today, size: 12, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('MMM d').format(task.dueDate),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildUpcomingDeadlines(BuildContext context, List<TaskModel> tasks, DashboardProvider provider) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming Deadlines',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (tasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'No upcoming deadlines',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            ...tasks.take(7).map((task) {
              final assignee = _findAssigneeFromTask(provider, task.assignedTo);
              // Normalize dates for accurate day calculation
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
              final daysUntil = taskDate.difference(today).inDays;
              final isOverdue = taskDate.compareTo(today) < 0;
              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TaskDetailView(task: task),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isOverdue ? AppColors.danger.withValues(alpha: 0.05) : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isOverdue ? AppColors.danger : AppColors.border.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: task.priority == TaskPriority.high
                              ? AppColors.danger
                              : task.priority == TaskPriority.medium
                                  ? AppColors.warning
                                  : AppColors.success,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  isOverdue
                                      ? 'Overdue'
                                      : daysUntil == 0
                                          ? 'Due today'
                                          : daysUntil == 1
                                              ? 'Due tomorrow'
                                              : 'Due in $daysUntil days',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isOverdue ? AppColors.danger : AppColors.textMuted,
                                    fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                                if (assignee.name.isNotEmpty) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    '• ${assignee.name}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTeamPerformance(BuildContext context, List<MapEntry<String, int>> assignees, DashboardProvider provider) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Performance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (assignees.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'No tasks assigned',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            ...assignees.take(5).map((entry) {
              final member = provider.members.firstWhere(
                (m) => m.name == entry.key || entry.key.contains(m.name),
                orElse: () => TeamMember(
                  id: '',
                  name: entry.key.split(' - ').first,
                  email: '',
                  role: '',
                  department: '',
                  isOnline: false,
                ),
              );
              final totalTasks = provider.tasks.length;
              final percentage = totalTasks > 0 ? (entry.value / totalTasks * 100) : 0.0;
              
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primarySoft,
                      child: Text(
                        member.name.isNotEmpty
                            ? member.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name.isNotEmpty ? member.name : entry.key,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage / 100,
                                    backgroundColor: AppColors.border,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '${entry.value} tasks',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSummaryWidgets(int thisWeekCompleted, int thisMonthCompleted, int totalTasks) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildSummaryItem('This Week', thisWeekCompleted.toString(), Icons.calendar_view_week),
          const SizedBox(height: AppSpacing.md),
          _buildSummaryItem('This Month', thisMonthCompleted.toString(), Icons.calendar_month),
          const SizedBox(height: AppSpacing.md),
          _buildSummaryItem('Total Tasks', totalTasks.toString(), Icons.task),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarView(DashboardProvider provider) {
    return Consumer<TaskScreenController>(
      builder: (context, controller, _) {
        final filteredTasks = controller.filterTasks(
          provider.tasks,
          members: provider.members,
        );
        return CalendarView(
          tasks: filteredTasks,
          onTaskTap: (task) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TaskDetailView(task: task),
              ),
            );
          },
        );
      },
    );
  }
}

class _ListSection extends StatefulWidget {
  const _ListSection({
    required this.title,
    required this.status,
    required this.tasks,
    required this.color,
    required this.icon,
    required this.onTaskTap,
  });

  final String title;
  final TaskStatus status;
  final List<TaskModel> tasks;
  final Color color;
  final IconData icon;
  final Function(TaskModel) onTaskTap;

  @override
  State<_ListSection> createState() => _ListSectionState();
}

class _ListSectionState extends State<_ListSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(widget.icon, size: 16, color: widget.color),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.tasks.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          // Tasks Table
          if (_isExpanded)
            widget.tasks.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Text(
                        'No tasks',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      // Table Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.border.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Checkbox(
                                value: false,
                                onChanged: null,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Name',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Assignee',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Due Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Priority',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: Icon(
                                Icons.more_vert,
                                size: 16,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Task Rows
                      ...widget.tasks.map((task) => _ListTaskRow(
                            task: task,
                            provider: provider,
                            onTap: () => widget.onTaskTap(task),
                          )),
                      // Add Task Button
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AddTaskView(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              const Icon(Icons.add, size: 16, color: AppColors.primary),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '+ Add Task',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
        ],
      ),
    );
  }
}

class _ListTaskRow extends StatelessWidget {
  const _ListTaskRow({
    required this.task,
    required this.provider,
    required this.onTap,
  });

  final TaskModel task;
  final DashboardProvider provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final dateFormatter = DateFormat(isMobile ? 'MMM d' : 'MMM d - hh:mm a', 'en_US');
    final isOverdue = task.dueDate.isBefore(DateTime.now()) && task.status != TaskStatus.completed;
    final assignee = _findAssigneeFromTask(provider, task.assignedTo);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? AppSpacing.sm : AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.border.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: task.status == TaskStatus.completed
                            ? const Icon(Icons.check_circle, size: 18, color: AppColors.success)
                            : task.status == TaskStatus.inProgress
                                ? InkWell(
                                    onTap: () => _updateTaskStatus(context, task, TaskStatus.completed),
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.warning,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.access_time,
                                          size: 10,
                                          color: AppColors.warning,
                                        ),
                                      ),
                                    ),
                                  )
                                : Checkbox(
                                    value: false,
                                    onChanged: (value) {
                                      if (value == true) {
                                        _updateTaskStatus(context, task, TaskStatus.inProgress);
                                      }
                                    },
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                      ),
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      if (task.assignedTo.isNotEmpty)
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.primarySoft,
                          child: Text(
                            assignee.name.isNotEmpty
                                ? assignee.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      if (task.assignedTo.isNotEmpty) const SizedBox(width: AppSpacing.xs),
                      Icon(Icons.calendar_today, size: 11, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        dateFormatter.format(task.dueDate),
                        style: TextStyle(
                          fontSize: 10,
                          color: isOverdue ? AppColors.danger : AppColors.textMuted,
                          fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      const Spacer(),
                      _buildPriorityIcon(task.priority),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: task.status == TaskStatus.completed
                        ? const Icon(Icons.check_circle, size: 20, color: AppColors.success)
                        : task.status == TaskStatus.inProgress
                            ? InkWell(
                                onTap: () => _updateTaskStatus(context, task, TaskStatus.completed),
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.warning,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.access_time,
                                      size: 10,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ),
                              )
                            : Checkbox(
                                value: false,
                                onChanged: (value) {
                                  if (value == true) {
                                    _updateTaskStatus(context, task, TaskStatus.inProgress);
                                  }
                                },
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        if (task.assignedTo.isNotEmpty)
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.primarySoft,
                            child: Text(
                              assignee.name.isNotEmpty
                                  ? assignee.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                    const Icon(Icons.person_add, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      task.assignedTo.isNotEmpty ? assignee.name : 'Assign',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      dateFormatter.format(task.dueDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue ? AppColors.danger : AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isOverdue)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.xs),
                      child: Text(
                        'Overdue',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.danger,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: _buildPriorityIcon(task.priority),
            ),
            SizedBox(
              width: 40,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 16, color: AppColors.textMuted),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16, color: AppColors.textPrimary),
                          SizedBox(width: AppSpacing.sm),
                          Text('Edit Task'),
                        ],
                      ),
                    ),
                    PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 16, color: AppColors.textPrimary),
                          SizedBox(width: AppSpacing.sm),
                          Text('View Details'),
                        ],
                      ),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'status_pending',
                      enabled: task.status != TaskStatus.pending,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Text('Set to Pending'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'status_inProgress',
                      enabled: task.status != TaskStatus.inProgress,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Text('Set to In Progress'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'status_completed',
                      enabled: task.status != TaskStatus.completed,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Text('Set to Completed'),
                        ],
                      ),
                    ),
                    PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                          SizedBox(width: AppSpacing.sm),
                          Text('Delete Task', style: TextStyle(color: AppColors.danger)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EditTaskView(task: task),
                        ),
                      );
                      if (context.mounted) {
                        final provider = context.read<DashboardProvider>();
                        await provider.refreshTasks();
                      }
                    } else if (value == 'view') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TaskDetailView(task: task),
                        ),
                      );
                    } else if (value == 'delete') {
                      await _confirmDeleteTask(context, task, provider);
                    } else if (value.startsWith('status_')) {
                      TaskStatus newStatus;
                      switch (value) {
                        case 'status_pending':
                          newStatus = TaskStatus.pending;
                          break;
                        case 'status_inProgress':
                          newStatus = TaskStatus.inProgress;
                          break;
                        case 'status_completed':
                          newStatus = TaskStatus.completed;
                          break;
                        default:
                          return;
                      }
                      await _updateTaskStatus(context, task, newStatus);
                    }
                  },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityIcon(TaskPriority priority) {
    Color color;
    IconData icon;
    switch (priority) {
      case TaskPriority.high:
        color = AppColors.danger;
        icon = Icons.flag;
        break;
      case TaskPriority.medium:
        color = AppColors.warning;
        icon = Icons.flag;
        break;
      case TaskPriority.low:
        color = AppColors.success;
        icon = Icons.flag;
        break;
    }

    return Icon(icon, size: 14, color: color);
  }

  Future<void> _updateTaskStatus(BuildContext context, TaskModel task, TaskStatus newStatus) async {
    try {
      await provider.updateTaskStatus(task.id, newStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ShadAlert(
              title: 'Success',
              description: 'Task status updated to ${newStatus.name}',
              variant: ShadAlertVariant.success,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.all(16),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ShadAlert(
              title: 'Error',
              description: 'Failed to update task status: ${e.toString()}',
              variant: ShadAlertVariant.destructive,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.all(16),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteTask(BuildContext context, TaskModel task, DashboardProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: 'Delete Task',
        content: Text(
          'Are you sure you want to delete "${task.title}"? This action cannot be undone.',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          ShadButton(
            onPressed: () => Navigator.of(context).pop(false),
            variant: ShadButtonVariant.outline,
            child: const Text('Cancel'),
          ),
          const SizedBox(width: AppSpacing.sm),
          ShadButton(
            onPressed: () => Navigator.of(context).pop(true),
            variant: ShadButtonVariant.destructive,
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await provider.deleteTask(task.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: ShadAlert(
                title: 'Success',
                description: 'Task deleted successfully',
                variant: ShadAlertVariant.success,
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              padding: const EdgeInsets.all(16),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: ShadAlert(
                title: 'Error',
                description: 'Failed to delete task: ${e.toString()}',
                variant: ShadAlertVariant.destructive,
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              padding: const EdgeInsets.all(16),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}

class _BoardTaskCard extends StatelessWidget {
  const _BoardTaskCard({
    required this.task,
    required this.onTap,
  });

  final TaskModel task;
  final VoidCallback onTap;

  Future<void> _updateTaskStatus(BuildContext context, TaskModel task, TaskStatus newStatus) async {
    final provider = context.read<DashboardProvider>();
    try {
      await provider.updateTaskStatus(task.id, newStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ShadAlert(
              title: 'Success',
              description: 'Task status updated to ${newStatus.name}',
              variant: ShadAlertVariant.success,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.all(16),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ShadAlert(
              title: 'Error',
              description: 'Failed to update task status: ${e.toString()}',
              variant: ShadAlertVariant.destructive,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.all(16),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleSubtask(BuildContext context, TaskModel task, String subtaskId) async {
    final provider = context.read<DashboardProvider>();
    try {
      // Find the subtask and toggle its completion status
      final updatedSubTasks = task.subTasks.map((sub) {
        if (sub.id == subtaskId) {
          return SubTask(
            id: sub.id,
            label: sub.label,
            isDone: !sub.isDone,
          );
        }
        return sub;
      }).toList();

      // Update the task with the new subtasks
      final updatedTask = task.copyWith(subTasks: updatedSubTasks);
      await provider.updateTask(updatedTask);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ShadAlert(
              title: 'Error',
              description: 'Failed to update subtask: ${e.toString()}',
              variant: ShadAlertVariant.destructive,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.all(16),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final dateFormatter = DateFormat('MMM d - hh:mm a', 'en_US');
    final isOverdue = task.dueDate.isBefore(DateTime.now()) && task.status != TaskStatus.completed;
    final assignee = _findAssigneeFromTask(provider, task.assignedTo);

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            // Subtasks (if any)
            if (task.subTasks.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              ...task.subTasks.take(3).map((sub) {
                return InkWell(
                  onTap: () => _toggleSubtask(context, task, sub.id),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: Checkbox(
                            value: sub.isDone,
                            onChanged: (_) => _toggleSubtask(context, task, sub.id),
                            activeColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.border, width: 1.5),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            sub.label,
                            style: TextStyle(
                              fontSize: 10,
                              color: sub.isDone
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary,
                              decoration: sub.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (task.subTasks.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '+${task.subTasks.length - 3} more',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.xs),
            ],
            // Footer with assignee, date, priority
            Row(
              children: [
                // Assignee
                if (task.assignedTo.isNotEmpty)
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primarySoft,
                    child: Text(
                      assignee.name.isNotEmpty
                          ? assignee.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  const Icon(Icons.person_add, size: 16, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.xs),
                // Date
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          dateFormatter.format(task.dueDate),
                          style: TextStyle(
                            fontSize: 11,
                            color: isOverdue ? AppColors.danger : AppColors.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOverdue)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            'Overdue',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.danger,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Priority
                _buildPriorityIcon(task.priority),
                // More options
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 16, color: AppColors.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16, color: AppColors.textPrimary),
                          SizedBox(width: AppSpacing.sm),
                          Text('Edit Task'),
                        ],
                      ),
                    ),
                    PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 16, color: AppColors.textPrimary),
                          SizedBox(width: AppSpacing.sm),
                          Text('View Details'),
                        ],
                      ),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'status_pending',
                      enabled: task.status != TaskStatus.pending,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Text('Set to Pending'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'status_inProgress',
                      enabled: task.status != TaskStatus.inProgress,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Text('Set to In Progress'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'status_completed',
                      enabled: task.status != TaskStatus.completed,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Text('Set to Completed'),
                        ],
                      ),
                    ),
                    PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                          SizedBox(width: AppSpacing.sm),
                          Text('Delete Task', style: TextStyle(color: AppColors.danger)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EditTaskView(task: task),
                        ),
                      );
                      if (context.mounted) {
                        await provider.refreshTasks();
                      }
                    } else if (value == 'view') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TaskDetailView(task: task),
                        ),
                      );
                    } else if (value == 'delete') {
                      await _confirmDeleteTask(context, task, provider);
                    } else if (value.startsWith('status_')) {
                      TaskStatus newStatus;
                      switch (value) {
                        case 'status_pending':
                          newStatus = TaskStatus.pending;
                          break;
                        case 'status_inProgress':
                          newStatus = TaskStatus.inProgress;
                          break;
                        case 'status_completed':
                          newStatus = TaskStatus.completed;
                          break;
                        default:
                          return;
                      }
                      await _updateTaskStatus(context, task, newStatus);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityIcon(TaskPriority priority) {
    Color color;
    String label;
    switch (priority) {
      case TaskPriority.high:
        color = AppColors.danger;
        label = 'High Priority';
        break;
      case TaskPriority.medium:
        color = AppColors.primary;
        label = 'Normal Priority';
        break;
      case TaskPriority.low:
        color = AppColors.success;
        label = 'Low Priority';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.flag, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteTask(BuildContext context, TaskModel task, DashboardProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: 'Delete Task',
        content: Text(
          'Are you sure you want to delete "${task.title}"? This action cannot be undone.',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          ShadButton(
            onPressed: () => Navigator.of(context).pop(false),
            variant: ShadButtonVariant.outline,
            child: const Text('Cancel'),
          ),
          const SizedBox(width: AppSpacing.sm),
          ShadButton(
            onPressed: () => Navigator.of(context).pop(true),
            variant: ShadButtonVariant.destructive,
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await provider.deleteTask(task.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: ShadAlert(
                title: 'Success',
                description: 'Task deleted successfully',
                variant: ShadAlertVariant.success,
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              padding: const EdgeInsets.all(16),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: ShadAlert(
                title: 'Error',
                description: 'Failed to delete task: ${e.toString()}',
                variant: ShadAlertVariant.destructive,
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              padding: const EdgeInsets.all(16),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}

