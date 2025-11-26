import 'package:flutter/foundation.dart';

import '../controllers/chat_controller.dart';
import '../controllers/task_controller.dart';
import '../controllers/team_controller.dart';
import '../data/sample_data.dart';
import '../models/chat_models.dart';
import '../models/task_model.dart';
import '../models/team_member.dart';

enum DashboardTab { tasks, team, chat, expenses }

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({
    required TaskController taskController,
    required TeamController teamController,
    required ChatController chatController,
  })  : _taskController = taskController,
        _teamController = teamController,
        _chatController = chatController;

  final TaskController _taskController;
  final TeamController _teamController;
  final ChatController _chatController;

  DashboardTab activeTab = DashboardTab.tasks;
  bool isLoading = false;
  String? lastError;

  List<TaskModel> tasks = const [];
  List<TeamMember> members = const [];
  List<Conversation> conversations = const [];
  String? selectedConversationId;

  String taskFilter = 'All';
  static const List<String> taskFilters = [
    'All',
    'Pending',
    'In Progress',
    'Completed',
  ];

  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();
    
    // Fetch tasks independently - don't let other failures affect tasks
    try {
      tasks = await _taskController.fetchTasks();
      print('Fetched ${tasks.length} tasks from Firestore');
      lastError = null;
    } catch (error) {
      print('Error fetching tasks: $error');
      tasks = [];
      lastError = error.toString();
    }
    
    // Fetch members independently
    try {
      members = await _teamController.fetchMembers();
      if (members.isEmpty) {
        members = SampleData.members();
      }
    } catch (error) {
      print('Error fetching members: $error');
      members = SampleData.members();
    }
    
    // Fetch conversations independently
    try {
      conversations = await _chatController.fetchConversations();
      if (conversations.isEmpty) {
        conversations = SampleData.conversations();
      }
      selectedConversationId =
          conversations.isNotEmpty ? conversations.first.id : null;
    } catch (error) {
      print('Error fetching conversations: $error');
      conversations = SampleData.conversations();
      selectedConversationId =
          conversations.isNotEmpty ? conversations.first.id : null;
    }
    
    isLoading = false;
    notifyListeners();
  }

  List<TaskModel> get filteredTasks {
    switch (taskFilter) {
      case 'Pending':
        return tasks
            .where((task) => task.status == TaskStatus.pending)
            .toList();
      case 'In Progress':
        return tasks
            .where((task) => task.status == TaskStatus.inProgress)
            .toList();
      case 'Completed':
        return tasks
            .where((task) => task.status == TaskStatus.completed)
            .toList();
      default:
        return tasks;
    }
  }

  int get totalTasks => tasks.length;
  int get inProgressCount =>
      tasks.where((task) => task.status == TaskStatus.inProgress).length;
  int get completedCount =>
      tasks.where((task) => task.status == TaskStatus.completed).length;

  void changeTab(DashboardTab tab) {
    if (activeTab == tab) return;
    activeTab = tab;
    notifyListeners();
  }

  void changeTaskFilter(String filter) {
    taskFilter = filter;
    notifyListeners();
  }

  Conversation? get selectedConversation {
    if (conversations.isEmpty) {
      return null;
    }
    if (selectedConversationId == null) {
      return conversations.first;
    }
    return conversations.firstWhere(
      (c) => c.id == selectedConversationId,
      orElse: () => conversations.first,
    );
  }

  void selectConversation(String conversationId) {
    selectedConversationId = conversationId;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || selectedConversationId == null) return;
    final conversationIndex = conversations.indexWhere(
      (c) => c.id == selectedConversationId,
    );
    if (conversationIndex == -1) return;
    final message = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      sender: 'You',
      body: text.trim(),
      sentAt: DateTime.now(),
      isMine: true,
    );
    final updatedMessages = [
      ...conversations[conversationIndex].messages,
      message,
    ];
    conversations[conversationIndex] = Conversation(
      id: conversations[conversationIndex].id,
      topic: conversations[conversationIndex].topic,
      preview: message.body,
      updatedAt: message.sentAt,
      unreadCount: conversations[conversationIndex].unreadCount,
      members: conversations[conversationIndex].members,
      messages: updatedMessages,
    );
    notifyListeners();
    try {
      await _chatController.sendMessage(
        selectedConversationId!,
        message,
      );
    } catch (_) {
      // keep optimistic UI even if network fails
    }
  }

  Future<String> addTask(TaskModel task) async {
    try {
      final taskId = await _taskController.createTask(task);
      // Refresh tasks from Firestore
      tasks = await _taskController.fetchTasks();
      notifyListeners();
      return taskId;
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTask(TaskModel task) async {
    try {
      await _taskController.updateTask(task);
      // Refresh tasks from Firestore
      tasks = await _taskController.fetchTasks();
      notifyListeners();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTaskWithAudit(TaskModel task, {String? actionBy, String? actionByName}) async {
    try {
      await _taskController.updateTaskWithAudit(task, actionBy: actionBy, actionByName: actionByName);
      // Refresh tasks from Firestore
      tasks = await _taskController.fetchTasks();
      notifyListeners();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _taskController.deleteTask(taskId);
      // Refresh tasks from Firestore
      tasks = await _taskController.fetchTasks();
      notifyListeners();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    try {
      await _taskController.updateStatus(taskId, status);
      // Refresh tasks from Firestore
      tasks = await _taskController.fetchTasks();
      notifyListeners();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> refreshTasks() async {
    try {
      tasks = await _taskController.fetchTasks();
      print('Refreshed: Fetched ${tasks.length} tasks from Firestore');
      lastError = null;
      notifyListeners();
    } catch (error) {
      lastError = error.toString();
      print('Error refreshing tasks: $error');
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getTaskAuditLogs(String taskId) async {
    try {
      return await _taskController.getAuditLogs(taskId);
    } catch (error) {
      print('Error fetching audit logs: $error');
      return [];
    }
  }
}

