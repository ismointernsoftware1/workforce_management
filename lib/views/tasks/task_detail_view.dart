import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:shadcn_ui/shadcn_ui.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../widgets/shadcn/shadcn_widgets.dart';
import '../../models/task_approval.dart';
import '../../models/task_attachment.dart';
import '../../models/task_model.dart';
import '../../providers/dashboard_provider.dart';
import '../../utils/responsive_utils.dart';

class TaskDetailView extends StatelessWidget {
  const TaskDetailView({
    super.key,
    required this.task,
  });

  final TaskModel task;

  Future<void> _openLocation(BuildContext context) async {
    if (task.location == null || task.location!.isEmpty) return;

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${task.location!.latitude},${task.location!.longitude}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MM/dd/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          task.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
            onPressed: () {
              // Navigate to edit view
              Navigator.of(context).pop();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.border.withValues(alpha: 0.5),
          ),
        ),
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: ResponsiveUtils.getPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            ShadBadge(
              child: Text(task.status.name.toUpperCase()),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Description
            Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              task.description,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Details Grid
            _DetailGrid(task: task, dateFormatter: dateFormatter),
            const SizedBox(height: AppSpacing.xl),

            // Location
            if (task.hasLocation && task.location != null && !task.location!.isEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  InkWell(
                    onTap: () => _openLocation(context),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (task.location!.placeName != null)
                                  Text(
                                    task.location!.placeName!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                Text(
                                  task.location!.address,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.open_in_new, size: 18, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),

            // Attachments
            if (task.attachments.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attachments (${task.attachments.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...task.attachments.map((attachment) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _AttachmentItem(attachment: attachment),
                    );
                  }),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),

            // Approvals
            if (task.approvalType != TaskApprovalType.none && task.approvals.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Approvals',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...task.approvals.map((approval) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _ApprovalItem(approval: approval),
                    );
                  }),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),

            // Subtasks
            if (task.subTasks.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subtasks (${task.subTasks.where((s) => s.isDone).length}/${task.subTasks.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...task.subTasks.map((sub) {
                    return InkWell(
                      onTap: () => _toggleSubtask(context, sub.id),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: sub.isDone,
                                onChanged: (_) => _toggleSubtask(context, sub.id),
                                activeColor: AppColors.success,
                                side: const BorderSide(color: AppColors.border, width: 1.5),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                sub.label,
                                style: TextStyle(
                                  color: sub.isDone
                                      ? AppColors.textMuted
                                      : AppColors.textPrimary,
                                  decoration: sub.isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
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
      
      // Refresh the view by popping and pushing again with updated task
      if (context.mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TaskDetailView(task: updatedTask),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update subtask: ${e.toString()}'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({
    required this.task,
    required this.dateFormatter,
  });

  final TaskModel task;
  final DateFormat dateFormatter;

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

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        _DetailChip(
          icon: Icons.flag,
          label: 'Priority',
          value: task.priority.name.toUpperCase(),
          color: _priorityColor,
        ),
        _DetailChip(
          icon: Icons.calendar_today,
          label: 'Due Date',
          value: dateFormatter.format(task.dueDate),
        ),
        _DetailChip(
          icon: Icons.person,
          label: 'Assigned To',
          value: task.assignedTo,
        ),
        if (task.createdAt != null)
          _DetailChip(
            icon: Icons.access_time,
            label: 'Created',
            value: dateFormatter.format(task.createdAt!),
          ),
      ],
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color ?? AppColors.textMuted),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttachmentItem extends StatelessWidget {
  const _AttachmentItem({required this.attachment});

  final TaskAttachment attachment;

  IconData _getFileIcon(String? fileType) {
    switch (fileType?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            _getFileIcon(attachment.fileType),
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (attachment.fileSize > 0)
                  Text(
                    _formatFileSize(attachment.fileSize),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          if (attachment.fileUrl.isNotEmpty)
            AppButton(
              onPressed: () async {
                final uri = Uri.parse(attachment.fileUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Icon(Icons.open_in_new, size: 18),
            ),
        ],
      ),
    );
  }
}

class _ApprovalItem extends StatelessWidget {
  const _ApprovalItem({required this.approval});

  final TaskApproval approval;

  @override
  Widget build(BuildContext context) {
    final String statusText;
    final IconData statusIcon;

    switch (approval.status) {
      case ApprovalStatus.approved:
        statusText = 'Approved';
        statusIcon = Icons.check_circle;
      case ApprovalStatus.rejected:
        statusText = 'Rejected';
        statusIcon = Icons.cancel;
      case ApprovalStatus.pending:
        statusText = 'Pending';
        statusIcon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(statusIcon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  approval.approverName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (approval.comments != null && approval.comments!.isNotEmpty)
                  Text(
                    approval.comments!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          ShadBadge(
            child: Text(statusText),
          ),
        ],
      ),
    );
  }
}

