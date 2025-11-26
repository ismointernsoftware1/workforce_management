import 'package:flutter/foundation.dart';

import '../controllers/chat_controller.dart';
import '../controllers/task_controller.dart';
import '../controllers/team_controller.dart';
import '../data/sample_data.dart';
import '../models/chat_models.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../models/team_model.dart';

enum DashboardTab { tasks, team, chat }

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
  List<UserModel> allUsers = const [];
  List<UserModel> users = const [];
  List<Team> teams = const [];
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
    try {
      tasks = await _taskController.fetchTasks();
      if (tasks.isEmpty) {
        tasks = SampleData.tasks();
      }
      allUsers = await _teamController.fetchUsers();
      users = allUsers;
      conversations = await _chatController.fetchConversations();
      if (conversations.isEmpty) {
        conversations = SampleData.conversations();
      }
      teams = await _teamController.fetchTeams();
      selectedConversationId =
          conversations.isNotEmpty ? conversations.first.id : null;
      lastError = null;
    } catch (error) {
      lastError = error.toString();
      tasks = SampleData.tasks();
      allUsers = const [];
      users = const [];
      conversations = SampleData.conversations();
      selectedConversationId =
          conversations.isNotEmpty ? conversations.first.id : null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
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

  Future<void> addUser(UserModel user) async {
    try {
      await _teamController.addUser(user);
      await refreshUsers();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _teamController.updateUser(user);
      await refreshUsers();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _teamController.deleteUser(userId);
      await refreshUsers();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> refreshUsers() async {
    allUsers = await _teamController.fetchUsers();
    users = allUsers;
    notifyListeners();
  }

  Future<void> addTeam(Team team) async {
    try {
      await _teamController.createTeam(team);
      await refreshTeams();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> refreshTeams() async {
    teams = await _teamController.fetchTeams();
    notifyListeners();
  }

  Future<void> updateTeamMembers(
      String teamId, List<String> memberIds) async {
    try {
      await _teamController.updateTeamMembers(teamId, memberIds);
      await refreshTeams();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTeam(Team team) async {
    try {
      await _teamController.updateTeam(team);
      await refreshTeams();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTeam(String teamId) async {
    try {
      await _teamController.deleteTeam(teamId);
      await refreshTeams();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
      rethrow;
    }
  }
}

