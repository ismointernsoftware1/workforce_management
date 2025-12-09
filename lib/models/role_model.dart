import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'permissions_model.dart';

/// RoleModel - represents a role with permissions
class RoleModel {
  const RoleModel({
    required this.roleId,
    required this.roleName,
    required this.permissions,
    this.createdAt,
    this.updatedAt,
  });

  final String roleId;
  final String roleName;
  final PermissionsModel permissions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory RoleModel.fromMap(Map<String, dynamic> data, {String? id}) {
    DateTime? parseTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return RoleModel(
      roleId: id ?? (data['roleId'] as String? ?? ''),
      roleName: (data['roleName'] as String? ?? '').trim(),
      permissions: PermissionsModel.fromMap(
        (data['permissions'] as Map<String, dynamic>?) ?? {},
      ),
      createdAt: parseTimestamp(data['createdAt']),
      updatedAt: parseTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'roleId': roleId,
        'roleName': roleName,
        'permissions': permissions.toMap(),
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
        if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      };

  RoleModel copyWith({
    String? roleId,
    String? roleName,
    PermissionsModel? permissions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoleModel(
      roleId: roleId ?? this.roleId,
      roleName: roleName ?? this.roleName,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory RoleModel.fromJson(String json) {
    return RoleModel.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }
}

