import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';

/// UserService - handles user operations with role assignment
class UserService {
  UserService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _collection = 'app_users';

  /// Create a new AppUser
  Future<void> createAppUser(AppUser user) async {
    try {
      await _firestore.collection(_collection).doc(user.uid).set(user.toMap());
      debugPrint('AppUser created: ${user.uid}');
    } catch (e) {
      debugPrint('Error creating AppUser: $e');
      rethrow;
    }
  }

  /// Get user by UID
  Future<AppUser?> getUserByUid(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      if (!doc.exists) {
        return null;
      }
      return AppUser.fromMap(doc.data()!, id: doc.id);
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  /// Update user's role
  Future<void> updateUserRole(String uid, String roleId) async {
    try {
      await _firestore.collection(_collection).doc(uid).update({
        'roleId': roleId,
      });
      debugPrint('User role updated: $uid -> $roleId');
    } catch (e) {
      debugPrint('Error updating user role: $e');
      rethrow;
    }
  }

  /// Stream user by UID
  Stream<AppUser?> streamUserByUid(String uid) {
    return _firestore
        .collection(_collection)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return null;
      }
      return AppUser.fromMap(doc.data()!, id: doc.id);
    });
  }

  /// Get all users
  Future<List<AppUser>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];
    }
  }
}

