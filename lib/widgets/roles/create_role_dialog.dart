import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/permission_set.dart';
import '../../models/permissions_model.dart';
import '../../models/role_model.dart';
import '../../services/role_service.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/shadcn/shadcn_widgets.dart';
import 'multi_select_permission_dropdown.dart';

/// Create Role Dialog - Modal form for creating/editing roles
class CreateRoleDialog extends StatefulWidget {
  const CreateRoleDialog({
    super.key,
    this.role,
  });

  final RoleModel? role; // If provided, edit mode; otherwise, create mode

  @override
  State<CreateRoleDialog> createState() => _CreateRoleDialogState();
}

class _CreateRoleDialogState extends State<CreateRoleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _roleNameController = TextEditingController();
  final _roleDescriptionController = TextEditingController();
  final RoleService _roleService = RoleService();

  // Collapsible section states
  bool _teamExpanded = true;
  bool _chatExpanded = true;
  bool _taskExpanded = true;
  bool _expenseExpanded = true;

  // Selected permissions for each module
  List<String> _teamPermissions = [];
  List<String> _chatPermissions = [];
  List<String> _taskPermissions = [];
  List<String> _expensePermissions = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.role != null) {
      // Edit mode - populate fields
      _roleNameController.text = widget.role!.roleName;
      _populatePermissions(widget.role!.permissions);
    }
  }

  void _populatePermissions(PermissionsModel permissions) {
    _teamPermissions = _getSelectedPermissions(permissions.teamControl);
    _chatPermissions = _getSelectedPermissions(permissions.chatControl);
    _taskPermissions = _getSelectedPermissions(permissions.taskControl);
    _expensePermissions = _getSelectedPermissions(permissions.expenseControl);
  }

  List<String> _getSelectedPermissions(PermissionSet permissionSet) {
    final List<String> selected = [];
    if (permissionSet.create) selected.add('Create');
    if (permissionSet.read) selected.add('Read');
    if (permissionSet.update) selected.add('Update');
    if (permissionSet.delete) selected.add('Delete');
    return selected;
  }

  PermissionSet _getPermissionSet(List<String> selectedPermissions) {
    return PermissionSet(
      create: selectedPermissions.contains('Create'),
      read: selectedPermissions.contains('Read'),
      update: selectedPermissions.contains('Update'),
      delete: selectedPermissions.contains('Delete'),
    );
  }

  @override
  void dispose() {
    _roleNameController.dispose();
    _roleDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final permissions = PermissionsModel(
        teamControl: _getPermissionSet(_teamPermissions),
        chatControl: _getPermissionSet(_chatPermissions),
        taskControl: _getPermissionSet(_taskPermissions),
        expenseControl: _getPermissionSet(_expensePermissions),
      );

      if (widget.role != null) {
        // Update existing role
        await _roleService.updateRole(
          widget.role!.copyWith(
            roleName: _roleNameController.text.trim(),
            permissions: permissions,
          ),
        );
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Role updated successfully',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } else {
        // Create new role
        await _roleService.createRole(
          RoleModel(
            roleId: '',
            roleName: _roleNameController.text.trim(),
            permissions: permissions,
          ),
        );
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Role created successfully',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    
    final dialogContent = Container(
      constraints: BoxConstraints(
        maxWidth: isMobile ? double.infinity : 800,
        maxHeight: isMobile
            ? MediaQuery.of(context).size.height
            : MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 0 : 16),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isMobile ? AppSpacing.md : 24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.role != null ? 'Edit Role' : 'Create Role',
                          style: TextStyle(
                            fontSize: isMobile ? 20 : (isTablet ? 22 : 24),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Roles & Permissions',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? AppSpacing.md : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Role Name
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Role Name',
                          style: TextStyle(
                            fontSize: isMobile ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ShadInput(
                          controller: _roleNameController,
                          placeholder: const Text('Enter role name'),
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                        if (_formKey.currentState?.validate() == false &&
                            (_roleNameController.text.trim().isEmpty))
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Text(
                              'Role name is required',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                      ],
                    ),

                    SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),

                    // Role Description
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Role Description',
                          style: TextStyle(
                            fontSize: isMobile ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ShadInput(
                          controller: _roleDescriptionController,
                          placeholder: const Text('Enter role description'),
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),

                    SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),

                    // Permissions Section
                    Text(
                      'Permissions',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : (isTablet ? 17 : 18),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select all actions this role is allowed to perform.',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                    SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),

                    // Team Control
                    _buildPermissionModule(
                      context: context,
                      title: 'Team Control',
                      isExpanded: _teamExpanded,
                      onExpandedChanged: (expanded) {
                        setState(() => _teamExpanded = expanded);
                      },
                      selectedPermissions: _teamPermissions,
                      onPermissionsChanged: (permissions) {
                        setState(() => _teamPermissions = permissions);
                      },
                    ),

                    SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),

                    // Chat Control
                    _buildPermissionModule(
                      context: context,
                      title: 'Chat Control',
                      isExpanded: _chatExpanded,
                      onExpandedChanged: (expanded) {
                        setState(() => _chatExpanded = expanded);
                      },
                      selectedPermissions: _chatPermissions,
                      onPermissionsChanged: (permissions) {
                        setState(() => _chatPermissions = permissions);
                      },
                    ),

                    SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),

                    // Task Control
                    _buildPermissionModule(
                      context: context,
                      title: 'Task Control',
                      isExpanded: _taskExpanded,
                      onExpandedChanged: (expanded) {
                        setState(() => _taskExpanded = expanded);
                      },
                      selectedPermissions: _taskPermissions,
                      onPermissionsChanged: (permissions) {
                        setState(() => _taskPermissions = permissions);
                      },
                    ),

                    SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),

                    // Expense Control
                    _buildPermissionModule(
                      context: context,
                      title: 'Expense Control',
                      isExpanded: _expenseExpanded,
                      onExpandedChanged: (expanded) {
                        setState(() => _expenseExpanded = expanded);
                      },
                      selectedPermissions: _expensePermissions,
                      onPermissionsChanged: (permissions) {
                        setState(() => _expensePermissions = permissions);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Footer with buttons
            Container(
              padding: EdgeInsets.all(isMobile ? AppSpacing.md : 24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: isMobile
                  ?                       Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppButton(
                            onPressed: _isLoading ? null : _handleSave,
                            icon: Icons.save,
                            label: widget.role != null ? 'Update Role' : 'Save Role',
                            variant: AppButtonVariant.primary,
                            size: AppButtonSize.medium,
                            isLoading: _isLoading,
                            fullWidth: true,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                            label: 'Cancel',
                            variant: AppButtonVariant.outline,
                            size: AppButtonSize.medium,
                            fullWidth: true,
                          ),
                        ],
                      )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AppButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          label: 'Cancel',
                          variant: AppButtonVariant.outline,
                          size: isTablet ? AppButtonSize.medium : AppButtonSize.large,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        AppButton(
                          onPressed: _isLoading ? null : _handleSave,
                          icon: Icons.save,
                          label: widget.role != null ? 'Update Role' : 'Save Role',
                          variant: AppButtonVariant.primary,
                          size: isTablet ? AppButtonSize.medium : AppButtonSize.large,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );

    if (isMobile) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: dialogContent,
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: dialogContent,
    );
  }

  Widget _buildPermissionModule({
    required BuildContext context,
    required String title,
    required bool isExpanded,
    required ValueChanged<bool> onExpandedChanged,
    required List<String> selectedPermissions,
    required ValueChanged<List<String>> onPermissionsChanged,
  }) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    return AppCard(
      backgroundColor: Colors.white,
      showShadow: false,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: AppColors.border.withValues(alpha: 0.3),
      ),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => onExpandedChanged(!isExpanded),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: Row(
                children: [
                  SizedBox(
                    width: isMobile ? 18 : 20,
                    height: isMobile ? 18 : 20,
                    child: Checkbox(
                      value: selectedPermissions.length == 4,
                      onChanged: (value) {
                        if (value == true) {
                          onPermissionsChanged(['Create', 'Read', 'Update', 'Delete']);
                        } else {
                          onPermissionsChanged([]);
                        }
                      },
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  SizedBox(width: isMobile ? AppSpacing.xs : AppSpacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: isMobile ? 14 : (isTablet ? 14.5 : 15),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textMuted,
                    size: isMobile ? 18 : 20,
                  ),
                ],
              ),
            ),
          ),
          // Content
          if (isExpanded) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.border.withValues(alpha: 0.3),
            ),
            Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: MultiSelectPermissionDropdown(
                label: 'Select Permissions',
                selectedPermissions: selectedPermissions,
                onChanged: onPermissionsChanged,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

