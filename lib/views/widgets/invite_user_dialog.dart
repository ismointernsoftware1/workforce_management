import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/role_model.dart';
import '../../services/invite_service.dart';
import '../../services/role_service.dart';
import '../../widgets/shadcn/app_button.dart';
import '../../widgets/shadcn/app_select.dart';
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
  final _roleService = RoleService();
  bool _isSending = false;
  String? _selectedRoleId;
  List<RoleModel> _roles = [];

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await _roleService.getAllRoles();
      if (mounted) {
        setState(() {
          _roles = roles;
          if (_roles.isNotEmpty && _selectedRoleId == null) {
            _selectedRoleId = _roles.first.roleId;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading roles: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendInvite() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      _showError('Email is required');
      return;
    }
    
    if (!_isValidEmail(email)) {
      _showError('Please enter a valid email address');
      return;
    }

    if (_selectedRoleId == null) {
      _showError('Please select a role');
      return;
    }

    setState(() => _isSending = true);

    try {
      final email = _emailController.text.trim();
      await _inviteService.createInvite(email, _selectedRoleId!);

      if (!mounted) return;

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invitation Sent!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to send invitation: ${e.toString()}');
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
              ShadInput(
                controller: _emailController,
                placeholder: const Text('Enter email address'),
                keyboardType: TextInputType.emailAddress,
                readOnly: _isSending,
              ),
              const SizedBox(height: AppSpacing.lg),
              // Role selection
              const Text(
                'Role',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppSelect<String>(
                value: _selectedRoleId,
                options: _roles.map((role) {
                  return SelectOption<String>(
                    value: role.roleId,
                    label: role.roleName,
                  );
                }).toList(),
                selectedOptionBuilder: (context, value) {
                  if (value == null || _roles.isEmpty) {
                    return const Text('Select a role');
                  }
                  final role = _roles.firstWhere(
                    (r) => r.roleId == value,
                    orElse: () => _roles.first,
                  );
                  return Text(role.roleName);
                },
                onChanged: _isSending
                    ? (_) {}
                    : (String? value) {
                        setState(() => _selectedRoleId = value);
                      },
                placeholder: 'Select a role',
                enabled: !_isSending,
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
