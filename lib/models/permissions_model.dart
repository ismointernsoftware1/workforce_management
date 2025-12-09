import 'dart:convert';
import 'permission_set.dart';

/// PermissionsModel - contains PermissionSet for each resource type
class PermissionsModel {
  const PermissionsModel({
    required this.teamControl,
    required this.chatControl,
    required this.taskControl,
    required this.expenseControl,
  });

  final PermissionSet teamControl;
  final PermissionSet chatControl;
  final PermissionSet taskControl;
  final PermissionSet expenseControl;

  factory PermissionsModel.fromMap(Map<String, dynamic> data) {
    return PermissionsModel(
      teamControl: PermissionSet.fromMap(
        (data['teamControl'] as Map<String, dynamic>?) ?? {},
      ),
      chatControl: PermissionSet.fromMap(
        (data['chatControl'] as Map<String, dynamic>?) ?? {},
      ),
      taskControl: PermissionSet.fromMap(
        (data['taskControl'] as Map<String, dynamic>?) ?? {},
      ),
      expenseControl: PermissionSet.fromMap(
        (data['expenseControl'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'teamControl': teamControl.toMap(),
        'chatControl': chatControl.toMap(),
        'taskControl': taskControl.toMap(),
        'expenseControl': expenseControl.toMap(),
      };

  PermissionsModel copyWith({
    PermissionSet? teamControl,
    PermissionSet? chatControl,
    PermissionSet? taskControl,
    PermissionSet? expenseControl,
  }) {
    return PermissionsModel(
      teamControl: teamControl ?? this.teamControl,
      chatControl: chatControl ?? this.chatControl,
      taskControl: taskControl ?? this.taskControl,
      expenseControl: expenseControl ?? this.expenseControl,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory PermissionsModel.fromJson(String json) {
    return PermissionsModel.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }

  // Helper to check if user has any permission across all resources
  bool hasAnyPermission() =>
      teamControl.hasAnyPermission() ||
      chatControl.hasAnyPermission() ||
      taskControl.hasAnyPermission() ||
      expenseControl.hasAnyPermission();
}

