import '../models/task_model.dart';
import '../services/firebase_service.dart';

class TaskController {
  const TaskController(this._service);

  final FirebaseService _service;

  Future<List<TaskModel>> fetchTasks() => _service.fetchTasks();

  Future<void> updateStatus(String taskId, TaskStatus status) =>
      _service.updateTaskStatus(taskId, status);
}

