import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../components/shadcn/shadcn.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/task_model.dart';
import '../../providers/dashboard_provider.dart';
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
                ShadButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TaskDetailView(task: task),
                      ),
                    );
                  },
                  variant: ShadButtonVariant.outline,
                  size: ShadButtonSize.sm,
                  icon: const Icon(Icons.visibility, size: 16),
                  child: const Text('View Details'),
                ),
                ShadButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TaskAuditLogsView(task: task),
                      ),
                    );
                  },
                  variant: ShadButtonVariant.ghost,
                  size: ShadButtonSize.sm,
                  icon: const Icon(Icons.history, size: 16),
                  child: const Text('Audit Logs'),
                ),
                ShadButton(
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
                  variant: ShadButtonVariant.outline,
                  size: ShadButtonSize.sm,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  child: const Text('Edit'),
                ),
                ShadButton(
                  onPressed: () => _showDeleteConfirmation(context),
                  variant: ShadButtonVariant.ghost,
                  size: ShadButtonSize.sm,
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                  child: const Text('Delete'),
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
                (sub) => Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: Checkbox(
                        value: sub.isDone,
                        onChanged: (_) {},
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
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
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
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      try {
        await provider.deleteTask(task.id);
        if (context.mounted) {
          ShadToast.show(
            context,
            title: 'Success',
            description: 'Task deleted successfully',
            variant: ShadToastVariant.success,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ShadToast.show(
            context,
            title: 'Error',
            description: 'Failed to delete task: ${e.toString()}',
            variant: ShadToastVariant.error,
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
      child: PopupMenuButton<TaskStatus>(
        padding: EdgeInsets.zero,
        icon: Row(
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
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: _statusColor,
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: TaskStatus.pending,
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
                const Text('Pending'),
              ],
            ),
          ),
          PopupMenuItem(
            value: TaskStatus.inProgress,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Text('In Progress'),
              ],
            ),
          ),
          PopupMenuItem(
            value: TaskStatus.completed,
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
                const Text('Completed'),
              ],
            ),
          ),
        ],
        onSelected: (TaskStatus newStatus) async {
          final provider = Provider.of<DashboardProvider>(context, listen: false);
          try {
            await provider.updateTaskStatus(task.id, newStatus);
          } catch (e) {
            if (context.mounted) {
              ShadToast.show(
                context,
                title: 'Error',
                description: 'Failed to update status: ${e.toString()}',
                variant: ShadToastVariant.error,
              );
            }
          }
        },
      ),
    );
  }
}

