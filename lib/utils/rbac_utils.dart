import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class RBACUtils {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Cache for current user model
  static UserModel? _cachedUserModel;
  static DateTime? _cacheTimestamp;
  static const _cacheDuration = Duration(minutes: 5);
  
  // Get current user's UserModel
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
      print('RBAC: accountType field value: ${data['accountType']}');
      
      _cachedUserModel = UserModel.fromMap(data, id: user.uid);
      _cacheTimestamp = DateTime.now();
      
      print('RBAC: Parsed user model - accountType: "${_cachedUserModel!.accountType}"');
      return _cachedUserModel;
    } catch (e, stackTrace) {
      print('RBAC: Error getting current user model: $e');
      print('RBAC: Stack trace: $stackTrace');
      return null;
    }
  }
  
  // Check if user is Super Admin
  static Future<bool> isSuperAdmin() async {
    try {
      final userModel = await getCurrentUserModel();
      if (userModel == null) {
        print('RBAC: User model is null');
        return false;
      }
      
      final accountType = userModel.accountType.trim();
      final role = userModel.role.trim();
      
      // Check both accountType and role fields
      // Some users might have Super Admin in role field instead of accountType
      final isSuperAdminByAccountType = accountType == 'Super Admin' || 
                                        accountType.toLowerCase() == 'super admin' ||
                                        accountType == 'SuperAdmin' ||
                                        accountType.toLowerCase() == 'superadmin';
      
      final isSuperAdminByRole = role == 'Super Admin' || 
                                 role.toLowerCase() == 'super admin' ||
                                 role == 'SuperAdmin' ||
                                 role.toLowerCase() == 'superadmin';
      
      final isSuperAdmin = isSuperAdminByAccountType || isSuperAdminByRole;
      
      print('RBAC: Checking user ${userModel.email} (${userModel.id})');
      print('RBAC: accountType from model: "$accountType"');
      print('RBAC: role from model: "$role"');
      print('RBAC: isSuperAdmin by accountType: $isSuperAdminByAccountType');
      print('RBAC: isSuperAdmin by role: $isSuperAdminByRole');
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
    final userModel = await getCurrentUserModel();
    final accountType = userModel?.accountType ?? 'Member';
    return accountType == 'Admin' || accountType == 'Super Admin';
  }
  
  // Clear cache (call this on logout or when user data changes)
  static void clearCache() {
    _cachedUserModel = null;
    _cacheTimestamp = null;
  }
}

