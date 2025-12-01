import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../providers/dashboard_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/rbac_utils.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
    this.isSuperAdmin,
  });

  final DashboardTab activeTab;
  final ValueChanged<DashboardTab> onTabChanged;
  final bool? isSuperAdmin;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final sidebarWidth = isMobile ? 280.0 : 220.0;
    
    return Container(
      width: sidebarWidth,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        border: Border(
          right: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SidebarHeader(onTabChanged: onTabChanged),
            const SizedBox(height: AppSpacing.xl),
            Expanded(
              child: Builder(
                builder: (context) {
                  // Use provided isSuperAdmin value or show loading
                  if (isSuperAdmin == null) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }
                  
                  // Filter tabs based on user role
                  final availableTabs = DashboardTab.values.where((tab) {
                    if (isSuperAdmin == true) {
                      // Super Admin: Show ONLY Form Builder
                      return tab == DashboardTab.formBuilder;
                    } else {
                      // Non-Super Admin: Show all tabs EXCEPT Form Builder
                      return tab != DashboardTab.formBuilder;
                    }
                  }).toList();
                  
                  // If no tabs available, show message
                  if (availableTabs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          'No tabs available',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }
                  
                  return SingleChildScrollView(
                    child: Column(
                      children: availableTabs.map(
                        (tab) => _SidebarItem(
                          label: _labelFor(tab),
                          icon: _iconFor(tab),
                          isActive: activeTab == tab,
                          onTap: () => onTabChanged(tab),
                        ),
                      ).toList(),
                    ),
                  );
                },
              ),
            ),
            _CurrentUserTile(),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(DashboardTab tab) {
    switch (tab) {
      case DashboardTab.tasks:
        return Icons.dashboard_customize_rounded;
      case DashboardTab.team:
        return Icons.people_alt_rounded;
      case DashboardTab.chat:
        return Icons.chat_bubble_rounded;
      case DashboardTab.expenses:
        return Icons.receipt_long;
      case DashboardTab.formBuilder:
        return Icons.view_quilt_rounded;
    }
  }

  static String _labelFor(DashboardTab tab) {
    switch (tab) {
      case DashboardTab.tasks:
        return 'Tasks';
      case DashboardTab.team:
        return 'Team';
      case DashboardTab.chat:
        return 'Chat';
      case DashboardTab.expenses:
        return 'Expenses';
      case DashboardTab.formBuilder:
        return 'Form Builder';
    }
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.onTabChanged});

  final ValueChanged<DashboardTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTabChanged(DashboardTab.tasks),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.work_outline_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workforce',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Management',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Material(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? AppColors.primary : Colors.white.withValues(alpha: 0.7),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentUserTile extends StatelessWidget {
  const _CurrentUserTile();

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        // Clear RBAC cache before logout
        RBACUtils.clearCache();
        
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.signOut();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getInitials(String? name, String? email) {
    if (name != null && name.isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    if (email != null && email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const SizedBox.shrink();
    }

    final displayName = user.displayName ?? user.email?.split('@')[0] ?? 'User';
    final email = user.email ?? '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: Text(
              _getInitials(user.displayName, user.email),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  email.isNotEmpty ? email : 'User',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 18),
            color: AppColors.textMuted,
            tooltip: 'Sign Out',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }
}

