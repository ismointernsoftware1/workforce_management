import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:shadcn_ui/shadcn_ui.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/task_model.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/shadcn/shadcn_widgets.dart';
import '../tasks/edit_task_view.dart';
import '../tasks/task_detail_view.dart';
import '../tasks/task_audit_logs_view.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
  });

  final TaskModel task;

  Color get _priorityColor {
    switch (task.priority) {
      case TaskPriority.low:
        return AppColors.success;
      case TaskPriority.medium:
        return AppColors.warning;
      case TaskPriority.high:
        return AppColors.danger;
    }
  }

  String get _priorityLabel {
    switch (task.priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  String get _statusLabel {
    switch (task.status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MM/dd/yyyy');
    return Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _StatusDropdown(
                  task: task,
                  statusLabel: _statusLabel,
                  color: _priorityColor,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Details section with labels and values
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Priority',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _priorityLabel,
                        style: TextStyle(
                          color: _priorityColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Due Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormatter.format(task.dueDate),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigned to',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.assignedTo,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Action buttons
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                AppButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TaskDetailView(task: task),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility, size: 16),
                      SizedBox(width: 4),
                      Text('View Details'),
                    ],
                  ),
                ),
                ShadIconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TaskAuditLogsView(task: task),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history, size: 16),
                ),
                AppButton(
                  variant: AppButtonVariant.outline,
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EditTaskView(task: task),
                      ),
                    );
                    if (context.mounted) {
                      await Provider.of<DashboardProvider>(context, listen: false)
                          .refreshTasks();
                    }
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, size: 16),
                      SizedBox(width: 4),
                      Text('Edit'),
                    ],
                  ),
                ),
                ShadIconButton(
                  onPressed: () => _showDeleteConfirmation(context),
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                ),
              ],
            ),
            if (task.subTasks.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Subtasks (${task.subTasks.where((s) => s.isDone).length}/${task.subTasks.length})',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ...task.subTasks.map(
                (sub) => InkWell(
                  onTap: () => _toggleSubtask(context, sub.id),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: Checkbox(
                            value: sub.isDone,
                            onChanged: (_) => _toggleSubtask(context, sub.id),
                            activeColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.border, width: 1.5),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            sub.label,
                            style: TextStyle(
                              color: sub.isDone
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSubtask(BuildContext context, String subtaskId) async {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
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
            content: Text('Failed to update subtask: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Delete Task'),
        child: Text(
          'Are you sure you want to delete "${task.title}"? This action cannot be undone.',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      try {
        await provider.deleteTask(task.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Task deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete task: ${e.toString()}'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({
    required this.task,
    required this.statusLabel,
    required this.color,
  });

  final TaskModel task;
  final String statusLabel;
  final Color color;

  Color get _statusColor {
    switch (task.status) {
      case TaskStatus.pending:
        return AppColors.warning;
      case TaskStatus.inProgress:
        return AppColors.primary;
      case TaskStatus.completed:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: AppSelect<TaskStatus>(
        placeholder: statusLabel,
        value: task.status,
        options: [
          SelectOption<TaskStatus>(
            value: TaskStatus.pending,
            label: 'Pending',
          ),
          SelectOption<TaskStatus>(
            value: TaskStatus.inProgress,
            label: 'In Progress',
          ),
          SelectOption<TaskStatus>(
            value: TaskStatus.completed,
            label: 'Completed',
          ),
        ],
        selectedOptionBuilder: (context, value) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                statusLabel,
                style: TextStyle(
                  color: _statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          );
        },
        onChanged: (TaskStatus? newStatus) async {
          if (newStatus != null) {
            final provider = Provider.of<DashboardProvider>(context, listen: false);
            try {
              await provider.updateTaskStatus(task.id, newStatus);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update status: ${e.toString()}'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            }
          }
        },
      ),
    );
  }
}

