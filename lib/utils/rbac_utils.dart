import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/app_user.dart';
import '../models/role_model.dart';
import '../services/user_service.dart';
import '../services/role_service.dart';

class RBACUtils {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final UserService _userService = UserService();
  static final RoleService _roleService = RoleService();
  
  // Cache for current user model
  static UserModel? _cachedUserModel;
  static AppUser? _cachedAppUser;
  static RoleModel? _cachedRole;
  static DateTime? _cacheTimestamp;
  static const _cacheDuration = Duration(minutes: 5);
  
  // Get current user's UserModel (legacy)
  static Future<UserModel?> getCurrentUserModel() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('RBAC: No current user found');
        return null;
      }
      
      print('RBAC: Getting user model for UID: ${user.uid}, Email: ${user.email}');
      
      // Return cached if still valid
      if (_cachedUserModel != null && 
          _cacheTimestamp != null &&
          DateTime.now().difference(_cacheTimestamp!) < _cacheDuration &&
          _cachedUserModel!.id == user.uid) {
        print('RBAC: Using cached user model');
        return _cachedUserModel;
      }
      
      print('RBAC: Fetching user document from Firestore...');
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        print('RBAC: User document does not exist in Firestore');
        return null;
      }
      
      final data = userDoc.data();
      if (data == null) {
        print('RBAC: User document data is null');
        return null;
      }
      
      print('RBAC: User document data: $data');
      
      _cachedUserModel = UserModel.fromMap(data, id: user.uid);
      _cacheTimestamp = DateTime.now();
      
      print('RBAC: Parsed user model - role: "${_cachedUserModel!.role}"');
      return _cachedUserModel;
    } catch (e, stackTrace) {
      print('RBAC: Error getting current user model: $e');
      print('RBAC: Stack trace: $stackTrace');
      return null;
    }
  }

  // Get current user's AppUser (new RBAC system)
  static Future<AppUser?> getCurrentAppUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      // Return cached if still valid
      if (_cachedAppUser != null && 
          _cacheTimestamp != null &&
          DateTime.now().difference(_cacheTimestamp!) < _cacheDuration &&
          _cachedAppUser!.uid == user.uid) {
        return _cachedAppUser;
      }

      _cachedAppUser = await _userService.getUserByUid(user.uid);
      if (_cachedAppUser != null) {
        _cacheTimestamp = DateTime.now();
      }
      return _cachedAppUser;
    } catch (e) {
      print('RBAC: Error getting AppUser: $e');
      return null;
    }
  }

  // Get current user's role with permissions
  static Future<RoleModel?> getCurrentUserRole() async {
    try {
      final appUser = await getCurrentAppUser();
      if (appUser == null || appUser.roleId.isEmpty) {
        return null;
      }

      // Return cached if still valid
      if (_cachedRole != null && 
          _cacheTimestamp != null &&
          DateTime.now().difference(_cacheTimestamp!) < _cacheDuration &&
          _cachedRole!.roleId == appUser.roleId) {
        return _cachedRole;
      }

      _cachedRole = await _roleService.getRoleById(appUser.roleId);
      if (_cachedRole != null) {
        _cacheTimestamp = DateTime.now();
      }
      return _cachedRole;
    } catch (e) {
      print('RBAC: Error getting role: $e');
      return null;
    }
  }
  
  // Check if user is Super Admin
  static Future<bool> isSuperAdmin() async {
    try {
      // First check AppUser system
      final appUser = await getCurrentAppUser();
      if (appUser != null) {
        final role = await getCurrentUserRole();
        if (role != null) {
          // Check if role name is Super Admin
          final roleName = role.roleName.toLowerCase();
          if (roleName.contains('super') && roleName.contains('admin')) {
            return true;
          }
        }
      }

      // Fallback to legacy UserModel system
      final userModel = await getCurrentUserModel();
      if (userModel == null) {
        print('RBAC: User model is null');
        return false;
      }
      
      final role = userModel.role.trim();
      
      // Check role field for Super Admin
      final isSuperAdmin = role == 'Super Admin' || 
                          role.toLowerCase() == 'super admin' ||
                          role == 'SuperAdmin' ||
                          role.toLowerCase() == 'superadmin';
      
      print('RBAC: Checking user ${userModel.email} (${userModel.id})');
      print('RBAC: role from model: "$role"');
      print('RBAC: isSuperAdmin result: $isSuperAdmin');
      
      return isSuperAdmin;
    } catch (e, stackTrace) {
      print('RBAC: Error checking Super Admin status: $e');
      print('RBAC: Stack trace: $stackTrace');
      return false;
    }
  }
  
  // Check if user is Admin or Super Admin
  static Future<bool> isAdmin() async {
    final appUser = await getCurrentAppUser();
    if (appUser != null) {
      final role = await getCurrentUserRole();
      if (role != null) {
        final roleName = role.roleName.toLowerCase();
        return roleName.contains('admin');
      }
    }

    final userModel = await getCurrentUserModel();
    final role = userModel?.role ?? 'Employee';
    return role == 'Admin' || role == 'Super Admin' || role.toLowerCase() == 'admin' || role.toLowerCase() == 'super admin';
  }

  // Check if user has read permission for a resource
  static Future<bool> canRead(String resource) async {
    // Admin users have full access to all resources
    if (await isAdmin()) {
      return true;
    }

    final role = await getCurrentUserRole();
    if (role == null) return false;

    switch (resource.toLowerCase()) {
      case 'team':
        return role.permissions.teamControl.read;
      case 'chat':
        return role.permissions.chatControl.read;
      case 'task':
      case 'tasks':
        return role.permissions.taskControl.read;
      case 'expense':
      case 'expenses':
        return role.permissions.expenseControl.read;
      default:
        return false;
    }
  }

  // Check if user has create permission for a resource
  static Future<bool> canCreate(String resource) async {
    // Admin users have full access to all resources
    if (await isAdmin()) {
      return true;
    }

    final role = await getCurrentUserRole();
    if (role == null) return false;

    switch (resource.toLowerCase()) {
      case 'team':
        return role.permissions.teamControl.create;
      case 'chat':
        return role.permissions.chatControl.create;
      case 'task':
      case 'tasks':
        return role.permissions.taskControl.create;
      case 'expense':
      case 'expenses':
        return role.permissions.expenseControl.create;
      default:
        return false;
    }
  }

  // Check if user has update permission for a resource
  static Future<bool> canUpdate(String resource) async {
    // Admin users have full access to all resources
    if (await isAdmin()) {
      return true;
    }

    final role = await getCurrentUserRole();
    if (role == null) return false;

    switch (resource.toLowerCase()) {
      case 'team':
        return role.permissions.teamControl.update;
      case 'chat':
        return role.permissions.chatControl.update;
      case 'task':
      case 'tasks':
        return role.permissions.taskControl.update;
      case 'expense':
      case 'expenses':
        return role.permissions.expenseControl.update;
      default:
        return false;
    }
  }

  // Check if user has delete permission for a resource
  static Future<bool> canDelete(String resource) async {
    // Admin users have full access to all resources
    if (await isAdmin()) {
      return true;
    }

    final role = await getCurrentUserRole();
    if (role == null) return false;

    switch (resource.toLowerCase()) {
      case 'team':
        return role.permissions.teamControl.delete;
      case 'chat':
        return role.permissions.chatControl.delete;
      case 'task':
      case 'tasks':
        return role.permissions.taskControl.delete;
      case 'expense':
      case 'expenses':
        return role.permissions.expenseControl.delete;
      default:
        return false;
    }
  }
  
  // Clear cache (call this on logout or when user data changes)
  static void clearCache() {
    _cachedUserModel = null;
    _cachedAppUser = null;
    _cachedRole = null;
    _cacheTimestamp = null;
  }
}
