import '../models/task_model.dart';

class TaskTemplate {
  const TaskTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.priority,
    this.dueDateDays,
    this.defaultSubtasks = const [],
    this.requiresApproval = false,
    this.requiresLocation = false,
    this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final TaskPriority priority;
  final int? dueDateDays; // Days from creation to set as due date
  final List<String> defaultSubtasks;
  final bool requiresApproval;
  final bool requiresLocation;
  final DateTime? createdAt;

  TaskModel toTask({
    required String assignedTo,
    DateTime? dueDate,
  }) {
    return TaskModel(
      id: '',
      title: name,
      description: description,
      priority: priority,
      dueDate: dueDate ??
          (dueDateDays != null
              ? DateTime.now().add(Duration(days: dueDateDays!))
              : DateTime.now().add(const Duration(days: 7))),
      assignedTo: assignedTo,
      status: TaskStatus.pending,
      subTasks: defaultSubtasks
          .asMap()
          .entries
          .map((entry) => SubTask(
                id: 'sub-${entry.key}',
                label: entry.value,
                isDone: false,
              ))
          .toList(),
      approvalType:
          requiresApproval ? TaskApprovalType.single : TaskApprovalType.none,
    );
  }
}

