import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:shadcn_ui/shadcn_ui.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../widgets/shadcn/shadcn_widgets.dart';
import '../../models/task_model.dart';
import '../../utils/responsive_utils.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({
    super.key,
    required this.tasks,
    required this.onTaskTap,
  });

  final List<TaskModel> tasks;
  final Function(TaskModel) onTaskTap;

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime _currentMonth = DateTime.now();

  Map<String, List<TaskModel>> _groupTasksByDate() {
    final grouped = <String, List<TaskModel>>{};
    for (final task in widget.tasks) {
      // Convert to local date and normalize to just year/month/day (remove time component)
      // This ensures UTC timestamps from Firestore are correctly converted to local dates
      final localDate = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );
      final dateKey = '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(task);
    }
    return grouped;
  }

  List<DateTime> _getDaysInMonth() {
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    
    // Only return days from the current month
    final days = <DateTime>[];
    for (int i = 1; i <= lastDay.day; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i));
    }
    
    return days;
  }

  Color _getTaskColor(TaskModel task) {
    switch (task.priority) {
      case TaskPriority.high:
        return AppColors.danger.withValues(alpha: 0.2);
      case TaskPriority.medium:
        return AppColors.warning.withValues(alpha: 0.2);
      case TaskPriority.low:
        return AppColors.success.withValues(alpha: 0.2);
    }
  }

  Color _getTaskBorderColor(TaskModel task) {
    switch (task.priority) {
      case TaskPriority.high:
        return AppColors.danger;
      case TaskPriority.medium:
        return AppColors.warning;
      case TaskPriority.low:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final groupedTasks = _groupTasksByDate();
    final days = _getDaysInMonth();
    final today = DateTime.now();
    
    // Count tasks by priority
    final highPriorityCount = widget.tasks.where((t) => t.priority == TaskPriority.high).length;
    final normalPriorityCount = widget.tasks.where((t) => t.priority == TaskPriority.medium || t.priority == TaskPriority.low).length;

    final priorityLegend = Container(
      width: isMobile ? double.infinity : 200,
      margin: EdgeInsets.only(
        top: AppSpacing.lg,
        right: isMobile ? 0 : AppSpacing.lg,
        bottom: AppSpacing.lg,
        left: isMobile ? AppSpacing.lg : 0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Priority',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _PriorityLegendItem(
            label: 'High Priority',
            count: highPriorityCount,
            color: AppColors.danger,
          ),
          const SizedBox(height: AppSpacing.sm),
          _PriorityLegendItem(
            label: 'Normal Priority',
            count: normalPriorityCount,
            color: AppColors.primary,
          ),
        ],
      ),
    );

    Widget _buildCalendarContent() {
      return Container(
        margin: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            // Month Navigation
            Container(
              padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: AppColors.textPrimary, size: isMobile ? 20 : 24),
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      DateFormat('MMMM yyyy').format(_currentMonth),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: AppColors.textPrimary, size: isMobile ? 20 : 24),
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                      });
                    },
                  ),
                ],
              ),
            ),
            // Day Headers
            Container(
              padding: EdgeInsets.symmetric(vertical: isMobile ? AppSpacing.xs : AppSpacing.sm),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                    .map((day) => Expanded(
                          child: Text(
                            day,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            // Calendar Grid
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = 7;
                  final itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * 4) / crossAxisCount;
                  
                  return GridView.builder(
                    padding: EdgeInsets.all(isMobile ? AppSpacing.xs : AppSpacing.sm),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: itemWidth / (itemWidth * (isMobile ? 1.5 : 1.2)),
                      crossAxisSpacing: isMobile ? 2 : 4,
                      mainAxisSpacing: isMobile ? 2 : 4,
                    ),
                    itemCount: days.length,
                    itemBuilder: (context, index) {
                      final date = days[index];
                      final isToday = date.year == today.year &&
                          date.month == today.month &&
                          date.day == today.day;
                      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      final dayTasks = groupedTasks[dateKey] ?? [];
                      final maxVisibleTasks = isMobile ? 2 : 3;

                      return Container(
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppColors.primarySoft.withValues(alpha: 0.3)
                              : AppColors.surface,
                          border: Border.all(
                            color: isToday
                                ? AppColors.primary
                                : AppColors.border.withValues(alpha: 0.3),
                            width: isToday ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(isMobile ? 2 : 4),
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                                  color: isToday ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: dayTasks.isEmpty
                                  ? const SizedBox.shrink()
                                  : ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: dayTasks.length > maxVisibleTasks
                                          ? maxVisibleTasks
                                          : dayTasks.length,
                                      itemBuilder: (context, taskIndex) {
                                        final task = dayTasks[taskIndex];
                                        return Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isMobile ? 1 : 2,
                                            vertical: isMobile ? 0.5 : 1,
                                          ),
                                          child: InkWell(
                                            onTap: () => widget.onTaskTap(task),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: isMobile ? 2 : 4,
                                                vertical: isMobile ? 1 : 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getTaskColor(task),
                                                border: Border.all(
                                                  color: _getTaskBorderColor(task),
                                                  width: 1,
                                                ),
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                              child: Text(
                                                task.title,
                                                style: TextStyle(
                                                  fontSize: isMobile ? 8 : 9,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.textPrimary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            if (dayTasks.length > maxVisibleTasks)
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 4),
                                child: InkWell(
                                  onTap: () => _showDayTasksDialog(context, date, dayTasks),
                                  child: Text(
                                    'View more',
                                    style: TextStyle(
                                      fontSize: isMobile ? 8 : 9,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                          ],
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

    return isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCalendarContent()),
              priorityLegend,
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCalendarContent()),
              priorityLegend,
            ],
          );
  }

  void _showDayTasksDialog(BuildContext context, DateTime date, List<TaskModel> tasks) {
    showDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('Tasks on ${DateFormat('MMM d, yyyy').format(date)}'),
        child: SizedBox(
          width: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onTaskTap(task);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: _getTaskColor(task),
                    border: Border.all(
                      color: _getTaskBorderColor(task),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          AppButton(
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _PriorityLegendItem extends StatelessWidget {
  const _PriorityLegendItem({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

