import 'dart:convert';

/// PermissionSet model - represents CRUD permissions for a resource
class PermissionSet {
  const PermissionSet({
    required this.create,
    required this.read,
    required this.update,
    required this.delete,
  });

  final bool create;
  final bool read;
  final bool update;
  final bool delete;

  factory PermissionSet.fromMap(Map<String, dynamic> data) {
    return PermissionSet(
      create: data['create'] as bool? ?? false,
      read: data['read'] as bool? ?? false,
      update: data['update'] as bool? ?? false,
      delete: data['delete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'create': create,
        'read': read,
        'update': update,
        'delete': delete,
      };

  PermissionSet copyWith({
    bool? create,
    bool? read,
    bool? update,
    bool? delete,
  }) {
    return PermissionSet(
      create: create ?? this.create,
      read: read ?? this.read,
      update: update ?? this.update,
      delete: delete ?? this.delete,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory PermissionSet.fromJson(String json) {
    return PermissionSet.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }

  // Helper to check if any permission is granted
  bool hasAnyPermission() => create || read || update || delete;

  // Helper to check if all permissions are granted
  bool hasAllPermissions() => create && read && update && delete;
}

