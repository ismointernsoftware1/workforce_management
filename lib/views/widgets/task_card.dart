import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/task_model.dart';

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
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
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
              Text(
                task.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _StatusDropdown(
                statusLabel: _statusLabel,
                color: _priorityColor,
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined),
                color: AppColors.textMuted,
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.delete_outline),
                color: AppColors.textMuted,
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
              ),
              _InfoBadge(
                label: 'Due',
                value: dateFormatter.format(task.dueDate),
              ),
              _InfoBadge(
                label: 'Assigned to',
                value: task.assignedTo,
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
                Text(
                  sub.label,
                  style: TextStyle(
                    color: sub.isDone
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.label,
    required this.value,
    this.color,
    this.textColor,
  });

  final String label;
  final String value;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
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
    required this.statusLabel,
    required this.color,
  });

  final String statusLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<String>(
        value: statusLabel,
        dropdownColor: AppColors.surfaceAlt,
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.expand_more_rounded),
        items: const [
          DropdownMenuItem(value: 'Pending', child: Text('Pending')),
          DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
          DropdownMenuItem(value: 'Completed', child: Text('Completed')),
        ],
        onChanged: (_) {},
        style: const TextStyle(color: AppColors.textPrimary),
      ),
    );
  }
}

