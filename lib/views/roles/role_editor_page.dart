import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/permission_set.dart';
import '../../models/permissions_model.dart';
import '../../models/role_model.dart';
import '../../services/role_service.dart';
import '../../widgets/shadcn/shadcn_widgets.dart';

/// RoleEditorPage - form to create/edit roles with permission toggles
class RoleEditorPage extends StatefulWidget {
  const RoleEditorPage({
    super.key,
    this.role,
  });

  final RoleModel? role;

  @override
  State<RoleEditorPage> createState() => _RoleEditorPageState();
}

class _RoleEditorPageState extends State<RoleEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _roleNameController = TextEditingController();
  final RoleService _roleService = RoleService();

  // Permission states for each resource
  bool _teamCreate = false;
  bool _teamRead = false;
  bool _teamUpdate = false;
  bool _teamDelete = false;

  bool _userCreate = false;
  bool _userRead = false;
  bool _userUpdate = false;
  bool _userDelete = false;

  bool _chatCreate = false;
  bool _chatRead = false;
  bool _chatUpdate = false;
  bool _chatDelete = false;

  bool _taskCreate = false;
  bool _taskRead = false;
  bool _taskUpdate = false;
  bool _taskDelete = false;

  bool _expenseCreate = false;
  bool _expenseRead = false;
  bool _expenseUpdate = false;
  bool _expenseDelete = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.role != null) {
      _roleNameController.text = widget.role!.roleName;
      final perms = widget.role!.permissions;
      
      _teamCreate = perms.teamControl.create;
      _teamRead = perms.teamControl.read;
      _teamUpdate = perms.teamControl.update;
      _teamDelete = perms.teamControl.delete;

      _userCreate = perms.userControl.create;
      _userRead = perms.userControl.read;
      _userUpdate = perms.userControl.update;
      _userDelete = perms.userControl.delete;

      _chatCreate = perms.chatControl.create;
      _chatRead = perms.chatControl.read;
      _chatUpdate = perms.chatControl.update;
      _chatDelete = perms.chatControl.delete;

      _taskCreate = perms.taskControl.create;
      _taskRead = perms.taskControl.read;
      _taskUpdate = perms.taskControl.update;
      _taskDelete = perms.taskControl.delete;

      _expenseCreate = perms.expenseControl.create;
      _expenseRead = perms.expenseControl.read;
      _expenseUpdate = perms.expenseControl.update;
      _expenseDelete = perms.expenseControl.delete;
    }
  }

  @override
  void dispose() {
    _roleNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.role == null ? 'Create Role' : 'Edit Role'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Role Name Input
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Role Name',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _roleNameController,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter role name',
                            hintStyle: TextStyle(
                              color: AppColors.textMuted.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: AppColors.border.withValues(alpha: 0.5),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: AppColors.border.withValues(alpha: 0.5),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceAlt,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Role name is required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Team Control Permissions
                  _buildPermissionSection(
                    title: 'Team Control',
                    create: _teamCreate,
                    read: _teamRead,
                    update: _teamUpdate,
                    delete: _teamDelete,
                    onChanged: (create, read, update, delete) {
                      setState(() {
                        _teamCreate = create;
                        _teamRead = read;
                        _teamUpdate = update;
                        _teamDelete = delete;
                      });
                    },
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // User Control Permissions
                  _buildPermissionSection(
                    title: 'User Control',
                    create: _userCreate,
                    read: _userRead,
                    update: _userUpdate,
                    delete: _userDelete,
                    onChanged: (create, read, update, delete) {
                      setState(() {
                        _userCreate = create;
                        _userRead = read;
                        _userUpdate = update;
                        _userDelete = delete;
                      });
                    },
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Chat Control Permissions
                  _buildPermissionSection(
                    title: 'Chat Control',
                    create: _chatCreate,
                    read: _chatRead,
                    update: _chatUpdate,
                    delete: _chatDelete,
                    onChanged: (create, read, update, delete) {
                      setState(() {
                        _chatCreate = create;
                        _chatRead = read;
                        _chatUpdate = update;
                        _chatDelete = delete;
                      });
                    },
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Task Control Permissions
                  _buildPermissionSection(
                    title: 'Task Control',
                    create: _taskCreate,
                    read: _taskRead,
                    update: _taskUpdate,
                    delete: _taskDelete,
                    onChanged: (create, read, update, delete) {
                      setState(() {
                        _taskCreate = create;
                        _taskRead = read;
                        _taskUpdate = update;
                        _taskDelete = delete;
                      });
                    },
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Expense Control Permissions
                  _buildPermissionSection(
                    title: 'Expense Control',
                    create: _expenseCreate,
                    read: _expenseRead,
                    update: _expenseUpdate,
                    delete: _expenseDelete,
                    onChanged: (create, read, update, delete) {
                      setState(() {
                        _expenseCreate = create;
                        _expenseRead = read;
                        _expenseUpdate = update;
                        _expenseDelete = delete;
                      });
                    },
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Save Button
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: AppButton(
                      label: widget.role == null ? 'Create Role' : 'Update Role',
                      icon: Icons.add,
                      variant: AppButtonVariant.primary,
                      fullWidth: true,
                      isLoading: _isLoading,
                      onPressed: _handleSave,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionSection({
    required String title,
    required bool create,
    required bool read,
    required bool update,
    required bool delete,
    required Function(bool, bool, bool, bool) onChanged,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildPermissionToggle(
                  label: 'Create',
                  value: create,
                  onChanged: (value) => onChanged(value, read, update, delete),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _buildPermissionToggle(
                  label: 'Read',
                  value: read,
                  onChanged: (value) => onChanged(create, value, update, delete),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _buildPermissionToggle(
                  label: 'Update',
                  value: update,
                  onChanged: (value) => onChanged(create, read, value, delete),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _buildPermissionToggle(
                  label: 'Delete',
                  value: delete,
                  onChanged: (value) => onChanged(create, read, update, value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: value 
              ? AppColors.primarySoft.withValues(alpha: 0.3)
              : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value 
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border.withValues(alpha: 0.3),
            width: value ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: value
                  ? Icon(
                      Icons.check_circle,
                      size: 14,
                      color: AppColors.primary,
                    )
                  : Icon(
                      Icons.circle_outlined,
                      size: 14,
                      color: AppColors.textMuted.withValues(alpha: 0.5),
                    ),
            ),
            const SizedBox(width: AppSpacing.xs - 2),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: value 
                      ? AppColors.primary 
                      : AppColors.textMuted.withValues(alpha: 0.7),
                  fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: -0.1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final permissions = PermissionsModel(
        teamControl: PermissionSet(
          create: _teamCreate,
          read: _teamRead,
          update: _teamUpdate,
          delete: _teamDelete,
        ),
        userControl: PermissionSet(
          create: _userCreate,
          read: _userRead,
          update: _userUpdate,
          delete: _userDelete,
        ),
        chatControl: PermissionSet(
          create: _chatCreate,
          read: _chatRead,
          update: _chatUpdate,
          delete: _chatDelete,
        ),
        taskControl: PermissionSet(
          create: _taskCreate,
          read: _taskRead,
          update: _taskUpdate,
          delete: _taskDelete,
        ),
        expenseControl: PermissionSet(
          create: _expenseCreate,
          read: _expenseRead,
          update: _expenseUpdate,
          delete: _expenseDelete,
        ),
      );

      if (widget.role == null) {
        // Create new role
        await _roleService.createRole(
          RoleModel(
            roleId: '',
            roleName: _roleNameController.text.trim(),
            permissions: permissions,
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Role created successfully')),
          );
          Navigator.pop(context);
        }
      } else {
        // Update existing role
        await _roleService.updateRole(
          widget.role!.copyWith(
            roleName: _roleNameController.text.trim(),
            permissions: permissions,
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Role updated successfully')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
