import 'package:cloud_firestore/cloud_firestore.dart';

enum ApprovalStatus { pending, approved, rejected }
enum ApprovalLevel { level1, level2, level3, finance }

class ExpenseApproval {
  const ExpenseApproval({
    required this.approverId,
    required this.approverName,
    required this.approverRole,
    required this.level,
    required this.status,
    this.comments,
    this.approvedAt,
    this.requiredAt,
  });

  final String approverId;
  final String approverName;
  final String approverRole; // e.g., 'Manager', 'Finance', 'Director'
  final ApprovalLevel level;
  final ApprovalStatus status;
  final String? comments;
  final DateTime? approvedAt;
  final DateTime? requiredAt; // When this approval is required

  factory ExpenseApproval.fromMap(Map<String, dynamic> data) {
    return ExpenseApproval(
      approverId: data['approverId'] as String? ?? '',
      approverName: data['approverName'] as String? ?? '',
      approverRole: data['approverRole'] as String? ?? '',
      level: _levelFrom(data['level']),
      status: _statusFrom(data['status']),
      comments: data['comments'] as String?,
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] is Timestamp)
              ? (data['approvedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['approvedAt']?.toString() ?? '')
          : null,
      requiredAt: data['requiredAt'] != null
          ? (data['requiredAt'] is Timestamp)
              ? (data['requiredAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['requiredAt']?.toString() ?? '')
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'approverId': approverId,
        'approverName': approverName,
        'approverRole': approverRole,
        'level': level.name,
        'status': status.name,
        if (comments != null) 'comments': comments,
        if (approvedAt != null) 'approvedAt': Timestamp.fromDate(approvedAt!),
        if (requiredAt != null) 'requiredAt': Timestamp.fromDate(requiredAt!),
      };

  ExpenseApproval copyWith({
    String? approverId,
    String? approverName,
    String? approverRole,
    ApprovalLevel? level,
    ApprovalStatus? status,
    String? comments,
    DateTime? approvedAt,
    DateTime? requiredAt,
  }) {
    return ExpenseApproval(
      approverId: approverId ?? this.approverId,
      approverName: approverName ?? this.approverName,
      approverRole: approverRole ?? this.approverRole,
      level: level ?? this.level,
      status: status ?? this.status,
      comments: comments ?? this.comments,
      approvedAt: approvedAt ?? this.approvedAt,
      requiredAt: requiredAt ?? this.requiredAt,
    );
  }
}

ApprovalStatus _statusFrom(dynamic raw) {
  final value = raw?.toString().toLowerCase() ?? 'pending';
  return ApprovalStatus.values.firstWhere(
    (s) => s.name.toLowerCase() == value,
    orElse: () => ApprovalStatus.pending,
  );
}

ApprovalLevel _levelFrom(dynamic raw) {
  final value = raw?.toString().toLowerCase() ?? 'level1';
  return ApprovalLevel.values.firstWhere(
    (l) => l.name.toLowerCase() == value,
    orElse: () => ApprovalLevel.level1,
  );
}

