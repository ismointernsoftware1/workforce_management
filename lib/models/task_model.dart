import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority { low, medium, high }

enum TaskStatus { pending, inProgress, completed }

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
  });

  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final DateTime dueDate;
  final String assignedTo;
  final TaskStatus status;
  final List<SubTask> subTasks;

  factory TaskModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? <String, dynamic>{};
    return TaskModel.fromMap(data, id: snap.id);
  }

  factory TaskModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return TaskModel(
      id: id ?? data['id'] as String? ?? '',
      title: data['title'] as String? ?? '',
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

