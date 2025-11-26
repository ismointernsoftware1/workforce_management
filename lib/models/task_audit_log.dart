import 'package:cloud_firestore/cloud_firestore.dart';

enum AuditLogAction {
  created,
  updated,
  deleted,
  statusChanged,
  assigned,
  priorityChanged,
  dueDateChanged,
  attachmentAdded,
  attachmentRemoved,
  approvalRequested,
  approved,
  rejected,
  commentAdded,
}

class TaskAuditLog {
  const TaskAuditLog({
    required this.id,
    required this.taskId,
    required this.action,
    required this.actionBy,
    required this.actionByName,
    required this.timestamp,
    this.oldValue,
    this.newValue,
    this.description,
  });

  final String id;
  final String taskId;
  final AuditLogAction action;
  final String actionBy; // user ID
  final String actionByName;
  final DateTime timestamp;
  final String? oldValue;
  final String? newValue;
  final String? description;

  factory TaskAuditLog.fromMap(Map<String, dynamic> data, {String? id}) {
    return TaskAuditLog(
      id: id ?? data['id'] as String? ?? '',
      taskId: data['taskId'] as String? ?? '',
      action: _actionFrom(data['action']),
      actionBy: data['actionBy'] as String? ?? '',
      actionByName: data['actionByName'] as String? ?? '',
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.tryParse(data['timestamp']?.toString() ?? '') ??
              DateTime.now(),
      oldValue: data['oldValue'] as String?,
      newValue: data['newValue'] as String?,
      description: data['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'taskId': taskId,
        'action': action.name,
        'actionBy': actionBy,
        'actionByName': actionByName,
        'timestamp': Timestamp.fromDate(timestamp),
        if (oldValue != null) 'oldValue': oldValue,
        if (newValue != null) 'newValue': newValue,
        if (description != null) 'description': description,
      };
}

AuditLogAction _actionFrom(dynamic raw) {
  final value = raw?.toString().toLowerCase() ?? 'updated';
  return AuditLogAction.values.firstWhere(
    (a) => a.name.toLowerCase() == value,
    orElse: () => AuditLogAction.updated,
  );
}

