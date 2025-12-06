import 'dart:async';
import '../models/task_model.dart';
import '../services/firebase_service.dart';

class TaskController {
  const TaskController(this._service);

  final FirebaseService _service;

  Future<List<TaskModel>> fetchTasks() => _service.fetchTasks();

  /// Real-time stream of tasks from Firestore
  Stream<List<TaskModel>> fetchTasksStream() => _service.fetchTasksStream();

  Future<String> createTask(TaskModel task) => _service.addTask(task);

  Future<void> updateTask(TaskModel task) => _service.updateTask(task, actionBy: null, actionByName: null);
  
  Future<void> updateTaskWithAudit(TaskModel task, {String? actionBy, String? actionByName}) => 
      _service.updateTask(task, actionBy: actionBy, actionByName: actionByName);

  Future<void> deleteTask(String taskId) => _service.deleteTask(taskId);

  Future<void> updateStatus(String taskId, TaskStatus status) =>
      _service.updateTaskStatus(taskId, status);

  Future<void> addAuditLog(String taskId, Map<String, dynamic> logData) =>
      _service.addAuditLog(taskId, logData);

  Future<List<Map<String, dynamic>>> getAuditLogs(String taskId) =>
      _service.getAuditLogs(taskId);
}

