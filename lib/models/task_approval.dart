import 'package:cloud_firestore/cloud_firestore.dart';

enum ApprovalStatus { pending, approved, rejected }

class TaskApproval {
  const TaskApproval({
    required this.approverId,
    required this.approverName,
    required this.status,
    this.comments,
    this.approvedAt,
  });

  final String approverId;
  final String approverName;
  final ApprovalStatus status;
  final String? comments;
  final DateTime? approvedAt;

  factory TaskApproval.fromMap(Map<String, dynamic> data) {
    return TaskApproval(
      approverId: data['approverId'] as String? ?? '',
      approverName: data['approverName'] as String? ?? '',
      status: _approvalStatusFrom(data['status']),
      comments: data['comments'] as String?,
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] is Timestamp)
              ? (data['approvedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['approvedAt']?.toString() ?? '')
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'approverId': approverId,
        'approverName': approverName,
        'status': status.name,
        if (comments != null) 'comments': comments,
        if (approvedAt != null) 'approvedAt': Timestamp.fromDate(approvedAt!),
      };

  TaskApproval copyWith({
    String? approverId,
    String? approverName,
    ApprovalStatus? status,
    String? comments,
    DateTime? approvedAt,
  }) {
    return TaskApproval(
      approverId: approverId ?? this.approverId,
      approverName: approverName ?? this.approverName,
      status: status ?? this.status,
      comments: comments ?? this.comments,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }
}

ApprovalStatus _approvalStatusFrom(dynamic raw) {
  final value = raw?.toString().toLowerCase() ?? 'pending';
  return ApprovalStatus.values.firstWhere(
    (s) => s.name.toLowerCase() == value,
    orElse: () => ApprovalStatus.pending,
  );
}

