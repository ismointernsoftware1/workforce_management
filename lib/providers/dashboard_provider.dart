import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../controllers/chat_controller.dart';
import '../controllers/task_controller.dart';
import '../controllers/team_controller.dart';
import '../data/sample_data.dart';
import '../models/chat_models.dart';
import '../models/task_model.dart';
import '../models/team_member.dart';
import '../models/team_model.dart';
import '../models/user_model.dart';
import '../models/search_result.dart';
import '../models/expense_model.dart';
import '../utils/rbac_utils.dart';

enum DashboardTab { tasks, team, chat, expenses, formBuilder }

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
  bool? _isSuperAdmin;

  List<TaskModel> tasks = const [];
  List<UserModel> allUsers = const [];
  List<UserModel> users = const [];
  List<Team> teams = const [];
  List<TeamMember> members = const [];
  List<Conversation> conversations = const [];
  String? selectedConversationId;

  String taskFilter = 'All';
  String taskSearchQuery = '';
  String globalSearchQuery = '';
  List<SearchResult> globalSearchResults = [];
  static const List<String> taskFilters = [
    'All',
    'Pending',
    'In Progress',
    'Completed',
  ];

  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();

    // Set initial tab based on user role
    print('DashboardProvider: Initializing and checking RBAC...');
    _isSuperAdmin = await RBACUtils.isSuperAdmin();
    print('DashboardProvider: isSuperAdmin = $_isSuperAdmin');
    
    if (_isSuperAdmin == true) {
      print('DashboardProvider: Setting activeTab to formBuilder');
      activeTab = DashboardTab.formBuilder;
    } else {
      print('DashboardProvider: Setting activeTab to tasks');
      activeTab = DashboardTab.tasks;
    }
    
    notifyListeners(); // Notify after setting tab

    await Future.wait([
      _loadTasks(),
      refreshUsers(),
      refreshTeams(),
      refreshConversations(),
      refreshMembers(),
    ]);

    isLoading = false;
    notifyListeners();
  }

  bool? get isSuperAdmin => _isSuperAdmin;

  Future<void> _loadTasks() async {
    try {
      tasks = await _taskController.fetchTasks();
      lastError = null;
    } catch (error) {
      tasks = const [];
      lastError = error.toString();
    }
  }

  Future<void> refreshTasks() async {
    await _loadTasks();
    notifyListeners();
  }

  Future<void> refreshUsers() async {
    try {
      allUsers = await _teamController.fetchUsers();
      users = allUsers;
      lastError = null;
    } catch (error) {
      allUsers = [];
      users = [];
      lastError = error.toString();
    }
    notifyListeners();
  }

  Future<void> refreshMembers() async {
    try {
      members = await _teamController.fetchMembers();
      if (members.isEmpty) {
        members = allUsers
            .map(
              (user) => TeamMember(
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                department: user.department,
                isOnline: user.status == 'Active',
              ),
            )
            .toList();
      }
    } catch (error) {
      members = SampleData.members();
      lastError = error.toString();
    }
    notifyListeners();
  }

  Future<void> refreshTeams() async {
    try {
      teams = await _teamController.fetchTeams();
      lastError = null;
    } catch (error) {
      lastError = error.toString();
    }
    notifyListeners();
  }

  Future<void> refreshConversations() async {
    try {
      conversations = await _chatController.fetchConversations();
      if (conversations.isEmpty) {
        conversations = SampleData.conversations();
      }
      selectedConversationId =
          conversations.isNotEmpty ? conversations.first.id : null;
      lastError = null;
    } catch (error) {
      conversations = SampleData.conversations();
      selectedConversationId =
          conversations.isNotEmpty ? conversations.first.id : null;
      lastError = error.toString();
    }
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
    
    // Use cached isSuperAdmin value
    final isSuperAdmin = _isSuperAdmin ?? false;
    
    // Check RBAC restrictions
    if (isSuperAdmin) {
      // Super Admin: Only allow Form Builder tab
      if (tab != DashboardTab.formBuilder) {
        return;
      }
    } else {
      // Non-Super Admin: Don't allow Form Builder tab
      if (tab == DashboardTab.formBuilder) {
        return;
      }
    }
    
    activeTab = tab;
    notifyListeners();
  }

  void changeTaskFilter(String filter) {
    taskFilter = filter;
    notifyListeners();
  }

  void setTaskSearchQuery(String query) {
    taskSearchQuery = query;
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

  Future<void> filterUsers(String query) async {
    if (query.trim().isEmpty) {
      users = allUsers;
    } else {
      final lower = query.toLowerCase();
      users = allUsers
          .where(
            (user) =>
                user.name.toLowerCase().contains(lower) ||
                user.email.toLowerCase().contains(lower),
          )
          .toList();
    }
    notifyListeners();
  }

  Future<void> addUser(UserModel user, {String? password}) async {
    try {
      await _teamController.addUser(user, password: password);
      await refreshUsers();
      await refreshMembers();
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
      await refreshMembers();
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
      await refreshMembers();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
      rethrow;
    }
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

  Future<void> updateTeamMembers(
    String teamId,
    List<String> memberIds,
  ) async {
    try {
      await _teamController.updateTeamMembers(teamId, memberIds);
      await refreshTeams();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addTask(TaskModel task) async {
    try {
      await _taskController.createTask(task);
      await refreshTasks();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTask(TaskModel task) async {
    try {
      await _taskController.updateTask(task);
      await refreshTasks();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTaskWithAudit(
    TaskModel task, {
    String? actionBy,
    String? actionByName,
  }) async {
    try {
      await _taskController.updateTaskWithAudit(
        task,
        actionBy: actionBy,
        actionByName: actionByName,
      );
      await refreshTasks();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _taskController.deleteTask(taskId);
      await refreshTasks();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTaskStatus(
    String taskId,
    TaskStatus status,
  ) async {
    try {
      await _taskController.updateStatus(taskId, status);
      await refreshTasks();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTaskAuditLogs(String taskId) async {
    try {
      return await _taskController.getAuditLogs(taskId);
    } catch (error) {
      lastError = error.toString();
      return [];
    }
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
      await _chatController.sendMessage(selectedConversationId!, message);
    } catch (_) {
      // keep optimistic UI even if sending fails
    }
  }

  void performGlobalSearch(String query, {List<ExpenseModel>? expenses}) {
    globalSearchQuery = query;
    final results = <SearchResult>[];
    final lowerQuery = query.toLowerCase().trim();

    if (lowerQuery.isEmpty) {
      globalSearchResults = [];
      notifyListeners();
      return;
    }

    // Search tasks
    for (final task in tasks) {
      if (task.title.toLowerCase().contains(lowerQuery) ||
          task.description.toLowerCase().contains(lowerQuery)) {
        results.add(SearchResult(
          type: SearchResultType.task,
          id: task.id,
          title: task.title,
          subtitle: task.description,
          icon: Icons.task_alt,
        ));
      }
    }

    // Search team members (from members list)
    for (final member in members) {
      if (member.name.toLowerCase().contains(lowerQuery) ||
          member.email.toLowerCase().contains(lowerQuery) ||
          member.role.toLowerCase().contains(lowerQuery) ||
          member.department.toLowerCase().contains(lowerQuery)) {
        final initials = member.name
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase();
        results.add(SearchResult(
          type: SearchResultType.teamMember,
          id: member.id,
          title: member.name,
          subtitle: '${member.email} • ${member.role}',
          icon: Icons.person,
          avatarText: initials,
          email: member.email,
          role: member.role,
        ));
      }
    }

    // Search users (from allUsers list)
    for (final user in allUsers) {
      if (user.name.toLowerCase().contains(lowerQuery) ||
          user.email.toLowerCase().contains(lowerQuery) ||
          user.role.toLowerCase().contains(lowerQuery) ||
          user.department.toLowerCase().contains(lowerQuery)) {
        // Check if not already added from members list
        if (!results.any((r) => r.type == SearchResultType.teamMember && r.id == user.id)) {
          final initials = user.name
              .split(' ')
              .map((e) => e.isNotEmpty ? e[0] : '')
              .take(2)
              .join()
              .toUpperCase();
          results.add(SearchResult(
            type: SearchResultType.teamMember,
            id: user.id,
            title: user.name,
            subtitle: '${user.email} • ${user.role}',
            icon: Icons.person,
            avatarText: initials,
            email: user.email,
            role: user.role,
          ));
        }
      }
    }

    // Search teams
    for (final team in teams) {
      if (team.name.toLowerCase().contains(lowerQuery) ||
          team.description.toLowerCase().contains(lowerQuery)) {
        results.add(SearchResult(
          type: SearchResultType.teamMember,
          id: team.id,
          title: team.name,
          subtitle: team.description,
          icon: Icons.groups,
        ));
      }
    }

    // Search expenses (if provided)
    if (expenses != null) {
      for (final expense in expenses) {
        final description = expense.description.toLowerCase();
        final employeeName = expense.employeeName.toLowerCase();
        final merchant = (expense.merchant ?? '').toLowerCase();
        
        if (description.contains(lowerQuery) ||
            employeeName.contains(lowerQuery) ||
            merchant.contains(lowerQuery)) {
          results.add(SearchResult(
            type: SearchResultType.expense,
            id: expense.id,
            title: expense.description,
            subtitle: '${expense.employeeName} - ${expense.amount.toStringAsFixed(2)} ${expense.currency}',
            icon: Icons.receipt,
          ));
        }
      }
    }

    // Search conversations
    for (final conversation in conversations) {
      if (conversation.topic.toLowerCase().contains(lowerQuery) ||
          conversation.preview.toLowerCase().contains(lowerQuery)) {
        results.add(SearchResult(
          type: SearchResultType.conversation,
          id: conversation.id,
          title: conversation.topic,
          subtitle: conversation.preview,
          icon: Icons.chat_bubble_outline,
        ));
      }
    }

    globalSearchResults = results;
    notifyListeners();
  }
}

