import 'package:flutter/material.dart';
import '../utils/rbac_utils.dart';

/// Widget that conditionally shows child based on permission
class PermissionWrapper extends StatelessWidget {
  const PermissionWrapper({
    super.key,
    required this.permission,
    required this.resource,
    required this.child,
    this.fallback,
  });

  /// Permission type: 'read', 'create', 'update', 'delete'
  final String permission;
  
  /// Resource name: 'team', 'chat', 'tasks', 'expenses'
  final String resource;
  
  /// Widget to show if permission is granted
  final Widget child;
  
  /// Widget to show if permission is denied (optional, defaults to SizedBox.shrink)
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkPermission(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink(); // Hide while checking
        }
        
        if (snapshot.data == true) {
          return child;
        }
        
        return fallback ?? const SizedBox.shrink();
      },
    );
  }

  Future<bool> _checkPermission() async {
    switch (permission.toLowerCase()) {
      case 'read':
        return await RBACUtils.canRead(resource);
      case 'create':
        return await RBACUtils.canCreate(resource);
      case 'update':
        return await RBACUtils.canUpdate(resource);
      case 'delete':
        return await RBACUtils.canDelete(resource);
      default:
        return false;
    }
  }
}

/// Helper widget for checking multiple permissions (AND logic)
class MultiPermissionWrapper extends StatelessWidget {
  const MultiPermissionWrapper({
    super.key,
    required this.permissions,
    required this.resource,
    required this.child,
    this.fallback,
  });

  /// List of permissions to check (all must be true)
  final List<String> permissions;
  final String resource;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAllPermissions(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        if (snapshot.data == true) {
          return child;
        }
        
        return fallback ?? const SizedBox.shrink();
      },
    );
  }

  Future<bool> _checkAllPermissions() async {
    for (final permission in permissions) {
      bool hasPermission = false;
      switch (permission.toLowerCase()) {
        case 'read':
          hasPermission = await RBACUtils.canRead(resource);
          break;
        case 'create':
          hasPermission = await RBACUtils.canCreate(resource);
          break;
        case 'update':
          hasPermission = await RBACUtils.canUpdate(resource);
          break;
        case 'delete':
          hasPermission = await RBACUtils.canDelete(resource);
          break;
      }
      if (!hasPermission) return false;
    }
    return true;
  }
}

