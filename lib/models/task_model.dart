import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'task_attachment.dart';
import 'task_location.dart';
import 'task_approval.dart';

enum TaskPriority { low, medium, high }

enum TaskStatus { pending, inProgress, completed }

enum TaskApprovalType { none, single, multiple }

class SubTask {
  const SubTask({
    required this.id,
    required this.label,
    required this.isDone,
  });

  final String id;
  final String label;
  final bool isDone;

  factory SubTask.fromMap(Map<String, dynamic> data) {
    return SubTask(
      id: data['id'] as String? ?? '',
      label: data['label'] as String? ?? '',
      isDone: data['isDone'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'isDone': isDone,
      };
}

class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.assignedTo,
    required this.status,
    required this.subTasks,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.attachments = const [],
    this.location,
    this.approvalType = TaskApprovalType.none,
    this.approvals = const [],
    this.templateId,
    this.hasLocation = false,
    this.formId,
    this.formDefinition,
    this.formValues,
  });

  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final DateTime dueDate;
  final String assignedTo;
  final TaskStatus status;
  final List<SubTask> subTasks;

  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<TaskAttachment> attachments;
  final TaskLocation? location;
  final TaskApprovalType approvalType;
  final List<TaskApproval> approvals;
  final String? templateId;
  final bool hasLocation;
  final String? formId;
  final Map<String, dynamic>? formDefinition;
  final Map<String, dynamic>? formValues;

  factory TaskModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? <String, dynamic>{};
    return TaskModel.fromMap(data, id: snap.id);
  }

  factory TaskModel.fromMap(Map<String, dynamic> data, {String? id}) {
    final title = data['title'] as String? ?? '';
    if (title.isEmpty && id != null && id.isNotEmpty) {
      debugPrint('Warning: Task $id has no title field');
    }

    return TaskModel(
      id: id ?? data['id'] as String? ?? '',
      title: title,
      description: data['description'] as String? ?? '',
      priority: _priorityFrom(data['priority']),
      dueDate: (data['dueDate'] is Timestamp)
          ? (data['dueDate'] as Timestamp).toDate()
          : DateTime.tryParse(data['dueDate']?.toString() ?? '') ??
              DateTime.now(),
      assignedTo: data['assignedTo'] as String? ?? '',
      status: _statusFrom(data['status']),
      subTasks: ((data['subTasks'] as List<dynamic>?) ?? [])
          .map((sub) => SubTask.fromMap(Map<String, dynamic>.from(sub)))
          .toList(),
      createdBy: data['createdBy'] as String?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp)
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['createdAt']?.toString() ?? '')
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp)
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['updatedAt']?.toString() ?? '')
          : null,
      attachments: ((data['attachments'] as List<dynamic>?) ?? [])
          .map((att) => TaskAttachment.fromMap(Map<String, dynamic>.from(att)))
          .toList(),
      location: data['location'] != null
          ? TaskLocation.fromMap(Map<String, dynamic>.from(data['location']))
          : null,
      approvalType: _approvalTypeFrom(data['approvalType']),
      approvals: ((data['approvals'] as List<dynamic>?) ?? [])
          .map((app) => TaskApproval.fromMap(Map<String, dynamic>.from(app)))
          .toList(),
      templateId: data['templateId'] as String?,
      hasLocation: data['hasLocation'] as bool? ?? false,
      formId: data['formId'] as String?,
      formDefinition: data['formDefinition'] != null
          ? Map<String, dynamic>.from(
              data['formDefinition'] as Map<String, dynamic>)
          : null,
      formValues: data['formValues'] != null
          ? Map<String, dynamic>.from(
              data['formValues'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'priority': priority.name,
        'dueDate': Timestamp.fromDate(dueDate),
        'assignedTo': assignedTo,
        'status': status.name,
        'subTasks': subTasks.map((sub) => sub.toMap()).toList(),
        if (createdBy != null) 'createdBy': createdBy,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
        if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
        'attachments': attachments.map((att) => att.toMap()).toList(),
        if (location != null && !location!.isEmpty) 'location': location!.toMap(),
        'approvalType': approvalType.name,
        'approvals': approvals.map((app) => app.toMap()).toList(),
        if (templateId != null) 'templateId': templateId,
        'hasLocation': hasLocation,
        if (formId != null) 'formId': formId,
        if (formDefinition != null) 'formDefinition': formDefinition,
        if (formValues != null) 'formValues': formValues,
      };

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? dueDate,
    String? assignedTo,
    TaskStatus? status,
    List<SubTask>? subTasks,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TaskAttachment>? attachments,
    TaskLocation? location,
    TaskApprovalType? approvalType,
    List<TaskApproval>? approvals,
    String? templateId,
    bool? hasLocation,
    String? formId,
    Map<String, dynamic>? formDefinition,
    Map<String, dynamic>? formValues,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      assignedTo: assignedTo ?? this.assignedTo,
      status: status ?? this.status,
      subTasks: subTasks ?? this.subTasks,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachments: attachments ?? this.attachments,
      location: location ?? this.location,
      approvalType: approvalType ?? this.approvalType,
      approvals: approvals ?? this.approvals,
      templateId: templateId ?? this.templateId,
      hasLocation: hasLocation ?? this.hasLocation,
      formId: formId ?? this.formId,
      formDefinition: formDefinition ?? this.formDefinition,
      formValues: formValues ?? this.formValues,
    );
  }
}

TaskPriority _priorityFrom(dynamic raw) {
  final value = raw?.toString().toLowerCase() ?? 'high';
  return TaskPriority.values.firstWhere(
    (p) => p.name.toLowerCase() == value,
    orElse: () => TaskPriority.high,
  );
}

TaskStatus _statusFrom(dynamic raw) {
  final value = raw?.toString().replaceAll(' ', '').toLowerCase() ?? 'pending';
  return TaskStatus.values.firstWhere(
    (s) => s.name.toLowerCase() == value,
    orElse: () => TaskStatus.pending,
  );
}

TaskApprovalType _approvalTypeFrom(dynamic raw) {
  final value = raw?.toString().toLowerCase() ?? 'none';
  return TaskApprovalType.values.firstWhere(
    (t) => t.name.toLowerCase() == value,
    orElse: () => TaskApprovalType.none,
  );
}

