import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/role_model.dart';
import '../../services/role_service.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/shadcn/shadcn_widgets.dart';
import '../../widgets/shadcn/app_menu.dart';
import 'create_role_page.dart';

/// RoleListPage - List view of all roles with create/edit functionality
class RoleListPage extends StatefulWidget {
  const RoleListPage({super.key});

  @override
  State<RoleListPage> createState() => _RoleListPageState();
}

class _RoleListPageState extends State<RoleListPage> {
  final RoleService _roleService = RoleService();

  Future<void> _showCreateRoleDialog() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const CreateRolePage(),
      ),
    );
    if (result == true && mounted) {
      // Role was created/updated, refresh is automatic via StreamBuilder
    }
  }

  Future<void> _showEditRoleDialog(RoleModel role) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CreateRolePage(role: role),
      ),
    );
    if (result == true && mounted) {
      // Role was updated, refresh is automatic via StreamBuilder
    }
  }

  Future<void> _showDeleteConfirmation(RoleModel role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Role'),
        content: Text('Are you sure you want to delete "${role.roleName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _roleService.deleteRole(role.roleId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Role deleted successfully',
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
                      'Error deleting role: $e',
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
      }
    }
  }

  int _countPermissions(RoleModel role) {
    int count = 0;
    if (role.permissions.teamControl.create) count++;
    if (role.permissions.teamControl.read) count++;
    if (role.permissions.teamControl.update) count++;
    if (role.permissions.teamControl.delete) count++;
    if (role.permissions.chatControl.create) count++;
    if (role.permissions.chatControl.read) count++;
    if (role.permissions.chatControl.update) count++;
    if (role.permissions.chatControl.delete) count++;
    if (role.permissions.taskControl.create) count++;
    if (role.permissions.taskControl.read) count++;
    if (role.permissions.taskControl.update) count++;
    if (role.permissions.taskControl.delete) count++;
    if (role.permissions.expenseControl.create) count++;
    if (role.permissions.expenseControl.read) count++;
    if (role.permissions.expenseControl.update) count++;
    if (role.permissions.expenseControl.delete) count++;
    return count;
  }


  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      color: const Color(0xFFF7F8FA),
      child: Column(
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.all(
              isMobile ? AppSpacing.md : AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Roles & Permissions',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Manage user roles and their permissions',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        onPressed: _showCreateRoleDialog,
                        icon: Icons.add,
                        label: 'Add Role',
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.medium,
                        fullWidth: true,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: AppColors.primary,
                        size: isTablet ? 26 : 28,
                      ),
                      SizedBox(width: isTablet ? AppSpacing.sm : AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Roles & Permissions',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    fontSize: isTablet ? 20 : 24,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage user roles and their permissions',
                              style: TextStyle(
                                fontSize: isTablet ? 13 : 14,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppButton(
                        onPressed: _showCreateRoleDialog,
                        icon: Icons.add,
                        label: 'Add Role',
                        variant: AppButtonVariant.primary,
                        size: isTablet ? AppButtonSize.medium : AppButtonSize.large,
                      ),
                    ],
                  ),
          ),

          // Roles List
          Expanded(
            child: StreamBuilder<List<RoleModel>>(
              stream: _roleService.streamAllRoles(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                final roles = snapshot.data ?? [];
                if (roles.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 64,
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No roles found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Click "Add Role" to create your first role',
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
                  padding: EdgeInsets.all(
                    isMobile ? AppSpacing.md : AppSpacing.lg,
                  ),
                  itemCount: roles.length,
                  itemBuilder: (context, index) {
                    final role = roles[index];
                    final permissionCount = _countPermissions(role);
                    return AppCard(
                      margin: EdgeInsets.only(
                        bottom: AppSpacing.md,
                      ),
                      padding: EdgeInsets.all(
                        isMobile ? AppSpacing.md : AppSpacing.lg,
                      ),
                      backgroundColor: Colors.white,
                      showShadow: false,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.3),
                      ),
                      child: Padding(
                        padding: EdgeInsets.zero,
                        child: isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Row: Icon, Name, Actions
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.shield_outlined,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              role.roleName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'ID: ${role.roleId.substring(0, role.roleId.length > 12 ? 12 : role.roleId.length)}...',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      AppMenu(
                                        icon: Icons.more_vert,
                                        items: [
                                          AppMenuItem(
                                            value: 'edit',
                                            label: 'Edit',
                                            icon: Icons.edit,
                                            onTap: () => _showEditRoleDialog(role),
                                          ),
                                          AppMenuItem(
                                            value: 'delete',
                                            label: 'Delete',
                                            icon: Icons.delete,
                                            isDestructive: true,
                                            onTap: () => _showDeleteConfirmation(role),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  // Badges - Wrap on mobile
                                  Wrap(
                                    spacing: AppSpacing.xs,
                                    runSpacing: AppSpacing.xs,
                                    children: [
                                      // Permission Count Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.lock_outline,
                                              size: 14,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$permissionCount',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  // Left: Icon and Role Name
                                  Container(
                                    padding: EdgeInsets.all(
                                      isTablet ? 10 : 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.shield_outlined,
                                      color: AppColors.primary,
                                      size: isTablet ? 22 : 24,
                                    ),
                                  ),
                                  SizedBox(
                                    width: isTablet
                                        ? AppSpacing.sm
                                        : AppSpacing.md,
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          role.roleName,
                                          style: TextStyle(
                                            fontSize: isTablet ? 16 : 18,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Role ID: ${role.roleId}',
                                          style: TextStyle(
                                            fontSize: isTablet ? 11 : 12,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Middle: Permission count and dates
                                  if (screenWidth > 900)
                                    Row(
                                      children: [
                                        // Permission Count Badge
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isTablet
                                                ? AppSpacing.sm
                                                : AppSpacing.md,
                                            vertical: AppSpacing.xs,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.lock_outline,
                                                size: isTablet ? 14 : 16,
                                                color: AppColors.primary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$permissionCount Permissions',
                                                style: TextStyle(
                                                  fontSize: isTablet ? 11 : 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    // For smaller screens, show fewer badges
                                    Wrap(
                                      spacing: AppSpacing.xs,
                                      runSpacing: AppSpacing.xs,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.sm,
                                            vertical: AppSpacing.xs,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.lock_outline,
                                                size: 14,
                                                color: AppColors.primary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$permissionCount',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.sm,
                                            vertical: AppSpacing.xs,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: Colors.green,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Active',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.green.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                  // Right: Actions Menu
                                  AppMenu(
                                    icon: Icons.more_vert,
                                    items: [
                                      AppMenuItem(
                                        value: 'edit',
                                        label: 'Edit',
                                        icon: Icons.edit,
                                        onTap: () => _showEditRoleDialog(role),
                                      ),
                                      AppMenuItem(
                                        value: 'delete',
                                        label: 'Delete',
                                        icon: Icons.delete,
                                        isDestructive: true,
                                        onTap: () => _showDeleteConfirmation(role),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
