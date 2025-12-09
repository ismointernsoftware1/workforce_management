import 'dart:convert';

/// AppUser model - represents a user with role assignment
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.roleId,
  });

  final String uid;
  final String email;
  final String roleId;

  factory AppUser.fromMap(Map<String, dynamic> data, {String? id}) {
    return AppUser(
      uid: id ?? (data['uid'] as String? ?? ''),
      email: (data['email'] as String? ?? '').trim(),
      roleId: (data['roleId'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'roleId': roleId,
      };

  AppUser copyWith({
    String? uid,
    String? email,
    String? roleId,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      roleId: roleId ?? this.roleId,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AppUser.fromJson(String json) {
    return AppUser.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }
}

