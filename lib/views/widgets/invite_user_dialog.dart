import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../services/invite_service.dart';
import '../../widgets/shadcn/app_button.dart';
import '../../widgets/shadcn/shadcn_widgets.dart';

class InviteUserDialog extends StatefulWidget {
  const InviteUserDialog({super.key});

  @override
  State<InviteUserDialog> createState() => _InviteUserDialogState();
}

class _InviteUserDialogState extends State<InviteUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _inviteService = InviteService();
  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendInvite() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSending = true);

    try {
      final email = _emailController.text.trim();
      final success = await _inviteService.sendInvite(email);

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation Sent!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _showError('Failed to send invitation. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      // Extract more user-friendly error message
      String errorMessage = 'Failed to send invitation';
      final errorString = e.toString();
      if (errorString.contains('internal')) {
        errorMessage = 'Server error. Please check if the function is deployed and try again.';
      } else if (errorString.contains('unauthenticated')) {
        errorMessage = 'Please log in to send invitations.';
      } else if (errorString.contains('invalid-argument')) {
        errorMessage = 'Invalid email address. Please check and try again.';
      } else if (errorString.isNotEmpty) {
        // Try to extract meaningful error message
        final match = RegExp(r'Error:\s*(.+?)(?:\n|$)').firstMatch(errorString);
        if (match != null) {
          errorMessage = match.group(1) ?? errorMessage;
        } else {
          errorMessage = errorString;
        }
      }
      _showError(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.send,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text(
                    'Invite User',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _isSending ? null : () => Navigator.of(context).pop(),
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Email input
              const Text(
                'Email Address',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_isSending,
                decoration: InputDecoration(
                  hintText: 'Enter email address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(fontSize: 15),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!_isValidEmail(value.trim())) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    variant: AppButtonVariant.outline,
                    onPressed: _isSending ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    isLoading: _isSending,
                    onPressed: _isSending ? null : _handleSendInvite,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.send, size: 18),
                        SizedBox(width: 6),
                        Text('Send Invite'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

