import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../components/shadcn/shadcn.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/task_approval.dart';
import '../../models/task_model.dart';
import '../../providers/dashboard_provider.dart';
import '../tasks/edit_task_view.dart';
import '../tasks/task_detail_view.dart';
import '../tasks/task_audit_logs_view.dart';
import '../tasks/approval_workflow_view.dart';

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
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.adjust_rounded,
                color: _priorityColor,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: _StatusDropdown(
                  task: task,
                  statusLabel: _statusLabel,
                  color: _priorityColor,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              ShadTooltip(
                message: 'Edit Task',
                child: ShadButton(
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
                  variant: ShadButtonVariant.ghost,
                  size: ShadButtonSize.icon,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  child: const SizedBox.shrink(),
                ),
              ),
              ShadTooltip(
                message: 'Delete Task',
                child: ShadButton(
                  onPressed: () => _showDeleteConfirmation(context),
                  variant: ShadButtonVariant.ghost,
                  size: ShadButtonSize.icon,
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                  child: const SizedBox.shrink(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            task.description,
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _InfoBadge(
                label: 'Priority',
                value: _priorityLabel,
                color: _priorityColor.withValues(alpha: 0.15),
                textColor: _priorityColor,
                useShadBadge: true,
              ),
              _InfoBadge(
                label: 'Due',
                value: dateFormatter.format(task.dueDate),
              ),
              _InfoBadge(
                label: 'Assigned to',
                value: task.assignedTo,
              ),
              if (task.hasLocation && task.location != null)
                _InfoBadge(
                  label: 'Location',
                  value: 'Set',
                ),
              if (task.attachments.isNotEmpty)
                _InfoBadge(
                  label: 'Files',
                  value: '${task.attachments.length}',
                ),
              if (task.approvalType != TaskApprovalType.none && task.approvals.isNotEmpty)
                _InfoBadge(
                  label: 'Approvals',
                  value: '${task.approvals.where((a) => a.status == ApprovalStatus.approved).length}/${task.approvals.length}',
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Action Buttons Row
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
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
              if (task.approvalType != TaskApprovalType.none)
                ShadButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ApprovalWorkflowView(task: task),
                      ),
                    );
                  },
                  variant: ShadButtonVariant.ghost,
                  size: ShadButtonSize.sm,
                  icon: const Icon(Icons.verified, size: 16),
                  child: const Text('Approve'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Subtasks (${task.subTasks.where((s) => s.isDone).length}/${task.subTasks.length})',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...task.subTasks.map(
            (sub) => Row(
              children: [
                Checkbox(
                  value: sub.isDone,
                  onChanged: (_) {},
                  activeColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    sub.label,
                    style: TextStyle(
                      color: sub.isDone
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
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

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.label,
    required this.value,
    this.color,
    this.textColor,
    this.useShadBadge = false,
  });

  final String label;
  final String value;
  final Color? color;
  final Color? textColor;
  final bool useShadBadge;

  @override
  Widget build(BuildContext context) {
    if (useShadBadge && label == 'Priority') {
      ShadBadgeVariant variant;
      if (textColor == AppColors.danger) {
        variant = ShadBadgeVariant.destructive;
      } else if (textColor == AppColors.warning) {
        variant = ShadBadgeVariant.secondary;
      } else {
        variant = ShadBadgeVariant.default_;
      }
      
      return ShadBadge(
        label: '$label: $value',
        variant: variant,
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color ?? AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            value,
            style: TextStyle(
              color: textColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: AppColors.border),
      ),
      child: ShadSelect<String>(
        value: statusLabel,
        items: const [
          ShadSelectItem(value: 'Pending', label: 'Pending'),
          ShadSelectItem(value: 'In Progress', label: 'In Progress'),
          ShadSelectItem(value: 'Completed', label: 'Completed'),
        ],
        onChanged: (String? newStatus) async {
          if (newStatus == null) return;
          
          TaskStatus status;
          switch (newStatus) {
            case 'Pending':
              status = TaskStatus.pending;
              break;
            case 'In Progress':
              status = TaskStatus.inProgress;
              break;
            case 'Completed':
              status = TaskStatus.completed;
              break;
            default:
              return;
          }

          final provider = Provider.of<DashboardProvider>(context, listen: false);
          try {
            await provider.updateTaskStatus(task.id, status);
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

