import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/user_model.dart';
import '../../models/role_model.dart';
import '../../services/role_service.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/rbac_utils.dart';
import '../../widgets/shadcn/shadcn_widgets.dart';
import '../widgets/add_user_dialog.dart';
import '../widgets/invite_user_dialog.dart';

class UsersView extends StatefulWidget {
  const UsersView({super.key});

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  final TextEditingController _searchController = TextEditingController();
  final RoleService _roleService = RoleService();
  
  String _statusFilter = 'All';
  String _roleFilter = 'All';
  String _sortOption = 'Name A-Z';
  
  List<RoleModel> _roles = [];
  bool _isLoadingRoles = true;

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
          _isLoadingRoles = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading roles: $e');
      if (mounted) {
        setState(() {
          _isLoadingRoles = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final filteredUsers = _filteredUsers(provider.users);
    final isMobile = ResponsiveUtils.isMobile(context);

    if (provider.isLoading && filteredUsers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: const Color(0xFFF5F6F8),
      child: Padding(
        padding: ResponsiveUtils.getPadding(context),
        child: isMobile 
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPeopleHeaderSection(context, provider, isMobile: true),
                const SizedBox(height: AppSpacing.lg),
                _buildPeopleSearchSection(isMobile: true),
                const SizedBox(height: AppSpacing.lg),
                _buildPeopleContent(context, provider, filteredUsers, isMobile: true),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPeopleHeaderSection(context, provider, isMobile: false),
                const SizedBox(height: AppSpacing.lg),
                _buildPeopleSearchSection(isMobile: false),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: _buildPeopleContent(context, provider, filteredUsers, isMobile: false),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildPeopleHeaderSection(BuildContext context, DashboardProvider provider, {required bool isMobile}) {
    if (isMobile) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildPeopleHeaderTexts(context)),
          const SizedBox(width: AppSpacing.md),
          FutureBuilder<bool>(
            future: RBACUtils.isAdmin(),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AppButton(
                    onPressed: () => _showInviteUserDialog(context),
                    variant: AppButtonVariant.primary,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.send, size: 18, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Invite User', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      );
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildPeopleHeaderTexts(context)),
        const SizedBox(width: AppSpacing.md),
        FutureBuilder<bool>(
          future: RBACUtils.isAdmin(),
          builder: (context, snapshot) {
            if (snapshot.data == true) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AppButton(
                  onPressed: () => _showInviteUserDialog(context),
                  variant: AppButtonVariant.primary,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.send, size: 18, color: Colors.white),
                      SizedBox(width: 6),
                      Text('Invite User', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildPeopleSearchSection({required bool isMobile}) {
    if (isMobile) {
      return Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: AppSearchInput(
              controller: _searchController,
              placeholder: 'Search by name or email...',
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: _isLoadingRoles
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : AppSelect<String>(
                          placeholder: 'All Roles',
                          value: _roleFilter,
                          options: [
                            const SelectOption<String>(value: 'All', label: 'All Roles'),
                            ..._roles.map((role) => SelectOption<String>(
                                  value: role.roleName,
                                  label: role.roleName,
                                )),
                          ],
                          selectedOptionBuilder: (context, value) {
                            return Text(value ?? 'All Roles');
                          },
                          onChanged: (value) {
                            setState(() => _roleFilter = value ?? 'All');
                          },
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: AppSelect<String>(
                    placeholder: 'All Status',
                    value: _statusFilter,
                    options: SelectOption.fromStringList([
                      'All',
                      'Active',
                      'On leave',
                      'Inactive',
                    ]),
                    selectedOptionBuilder: (context, value) {
                      final label = value == 'All' ? 'All Status' : value ?? 'All Status';
                      return Text(label);
                    },
                    onChanged: (value) {
                      setState(() => _statusFilter = value ?? 'All');
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: AppSelect<String>(
              placeholder: 'Sort',
              value: _sortOption,
              options: SelectOption.fromStringList([
                'Name A-Z',
                'Name Z-A',
                'Email A-Z',
                'Email Z-A',
                'Role A-Z',
                'Role Z-A',
              ]),
              selectedOptionBuilder: (context, value) {
                return Text(value ?? 'Sort');
              },
              onChanged: (value) {
                setState(() => _sortOption = value ?? 'Name A-Z');
              },
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: AppSearchInput(
                controller: _searchController,
                placeholder: 'Search by name or email...',
                onChanged: (query) {
                  setState(() {});
                },
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            width: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: _isLoadingRoles
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : AppSelect<String>(
                    placeholder: 'All Roles',
                    value: _roleFilter,
                    options: [
                      const SelectOption<String>(value: 'All', label: 'All Roles'),
                      ..._roles.map((role) => SelectOption<String>(
                            value: role.roleName,
                            label: role.roleName,
                          )),
                    ],
                    selectedOptionBuilder: (context, value) {
                      return Text(value ?? 'All Roles');
                    },
                    onChanged: (value) {
                      setState(() => _roleFilter = value ?? 'All');
                    },
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            width: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: AppSelect<String>(
              placeholder: 'All Status',
              value: _statusFilter,
              options: SelectOption.fromStringList([
                'All',
                'Active',
                'On leave',
                'Inactive',
              ]),
              selectedOptionBuilder: (context, value) {
                final label = _statusFilter == 'All' ? 'All Status' : _statusFilter;
                return Text(label);
              },
              onChanged: (value) {
                setState(() => _statusFilter = value ?? 'All');
              },
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            width: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: AppSelect<String>(
              placeholder: 'Sort',
              value: _sortOption,
              options: SelectOption.fromStringList([
                'Name A-Z',
                'Name Z-A',
                'Email A-Z',
                'Email Z-A',
                'Role A-Z',
                'Role Z-A',
              ]),
              selectedOptionBuilder: (context, value) {
                return Text(value ?? 'Sort');
              },
              onChanged: (value) {
                setState(() => _sortOption = value ?? 'Name A-Z');
              },
            ),
          ),
        ],
      );
    }
  }

  Widget _buildPeopleContent(BuildContext context, DashboardProvider provider, List<UserModel> filteredUsers, {required bool isMobile}) {
    if (provider.users.isEmpty && !provider.isLoading) {
      return _buildEmptyState(context, provider);
    }

    if (filteredUsers.isEmpty) {
      return _buildNoResultsState();
    }

    if (isMobile) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppSpacing.md),
          children: filteredUsers.map((user) {
            return _buildModernMobileUserCard(user, provider);
          }).toList(),
        ),
      );
    } else {
      return AppCard(
        backgroundColor: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.3),
          width: 1,
        ),
        showShadow: true,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _buildModernTableHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  return _buildModernTableRow(user, provider, index == filteredUsers.length - 1);
                },
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildEmptyState(BuildContext context, DashboardProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_alt_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'No employees yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add your first user to get started.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FutureBuilder<bool>(
              future: RBACUtils.isAdmin(),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: AppButton(
                      onPressed: () => _showInviteUserDialog(context),
                      variant: AppButtonVariant.primary,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.send, size: 18, color: Colors.white),
                          SizedBox(width: 6),
                          Text('Invite User', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl * 2),
        child: Text(
          'No employees match the current filters.',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  List<UserModel> _filteredUsers(List<UserModel> users) {
    final query = _searchController.text.toLowerCase().trim();
    
    // Filter users
    var filtered = users.where((user) {
      final matchesQuery = query.isEmpty ||
          user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
      final matchesStatus =
          _statusFilter == 'All' || user.status == _statusFilter;
      final matchesRole = _roleFilter == 'All' || 
          user.role.toLowerCase() == _roleFilter.toLowerCase();
      return matchesQuery && matchesStatus && matchesRole;
    }).toList();
    
    // Sort users
    filtered.sort((a, b) {
      switch (_sortOption) {
        case 'Name A-Z':
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 'Name Z-A':
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case 'Email A-Z':
          return a.email.toLowerCase().compareTo(b.email.toLowerCase());
        case 'Email Z-A':
          return b.email.toLowerCase().compareTo(a.email.toLowerCase());
        case 'Role A-Z':
          return a.role.toLowerCase().compareTo(b.role.toLowerCase());
        case 'Role Z-A':
          return b.role.toLowerCase().compareTo(a.role.toLowerCase());
        default:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
    });
    
    return filtered;
  }

  Widget _buildPeopleHeaderTexts(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'People',
          style: TextStyle(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage your team members',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildModernTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _ModernHeaderCell('Name'),
          ),
          Expanded(
            flex: 2,
            child: _ModernHeaderCell('Email'),
          ),
          Expanded(
            child: _ModernHeaderCell('Role'),
          ),
          Expanded(
            child: _ModernHeaderCell('Status'),
          ),
          SizedBox(
            width: 100,
            child: _ModernHeaderCell('Actions'),
          ),
        ],
      ),
    );
  }

  Widget _buildModernMobileUserCard(UserModel user, DashboardProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _ModernStatusBadge(status: user.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Role: ${user.role}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              FutureBuilder<bool>(
                future: RBACUtils.isAdmin(),
                builder: (context, snapshot) {
                  if (snapshot.data == true) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionButton(
                          icon: Icons.edit_outlined,
                          onPressed: () => _showAddUserDialog(context, provider, user),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _buildActionButton(
                          icon: Icons.delete_outline,
                          onPressed: () => _confirmDelete(context, provider, user),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernTableRow(UserModel user, DashboardProvider provider, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast 
                ? Colors.transparent 
                : AppColors.border.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primarySoft,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              user.email,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              user.role,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: _ModernStatusBadge(status: user.status),
          ),
          SizedBox(
            width: 100,
            child: FutureBuilder<bool>(
              future: RBACUtils.isAdmin(),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionButton(
                        icon: Icons.edit_outlined,
                        onPressed: () => _showAddUserDialog(context, provider, user),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _buildActionButton(
                        icon: Icons.delete_outline,
                        onPressed: () => _confirmDelete(context, provider, user),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18),
      color: AppColors.textMuted,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  void _showInviteUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const InviteUserDialog(),
    );
  }

  void _showAddUserDialog(
    BuildContext context,
    DashboardProvider provider, [
    UserModel? user,
  ]) {
    showDialog(
      context: context,
      builder: (context) => AddUserDialog(
        initialUser: user,
        onSave: (newUser, {String? password, String? roleId}) {
          if (user == null) {
            return provider.addUser(newUser, password: password, roleId: roleId);
          } else {
            return provider.updateUser(newUser);
          }
        },
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    DashboardProvider provider,
    UserModel user,
  ) {
    showDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Remove employee'),
        child: Text('Are you sure you want to remove ${user.name}?'),
        actions: [
          AppButton(
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          AppButton(
            variant: AppButtonVariant.destructive,
            onPressed: () async {
              Navigator.of(context).pop();
              await provider.deleteUser(user.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${user.name} removed'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _ModernHeaderCell extends StatelessWidget {
  const _ModernHeaderCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        fontSize: 12,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _ModernStatusBadge extends StatelessWidget {
  const _ModernStatusBadge({required this.status});

  final String status;

  Color get _backgroundColor {
    switch (status) {
      case 'Active':
        return const Color(0xFFD1FAE5);
      case 'On leave':
        return const Color(0xFFFEF3C7);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color get _textColor {
    switch (status) {
      case 'Active':
        return const Color(0xFF065F46);
      case 'On leave':
        return const Color(0xFF92400E);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _textColor,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }
}

