import 'package:flutter/foundation.dart';

import '../controllers/chat_controller.dart';
import '../controllers/task_controller.dart';
import '../controllers/team_controller.dart';
import '../data/sample_data.dart';
import '../models/chat_models.dart';
import '../models/task_model.dart';
import '../models/team_member.dart';

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
    try {
      tasks = await _taskController.fetchTasks();
      if (tasks.isEmpty) {
        tasks = SampleData.tasks();
      }
      members = await _teamController.fetchMembers();
      if (members.isEmpty) {
        members = SampleData.members();
      }
      conversations = await _chatController.fetchConversations();
      if (conversations.isEmpty) {
        conversations = SampleData.conversations();
      }
      selectedConversationId =
          conversations.isNotEmpty ? conversations.first.id : null;
      lastError = null;
    } catch (error) {
      lastError = error.toString();
      tasks = SampleData.tasks();
      members = SampleData.members();
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
}

