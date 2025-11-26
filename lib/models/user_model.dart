import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.role,
    required this.department,
    required this.email,
    required this.status,
    required this.joinDate,
    this.manager,
    this.team,
    this.accountType = 'Member',
    this.userStatus,
  });

  final String id;
  final String name;
  final String role;
  final String department;
  final String email;
  final String status; // Active, On leave, etc.
  final DateTime joinDate;
  final String? manager;
  final String? team;
  final String accountType;
  final String? userStatus;

  factory UserModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return UserModel(
      id: id ?? (data['id'] as String? ?? ''),
      name: data['name'] as String? ?? '',
      role: data['role'] as String? ?? '',
      department: data['department'] as String? ?? '',
      email: data['email'] as String? ?? '',
      status: data['status'] as String? ?? 'Active',
      joinDate:
          (data['joinDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      manager: data['manager'] as String?,
      team: data['team'] as String?,
      accountType: data['accountType'] as String? ?? 'Member',
      userStatus: data['userStatus'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'role': role,
        'department': department,
        'email': email,
        'status': status,
        'joinDate': Timestamp.fromDate(joinDate),
        'manager': manager,
        'team': team,
        'accountType': accountType,
        'userStatus': userStatus,
      };

  UserModel copyWith({
    String? id,
    String? name,
    String? role,
    String? department,
    String? email,
    String? status,
    DateTime? joinDate,
    String? manager,
    String? team,
    String? accountType,
    String? userStatus,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      department: department ?? this.department,
      email: email ?? this.email,
      status: status ?? this.status,
      joinDate: joinDate ?? this.joinDate,
      manager: manager ?? this.manager,
      team: team ?? this.team,
      accountType: accountType ?? this.accountType,
      userStatus: userStatus ?? this.userStatus,
    );
  }
}

