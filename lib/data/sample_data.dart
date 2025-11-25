import 'package:intl/intl.dart';

import '../models/chat_models.dart';
import '../models/task_model.dart';
import '../models/team_member.dart';

class SampleData {
  static List<TaskModel> tasks() {
    final now = DateTime.now();
    return [
      TaskModel(
        id: 'task-1',
        title: 'Complete Q4 Report',
        description: 'Prepare comprehensive quarterly report',
        priority: TaskPriority.high,
        dueDate: DateTime(now.year, 12, 15),
        assignedTo: 'John Doe',
        status: TaskStatus.inProgress,
        subTasks: const [
          SubTask(id: 'sub-1', label: 'Data collection', isDone: true),
          SubTask(id: 'sub-2', label: 'Analysis', isDone: false),
        ],
      ),
      TaskModel(
        id: 'task-2',
        title: 'Team Meeting Prep',
        description: 'Prepare agenda and materials',
        priority: TaskPriority.medium,
        dueDate: DateTime(now.year, 12, 10),
        assignedTo: 'Jane Smith',
        status: TaskStatus.pending,
        subTasks: const [
          SubTask(id: 'sub-3', label: 'Agenda draft', isDone: false),
        ],
      ),
      TaskModel(
        id: 'task-3',
        title: 'Client Presentation',
        description: 'Finalize presentation for client review',
        priority: TaskPriority.low,
        dueDate: DateTime(now.year, 12, 09),
        assignedTo: 'Bob Johnson',
        status: TaskStatus.completed,
        subTasks: const [
          SubTask(id: 'sub-4', label: 'Slides polishing', isDone: true),
        ],
      ),
    ];
  }

  static List<TeamMember> members() => const [
        TeamMember(
          id: 'member-1',
          name: 'John Doe',
          email: 'john@company.com',
          role: 'Manager',
          department: 'Operations',
          isOnline: true,
        ),
        TeamMember(
          id: 'member-2',
          name: 'Jane Smith',
          email: 'jane@company.com',
          role: 'Team Lead',
          department: 'Sales',
          isOnline: true,
        ),
        TeamMember(
          id: 'member-3',
          name: 'Bob Johnson',
          email: 'bob@company.com',
          role: 'Employee',
          department: 'Support',
          isOnline: false,
        ),
        TeamMember(
          id: 'member-4',
          name: 'Alice Brown',
          email: 'alice@company.com',
          role: 'Designer',
          department: 'Product',
          isOnline: true,
        ),
      ];

  static List<Conversation> conversations() {
    final now = DateTime.now();
    return [
      Conversation(
        id: 'convo-1',
        topic: 'Team Sales',
        preview: 'Great work on the presentation!',
        updatedAt: now.subtract(const Duration(minutes: 5)),
        unreadCount: 2,
        members: const ['Jane Smith', 'Bob Johnson'],
        messages: [
          ChatMessage(
            id: 'msg-1',
            sender: 'Jane Smith',
            body: 'Hi team! How are the sales going?',
            sentAt: now.subtract(const Duration(minutes: 30)),
            isMine: false,
          ),
          ChatMessage(
            id: 'msg-2',
            sender: 'Bob Johnson',
            body: 'I closed 3 deals this week',
            sentAt: now.subtract(const Duration(minutes: 25)),
            isMine: false,
          ),
          ChatMessage(
            id: 'msg-3',
            sender: 'Jane Smith',
            body: 'Great work on the presentation!',
            sentAt: now.subtract(const Duration(minutes: 5)),
            isMine: false,
          ),
          ChatMessage(
            id: 'msg-4',
            sender: 'You',
            body: 'Great! We have some good leads',
            sentAt: now.subtract(const Duration(minutes: 4)),
            isMine: true,
          ),
        ],
      ),
      Conversation(
        id: 'convo-2',
        topic: 'Project Alpha',
        preview: 'Updates are ready for review',
        updatedAt: now.subtract(const Duration(hours: 2)),
        unreadCount: 1,
        members: const ['Project Team'],
        messages: const [],
      ),
      Conversation(
        id: 'convo-3',
        topic: 'Bob Johnson',
        preview: 'Thanks for the feedback',
        updatedAt: now.subtract(const Duration(hours: 3)),
        unreadCount: 0,
        members: const ['Bob Johnson'],
        messages: const [],
      ),
    ];
  }

  static String formatDueDate(DateTime date) =>
      DateFormat('MM/dd/yyyy').format(date);
}

