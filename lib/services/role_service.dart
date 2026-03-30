import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/role_model.dart';

/// RoleService - handles role CRUD operations
class RoleService {
  RoleService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _collection = 'roles';

  /// Create a new role
  Future<String> createRole(RoleModel role) async {
    try {
      final now = DateTime.now();
      final docRef = _firestore.collection(_collection).doc();
      await docRef.set(
        role
            .copyWith(
              roleId: docRef.id,
              createdAt: now,
              updatedAt: now,
            )
            .toMap(),
      );
      debugPrint('Role created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating role: $e');
      rethrow;
    }
  }

  /// Update an existing role
  Future<void> updateRole(RoleModel role) async {
    try {
      await _firestore.collection(_collection).doc(role.roleId).update(
        role.copyWith(updatedAt: DateTime.now()).toMap(),
      );
      debugPrint('Role updated: ${role.roleId}');
    } catch (e) {
      debugPrint('Error updating role: $e');
      rethrow;
    }
  }

  /// Delete a role
  Future<void> deleteRole(String roleId) async {
    try {
      await _firestore.collection(_collection).doc(roleId).delete();
      debugPrint('Role deleted: $roleId');
    } catch (e) {
      debugPrint('Error deleting role: $e');
      rethrow;
    }
  }

  /// Get a role by ID
  Future<RoleModel?> getRoleById(String roleId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(roleId).get();
      if (!doc.exists) {
        return null;
      }
      return RoleModel.fromMap(doc.data()!, id: doc.id);
    } catch (e) {
      debugPrint('Error getting role: $e');
      return null;
    }
  }

  /// Stream all roles
  Stream<List<RoleModel>> streamAllRoles() {
    return _firestore
        .collection(_collection)
        .orderBy('roleName')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RoleModel.fromMap(doc.data(), id: doc.id))
          .toList();
    });
  }

  /// Get all roles (one-time fetch)
  Future<List<RoleModel>> getAllRoles() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('roleName')
          .get();
      return snapshot.docs
          .map((doc) => RoleModel.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting all roles: $e');
      return [];
    }
  }

  /// Get roleId by role name (case-insensitive)
  Future<String?> getRoleIdByName(String roleName) async {
    try {
      // Try exact match first
      final snapshot = await _firestore
          .collection(_collection)
          .where('roleName', isEqualTo: roleName)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
      
      // Try case-insensitive search by fetching all and filtering
      final allRoles = await getAllRoles();
      final matchingRole = allRoles.firstWhere(
        (r) => r.roleName.toLowerCase() == roleName.toLowerCase(),
        orElse: () => throw Exception('Role not found'),
      );
      return matchingRole.roleId;
    } catch (e) {
      debugPrint('Error getting roleId by name "$roleName": $e');
      return null;
    }
  }
}

