import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:shadcn_ui/shadcn_ui.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../widgets/shadcn/shadcn_widgets.dart';
import '../../models/task_audit_log.dart';
import '../../models/task_model.dart';
import '../../providers/dashboard_provider.dart';

class TaskAuditLogsView extends StatelessWidget {
  const TaskAuditLogsView({
    super.key,
    required this.task,
  });

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Task Audit Logs',
          style: TextStyle(
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.border.withValues(alpha: 0.5),
          ),
        ),
      ),
      backgroundColor: AppColors.background,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: provider.getTaskAuditLogs(task.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load audit logs: ${snapshot.error}'),
            );
          }

          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'No audit logs found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Audit logs will appear here as changes are made',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.xl),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final logData = logs[index];
              final log = TaskAuditLog.fromMap(logData, id: logData['id'] as String?);
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _AuditLogItem(log: log),
              );
            },
          );
        },
      ),
    );
  }
}

class _AuditLogItem extends StatelessWidget {
  const _AuditLogItem({required this.log});

  final TaskAuditLog log;

  IconData get _actionIcon {
    switch (log.action) {
      case AuditLogAction.created:
        return Icons.add_circle;
      case AuditLogAction.updated:
        return Icons.edit;
      case AuditLogAction.deleted:
        return Icons.delete;
      case AuditLogAction.statusChanged:
        return Icons.swap_horiz;
      case AuditLogAction.assigned:
        return Icons.person_add;
      case AuditLogAction.priorityChanged:
        return Icons.flag;
      case AuditLogAction.dueDateChanged:
        return Icons.calendar_today;
      case AuditLogAction.attachmentAdded:
        return Icons.attach_file;
      case AuditLogAction.attachmentRemoved:
        return Icons.delete_outline;
      case AuditLogAction.approvalRequested:
        return Icons.pending_actions;
      case AuditLogAction.approved:
        return Icons.check_circle;
      case AuditLogAction.rejected:
        return Icons.cancel;
      case AuditLogAction.commentAdded:
        return Icons.comment;
    }
  }

  Color get _actionColor {
    switch (log.action) {
      case AuditLogAction.created:
      case AuditLogAction.approved:
        return AppColors.success;
      case AuditLogAction.deleted:
      case AuditLogAction.rejected:
        return AppColors.danger;
      case AuditLogAction.updated:
      case AuditLogAction.statusChanged:
        return AppColors.primary;
      default:
        return AppColors.textMuted;
    }
  }

  String get _actionText {
    switch (log.action) {
      case AuditLogAction.created:
        return 'Task Created';
      case AuditLogAction.updated:
        return 'Task Updated';
      case AuditLogAction.deleted:
        return 'Task Deleted';
      case AuditLogAction.statusChanged:
        return 'Status Changed';
      case AuditLogAction.assigned:
        return 'Task Assigned';
      case AuditLogAction.priorityChanged:
        return 'Priority Changed';
      case AuditLogAction.dueDateChanged:
        return 'Due Date Changed';
      case AuditLogAction.attachmentAdded:
        return 'Attachment Added';
      case AuditLogAction.attachmentRemoved:
        return 'Attachment Removed';
      case AuditLogAction.approvalRequested:
        return 'Approval Requested';
      case AuditLogAction.approved:
        return 'Approved';
      case AuditLogAction.rejected:
        return 'Rejected';
      case AuditLogAction.commentAdded:
        return 'Comment Added';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final timeFormatter = DateFormat('hh:mm a');

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _actionColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_actionIcon, color: _actionColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _actionText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      '${dateFormatter.format(log.timestamp)} ${timeFormatter.format(log.timestamp)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'By ${log.actionByName}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (log.oldValue != null || log.newValue != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      if (log.oldValue != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'From: ${log.oldValue}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      if (log.newValue != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'To: ${log.newValue}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                if (log.description != null && log.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    log.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

