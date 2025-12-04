import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:shadcn_ui/shadcn_ui.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../widgets/shadcn/shadcn_widgets.dart';
import '../../models/task_approval.dart';
import '../../models/task_model.dart';

class ApprovalWorkflowView extends StatefulWidget {
  const ApprovalWorkflowView({
    super.key,
    required this.task,
  });

  final TaskModel task;

  @override
  State<ApprovalWorkflowView> createState() => _ApprovalWorkflowViewState();
}

class _ApprovalWorkflowViewState extends State<ApprovalWorkflowView> {
  final _commentsController = TextEditingController();
  ApprovalStatus? _selectedStatus;

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _submitApproval() async {
    if (_selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select approval status'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // TODO: Implement approval submission
    // This would update the task's approval list through the provider

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Task Approval',
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
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Info
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.task.description,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Current Approvals
            if (widget.task.approvals.isNotEmpty) ...[
              Text(
                'Current Approvals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...widget.task.approvals.map((approval) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _ApprovalStatusCard(approval: approval),
                );
              }),
              const SizedBox(height: AppSpacing.xl),
            ],

            // New Approval Form
            Text(
              'Submit Approval',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            AppSelect<ApprovalStatus>(
              placeholder: 'Select status',
              value: _selectedStatus,
              options: ApprovalStatus.values.map((status) {
                String label;
                switch (status) {
                  case ApprovalStatus.approved:
                    label = 'Approve';
                    break;
                  case ApprovalStatus.rejected:
                    label = 'Reject';
                    break;
                  case ApprovalStatus.pending:
                    label = 'Pending';
                    break;
                }
                return SelectOption<ApprovalStatus>(
                  value: status,
                  label: label,
                );
              }).toList(),
              selectedOptionBuilder: (context, value) {
                if (value == null) {
                  return const Text('Select status');
                }
                String label;
                switch (value) {
                  case ApprovalStatus.approved:
                    label = 'Approve';
                    break;
                  case ApprovalStatus.rejected:
                    label = 'Reject';
                    break;
                  case ApprovalStatus.pending:
                    label = 'Pending';
                    break;
                }
                return Text(label);
              },
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            ShadInput(
              controller: _commentsController,
              placeholder: const Text('Add any comments...'),
            ),
            const SizedBox(height: AppSpacing.xl),

            AppButton(
              onPressed: _submitApproval,
              child: const Text('Submit Approval'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApprovalStatusCard extends StatelessWidget {
  const _ApprovalStatusCard({required this.approval});

  final TaskApproval approval;

  @override
  Widget build(BuildContext context) {
    String statusText;
    IconData statusIcon;
    Color iconColor;

    switch (approval.status) {
      case ApprovalStatus.approved:
        statusText = 'Approved';
        statusIcon = Icons.check_circle;
        iconColor = AppColors.success;
        break;
      case ApprovalStatus.rejected:
        statusText = 'Rejected';
        statusIcon = Icons.cancel;
        iconColor = AppColors.danger;
        break;
      case ApprovalStatus.pending:
        statusText = 'Pending';
        statusIcon = Icons.pending;
        iconColor = AppColors.warning;
        break;
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(statusIcon, color: iconColor, size: 24),
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
                if (approval.approvedAt != null)
                  Text(
                    DateFormat('MM/dd/yyyy hh:mm a').format(approval.approvedAt!),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                if (approval.comments != null && approval.comments!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    approval.comments!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
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

