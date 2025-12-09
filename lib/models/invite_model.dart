import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

/// InviteModel - represents an invitation with role assignment
class InviteModel {
  const InviteModel({
    required this.inviteId,
    required this.email,
    required this.roleId,
    required this.token,
    required this.expiresAt,
    required this.used,
    this.createdAt,
    this.invitedBy,
    this.usedAt,
    this.usedBy,
  });

  final String inviteId;
  final String email;
  final String roleId;
  final String token;
  final DateTime expiresAt;
  final bool used;
  final DateTime? createdAt;
  final String? invitedBy;
  final DateTime? usedAt;
  final String? usedBy;

  factory InviteModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return InviteModel(
      inviteId: id ?? (data['inviteId'] as String? ?? ''),
      email: (data['email'] as String? ?? '').trim(),
      roleId: (data['roleId'] as String? ?? '').trim(),
      token: (data['token'] as String? ?? '').trim(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 7)),
      used: data['used'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      invitedBy: data['invitedBy'] as String?,
      usedAt: (data['usedAt'] as Timestamp?)?.toDate(),
      usedBy: data['usedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'inviteId': inviteId,
        'email': email,
        'roleId': roleId,
        'token': token,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'used': used,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
        if (invitedBy != null) 'invitedBy': invitedBy,
        if (usedAt != null) 'usedAt': Timestamp.fromDate(usedAt!),
        if (usedBy != null) 'usedBy': usedBy,
      };

  InviteModel copyWith({
    String? inviteId,
    String? email,
    String? roleId,
    String? token,
    DateTime? expiresAt,
    bool? used,
    DateTime? createdAt,
    String? invitedBy,
    DateTime? usedAt,
    String? usedBy,
  }) {
    return InviteModel(
      inviteId: inviteId ?? this.inviteId,
      email: email ?? this.email,
      roleId: roleId ?? this.roleId,
      token: token ?? this.token,
      expiresAt: expiresAt ?? this.expiresAt,
      used: used ?? this.used,
      createdAt: createdAt ?? this.createdAt,
      invitedBy: invitedBy ?? this.invitedBy,
      usedAt: usedAt ?? this.usedAt,
      usedBy: usedBy ?? this.usedBy,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory InviteModel.fromJson(String json) {
    return InviteModel.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }

  // Helper to check if invite is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  // Helper to check if invite is valid (not used and not expired)
  bool get isValid => !used && !isExpired;
}

