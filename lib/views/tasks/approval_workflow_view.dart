import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../components/shadcn/shadcn.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
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
          content: ShadAlert(
            title: 'Validation Error',
            description: 'Please select approval status',
            variant: ShadAlertVariant.destructive,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.all(16),
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
            ShadCard(
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

            ShadSelect<ApprovalStatus>(
              label: 'Approval Status *',
              hint: 'Select status',
              value: _selectedStatus,
              items: ApprovalStatus.values.map((status) {
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
                return ShadSelectItem<ApprovalStatus>(
                  value: status,
                  label: label,
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            ShadInput(
              controller: _commentsController,
              label: 'Comments (Optional)',
              hintText: 'Add any comments...',
              maxLines: 4,
            ),
            const SizedBox(height: AppSpacing.xl),

            ShadButton(
              onPressed: _submitApproval,
              variant: ShadButtonVariant.default_,
              size: ShadButtonSize.lg,
              width: double.infinity,
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
    ShadBadgeVariant variant;
    String statusText;
    IconData statusIcon;
    Color iconColor;

    switch (approval.status) {
      case ApprovalStatus.approved:
        variant = ShadBadgeVariant.default_;
        statusText = 'Approved';
        statusIcon = Icons.check_circle;
        iconColor = AppColors.success;
        break;
      case ApprovalStatus.rejected:
        variant = ShadBadgeVariant.destructive;
        statusText = 'Rejected';
        statusIcon = Icons.cancel;
        iconColor = AppColors.danger;
        break;
      case ApprovalStatus.pending:
        variant = ShadBadgeVariant.secondary;
        statusText = 'Pending';
        statusIcon = Icons.pending;
        iconColor = AppColors.warning;
        break;
    }

    return ShadCard(
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
            label: statusText,
            variant: variant,
          ),
        ],
      ),
    );
  }
}

