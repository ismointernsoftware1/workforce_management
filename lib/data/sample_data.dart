import 'package:intl/intl.dart';

import '../models/chat_models.dart';
import '../models/task_model.dart';
import '../models/team_member.dart';
import '../models/user_model.dart';

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

  static List<UserModel> users() => [
        UserModel(
          id: 'user-1',
          name: 'Alice Johnson',
          role: 'Senior Engineer',
          email: 'alice@company.com',
          status: 'Active',
          manager: 'Marcus Lee',
        ),
        UserModel(
          id: 'user-2',
          name: 'Bob Smith',
          role: 'Product Manager',
          email: 'bob@company.com',
          status: 'Active',
          manager: 'Emma Davis',
        ),
        UserModel(
          id: 'user-3',
          name: 'Carol Davis',
          role: 'Sales Executive',
          email: 'carol@company.com',
          status: 'On leave',
          manager: 'Victor Chen',
        ),
        UserModel(
          id: 'user-4',
          name: 'David Wilson',
          role: 'Marketing Manager',
          email: 'david@company.com',
          status: 'Active',
          manager: 'Sophia Patel',
        ),
        UserModel(
          id: 'user-5',
          name: 'Eva Martinez',
          role: 'HR Specialist',
          email: 'eva@company.com',
          status: 'Active',
          manager: 'Marcus Lee',
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

  static List<TeamMember> members() => [
        TeamMember(
          id: 'member-1',
          name: 'Alice Johnson',
          role: 'Senior Engineer',
          email: 'alice@company.com',
          department: 'Engineering',
          isOnline: true,
        ),
        TeamMember(
          id: 'member-2',
          name: 'Bob Smith',
          role: 'Product Manager',
          email: 'bob@company.com',
          department: 'Product',
          isOnline: true,
        ),
        TeamMember(
          id: 'member-3',
          name: 'Carol Davis',
          role: 'Sales Executive',
          email: 'carol@company.com',
          department: 'Sales',
          isOnline: false,
        ),
      ];
}

