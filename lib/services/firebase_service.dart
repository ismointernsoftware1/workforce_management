import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import '../models/app_user.dart';
import '../models/chat_models.dart';
import '../models/task_model.dart';
import '../models/team_model.dart';
import '../models/user_model.dart';
import '../models/team_member.dart';
import '../models/expense_model.dart';
import '../models/expense_category.dart';
import '../models/reimbursement_model.dart';
import '../models/timesheet_entry.dart';
import 'user_service.dart';

class FirebaseService {
  FirebaseService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  FirebaseService.stub() : _firestore = null;

  final FirebaseFirestore? _firestore;
  FirebaseAuth? _secondaryAuth;

  CollectionReference<Map<String, dynamic>> get _tasksCol =>
      _firestore!.collection('tasks');
  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore!.collection('users');
  CollectionReference<Map<String, dynamic>> get _conversationsCol =>
      _firestore!.collection('conversations');
  CollectionReference<Map<String, dynamic>> get _teamsCol =>
      _firestore!.collection('teams');
  CollectionReference<Map<String, dynamic>> get _expensesCol =>
      _firestore!.collection('expenses');
  CollectionReference<Map<String, dynamic>> get _reimbursementsCol =>
      _firestore!.collection('reimbursements');
  CollectionReference<Map<String, dynamic>> get _expenseCategoriesCol =>
      _firestore!.collection('expenseCategories');
  CollectionReference<Map<String, dynamic>> get _timesheetEntriesCol =>
      _firestore!.collection('timesheetEntries');

  Future<List<TaskModel>> fetchTasks() async {
    try {
      // Try with orderBy first, if it fails (e.g., missing index), fetch without ordering
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await _tasksCol.orderBy('dueDate').get();
      } catch (e) {
        // If orderBy fails (e.g., missing index), fetch without ordering
        print('Warning: OrderBy failed, fetching without ordering: $e');
        snapshot = await _tasksCol.get();
      }
      
      print('Found ${snapshot.docs.length} documents in Firestore');
      final tasks = <TaskModel>[];
      for (var doc in snapshot.docs) {
        try {
          print('Parsing task document: ${doc.id}');
          print('Document data keys: ${doc.data().keys.toList()}');
          final task = TaskModel.fromSnapshot(doc);
          print('Successfully parsed task: ${task.title} (ID: ${task.id})');
          tasks.add(task);
        } catch (e, stackTrace) {
          // Log error but don't crash - skip problematic documents
          print('Error parsing task document ${doc.id}: $e');
          print('Stack trace: $stackTrace');
          print('Document data: ${doc.data()}');
        }
      }
      
      print('Successfully parsed ${tasks.length} tasks');
      return tasks;
    } catch (e) {
      print('Error fetching tasks: $e');
      rethrow; // Re-throw so the provider can handle it
    }
  }

  /// Real-time stream of tasks from Firestore
  /// Automatically updates when tasks are added, updated, or deleted
  Stream<List<TaskModel>> fetchTasksStream() {
    try {
      // Try with orderBy first, if it fails (e.g., missing index), use stream without ordering
      try {
        return _tasksCol
            .orderBy('dueDate')
            .snapshots()
            .map((snapshot) {
              print('Tasks stream update: ${snapshot.docs.length} documents');
              final tasks = <TaskModel>[];
              for (var doc in snapshot.docs) {
                try {
                  final task = TaskModel.fromSnapshot(doc);
                  tasks.add(task);
                } catch (e) {
                  // Log error but don't crash - skip problematic documents
                  print('Error parsing task document ${doc.id} in stream: $e');
                }
              }
              print('Successfully parsed ${tasks.length} tasks from stream');
              return tasks;
            });
      } catch (e) {
        // If orderBy fails (e.g., missing index), use stream without ordering
        print('Warning: OrderBy failed in stream, using stream without ordering: $e');
        return _tasksCol
            .snapshots()
            .map((snapshot) {
              print('Tasks stream update (no orderBy): ${snapshot.docs.length} documents');
              final tasks = <TaskModel>[];
              for (var doc in snapshot.docs) {
                try {
                  final task = TaskModel.fromSnapshot(doc);
                  tasks.add(task);
                } catch (e) {
                  // Log error but don't crash - skip problematic documents
                  print('Error parsing task document ${doc.id} in stream: $e');
                }
              }
              print('Successfully parsed ${tasks.length} tasks from stream');
              return tasks;
            });
      }
    } catch (e) {
      print('Error setting up tasks stream: $e');
      // Return an empty stream on error
      return Stream.value([]);
    }
  }

  Future<String> addTask(TaskModel task) async {
    final taskMap = task.toMap();
    taskMap['createdAt'] = FieldValue.serverTimestamp();
    taskMap['updatedAt'] = FieldValue.serverTimestamp();
    final docRef = await _tasksCol.add(taskMap);
    final taskId = docRef.id;
    
    // Create audit log for task creation
    await addAuditLog(taskId, {
      'action': 'created',
      'actionBy': task.createdBy ?? 'system',
      'actionByName': task.createdBy ?? 'System',
      'description': 'Task "${task.title}" was created',
    });
    
    return taskId;
  }

  Future<void> updateTask(TaskModel task, {String? actionBy, String? actionByName}) async {
    final oldTaskDoc = await _tasksCol.doc(task.id).get();
    final oldTask = oldTaskDoc.exists ? TaskModel.fromSnapshot(oldTaskDoc) : null;
    
    final taskMap = task.toMap();
    taskMap['updatedAt'] = FieldValue.serverTimestamp();
    await _tasksCol.doc(task.id).update(taskMap);
    
    // Create audit log for task update
    final changes = <String>[];
    if (oldTask != null) {
      if (oldTask.title != task.title) {
        changes.add('Title: "${oldTask.title}" → "${task.title}"');
      }
      if (oldTask.description != task.description) {
        changes.add('Description changed');
      }
      if (oldTask.priority != task.priority) {
        changes.add('Priority: ${oldTask.priority.name} → ${task.priority.name}');
      }
      if (oldTask.status != task.status) {
        changes.add('Status: ${oldTask.status.name} → ${task.status.name}');
      }
      if (oldTask.assignedTo != task.assignedTo) {
        changes.add('Assigned to: ${oldTask.assignedTo} → ${task.assignedTo}');
      }
    }
    
    await addAuditLog(task.id, {
      'action': 'updated',
      'actionBy': actionBy ?? 'system',
      'actionByName': actionByName ?? 'System',
      'description': changes.isNotEmpty ? changes.join(', ') : 'Task updated',
    });
  }

  Future<void> deleteTask(String taskId, {String? actionBy, String? actionByName}) async {
    // Get task before deleting for audit log
    final taskDoc = await _tasksCol.doc(taskId).get();
    final taskTitle = taskDoc.exists
        ? (taskDoc.data()?['title'] as String? ?? 'Unknown')
        : 'Unknown';
    
    // Create audit log before deletion
    await addAuditLog(taskId, {
      'action': 'deleted',
      'actionBy': actionBy ?? 'system',
      'actionByName': actionByName ?? 'System',
      'description': 'Task "$taskTitle" was deleted',
    });
    
    await _tasksCol.doc(taskId).delete();
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status, {String? actionBy, String? actionByName}) async {
    // Get old status for audit log
    final taskDoc = await _tasksCol.doc(taskId).get();
    final oldStatus = taskDoc.exists
        ? (taskDoc.data()?['status'] as String? ?? 'unknown')
        : 'unknown';
    
    await _tasksCol.doc(taskId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Create audit log for status change
    await addAuditLog(taskId, {
      'action': 'statusChanged',
      'actionBy': actionBy ?? 'system',
      'actionByName': actionByName ?? 'System',
      'oldValue': oldStatus,
      'newValue': status.name,
      'description': 'Status changed from $oldStatus to ${status.name}',
    });
  }

  // Audit logs collection
  CollectionReference<Map<String, dynamic>> _auditLogsCol(String taskId) =>
      _tasksCol.doc(taskId).collection('auditLogs');

  Future<void> addAuditLog(String taskId, Map<String, dynamic> logData) async {
    final logMap = Map<String, dynamic>.from(logData);
    logMap['timestamp'] = FieldValue.serverTimestamp();
    await _auditLogsCol(taskId).add(logMap);
  }

  Future<List<Map<String, dynamic>>> getAuditLogs(String taskId) async {
    final snapshot = await _auditLogsCol(taskId)
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
  }

  Future<List<UserModel>> fetchUsers() async {
    final snapshot = await _usersCol.orderBy('name').get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), id: doc.id))
        .toList(growable: false);
  }

  Future<List<TeamMember>> fetchMembers() async {
    final snapshot = await _usersCol.orderBy('name').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return TeamMember(
        id: doc.id,
        name: data['name'] as String? ?? '',
        email: data['email'] as String? ?? '',
        role: data['role'] as String? ?? '',
        department: data['department'] as String? ?? '',
        isOnline: (data['status'] as String? ?? 'Active') == 'Active',
      );
    }).toList(growable: false);
  }

  Future<List<Conversation>> fetchConversations() async {
    final snapshot =
        await _conversationsCol.orderBy('updatedAt', descending: true).get();
    final conversations = <Conversation>[];

    for (final doc in snapshot.docs) {
      final messagesSnap =
          await doc.reference.collection('messages').orderBy('sentAt').get();
      conversations.add(
        Conversation.fromMap(
          doc.data()
            ..addAll({
              'messages': messagesSnap.docs
                  .map((msg) => msg.data()..addAll({'id': msg.id}))
                  .toList(),
            }),
          id: doc.id,
        ),
      );
    }

    return conversations;
  }

  Future<void> sendMessage(
    String conversationId,
    ChatMessage message,
  ) async {
    await _conversationsCol
        .doc(conversationId)
        .collection('messages')
        .add(message.toMap());
    await _conversationsCol.doc(conversationId).update({
      'preview': message.body,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Team>> fetchTeams() async {
    final snapshot = await _teamsCol.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => Team.fromMap(doc.data(), id: doc.id))
        .toList(growable: false);
  }

  Future<void> createTeam(Team team) async {
    final docRef = _teamsCol.doc();
    await docRef.set({
      ...team.toMap(),
      'id': docRef.id,
    });
  }

  Future<void> updateTeamMembers(
      String teamId, List<String> memberIds) async {
    await _teamsCol.doc(teamId).update({'memberIds': memberIds});
  }

  Future<void> updateTeam(Team team) async {
    await _teamsCol.doc(team.id).update({
      'name': team.name,
      'description': team.description,
    });
  }

  Future<void> deleteTeam(String teamId) async {
    await _teamsCol.doc(teamId).delete();
  }

  Future<void> addUser(UserModel user, {String? password, String? roleId}) async {
    // If password is provided, create Firebase Auth account first
    String userId;
    if (password != null && password.isNotEmpty) {
      try {
        final secondaryAuth = await _getSecondaryAuth();
        final credential = await secondaryAuth.createUserWithEmailAndPassword(
          email: user.email,
          password: password,
        );
        userId = credential.user!.uid;
        await credential.user?.updateDisplayName(user.name);

        await _usersCol.doc(userId).set({
          ...user.toMap(),
          'id': userId,
        });

        // Create AppUser document for RBAC system if roleId is provided
        if (roleId != null && roleId.isNotEmpty) {
          try {
            final userService = UserService();
            await userService.createAppUser(AppUser(
              uid: userId,
              email: user.email,
              roleId: roleId,
            ));
            debugPrint('AppUser created for ${user.email} with roleId: $roleId');
          } catch (e) {
            debugPrint('Warning: Failed to create AppUser: $e');
            // Don't throw - user is created, just AppUser failed
          }
        }

        await secondaryAuth.signOut();
      } catch (e) {
        throw Exception('Failed to create user account: $e');
      }
    } else {
      // For users without password (legacy or manual creation), use Firestore-generated ID
      final docRef = _usersCol.doc();
      userId = docRef.id;
      await docRef.set({
        ...user.toMap(),
        'id': userId,
      });
      
      // Note: AppUser cannot be created without Firebase Auth UID
      // Users created without password need to be migrated manually
    }
  }

  Future<void> updateUser(UserModel user) async {
    if (user.id.isEmpty) {
      throw Exception('User ID is required to update');
    }
    await _usersCol.doc(user.id).update(user.toMap());
  }

  Future<void> deleteUser(String userId) async {
    await _usersCol.doc(userId).delete();
  }
  Future<FirebaseAuth> _getSecondaryAuth() async {
    if (_secondaryAuth != null) return _secondaryAuth!;

    try {
      final app = Firebase.app('user_admin');
      _secondaryAuth = FirebaseAuth.instanceFor(app: app);
      return _secondaryAuth!;
    } catch (_) {
      final app = await Firebase.initializeApp(
        name: 'user_admin',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _secondaryAuth = FirebaseAuth.instanceFor(app: app);
      return _secondaryAuth!;
    }
  }

  // ============= EXPENSE METHODS =============

  Future<List<ExpenseModel>> fetchExpenses({String? employeeId}) async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        if (employeeId != null) {
          snapshot = await _expensesCol
              .where('employeeId', isEqualTo: employeeId)
              .orderBy('expenseDate', descending: true)
              .get();
        } else {
          snapshot = await _expensesCol.orderBy('expenseDate', descending: true).get();
        }
      } catch (e) {
        // If orderBy fails (e.g., missing index), fetch without ordering
        print('Warning: OrderBy failed for expenses, fetching without ordering: $e');
        if (employeeId != null) {
          snapshot = await _expensesCol
              .where('employeeId', isEqualTo: employeeId)
              .get();
        } else {
          snapshot = await _expensesCol.get();
        }
      }
      
      print('Found ${snapshot.docs.length} expense documents in Firestore');
      final expenses = <ExpenseModel>[];
      for (var doc in snapshot.docs) {
        try {
          final expense = ExpenseModel.fromSnapshot(doc);
          expenses.add(expense);
        } catch (e, stackTrace) {
          // Log error but don't crash - skip problematic documents
          print('Error parsing expense document ${doc.id}: $e');
          print('Stack trace: $stackTrace');
          print('Document data: ${doc.data()}');
        }
      }
      print('Successfully parsed ${expenses.length} expenses');
      return expenses;
    } catch (e) {
      print('Error fetching expenses: $e');
      rethrow;
    }
  }

  Future<String> addExpense(ExpenseModel expense) async {
    final expenseMap = expense.toMap();
    expenseMap['createdAt'] = FieldValue.serverTimestamp();
    expenseMap['updatedAt'] = FieldValue.serverTimestamp();
    final docRef = await _expensesCol.add(expenseMap);
    return docRef.id;
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    final expenseMap = expense.toMap();
    expenseMap['updatedAt'] = FieldValue.serverTimestamp();
    await _expensesCol.doc(expense.id).update(expenseMap);
  }

  Future<void> deleteExpense(String expenseId) async {
    await _expensesCol.doc(expenseId).delete();
  }

  Future<void> updateExpenseStatus(String expenseId, ExpenseStatus status) async {
    await _expensesCol.doc(expenseId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Check for duplicate receipts by hash
  Future<bool> checkDuplicateReceipt(String fileHash, String employeeId) async {
    try {
      final snapshot = await _expensesCol
          .where('employeeId', isEqualTo: employeeId)
          .get();
      
      for (var doc in snapshot.docs) {
        final expense = ExpenseModel.fromSnapshot(doc);
        for (var receipt in expense.receipts) {
          if (receipt.fileHash == fileHash) {
            return true; // Duplicate found
          }
        }
      }
      return false; // No duplicate
    } catch (e) {
      print('Error checking duplicate receipt: $e');
      return false;
    }
  }

  // Expense Categories
  Future<List<ExpenseCategory>> fetchExpenseCategories() async {
    try {
      final snapshot = await _expenseCategoriesCol.orderBy('name').get();
      if (snapshot.docs.isEmpty) {
        // If no categories in Firestore, return defaults
        return _getDefaultCategories();
      }
      return snapshot.docs
          .map((doc) => ExpenseCategory.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      print('Error fetching expense categories: $e');
      // Return default categories if fetch fails
      return _getDefaultCategories();
    }
  }

  List<ExpenseCategory> _getDefaultCategories() {
    return [
      const ExpenseCategory(
        id: 'travel',
        name: 'Travel',
        code: 'TRAVEL',
        icon: 'flight',
        color: '#3B82F6',
        requiresApproval: true,
      ),
      const ExpenseCategory(
        id: 'meals',
        name: 'Meals & Entertainment',
        code: 'MEALS',
        icon: 'restaurant',
        color: '#10B981',
        maxAmount: 100,
      ),
      const ExpenseCategory(
        id: 'office',
        name: 'Office Supplies',
        code: 'OFFICE_SUPPLIES',
        icon: 'business',
        color: '#8B5CF6',
      ),
      const ExpenseCategory(
        id: 'transport',
        name: 'Transportation',
        code: 'TRANSPORT',
        icon: 'directions_car',
        color: '#F59E0B',
      ),
      const ExpenseCategory(
        id: 'lodging',
        name: 'Lodging',
        code: 'LODGING',
        icon: 'hotel',
        color: '#EC4899',
        requiresApproval: true,
      ),
      const ExpenseCategory(
        id: 'other',
        name: 'Other',
        code: 'OTHER',
        icon: 'category',
        color: '#6B7280',
      ),
    ];
  }

  // Reimbursements
  Future<List<ReimbursementModel>> fetchReimbursements({String? employeeId}) async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot;
      if (employeeId != null) {
        snapshot = await _reimbursementsCol
            .where('employeeId', isEqualTo: employeeId)
            .orderBy('submittedDate', descending: true)
            .get();
      } else {
        snapshot = await _reimbursementsCol.orderBy('submittedDate', descending: true).get();
      }
      
      return snapshot.docs
          .map((doc) => ReimbursementModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      print('Error fetching reimbursements: $e');
      rethrow;
    }
  }

  Future<String> addReimbursement(ReimbursementModel reimbursement) async {
    final reimbursementMap = reimbursement.toMap();
    reimbursementMap['createdAt'] = FieldValue.serverTimestamp();
    reimbursementMap['updatedAt'] = FieldValue.serverTimestamp();
    final docRef = await _reimbursementsCol.add(reimbursementMap);
    return docRef.id;
  }

  Future<void> updateReimbursement(ReimbursementModel reimbursement) async {
    final reimbursementMap = reimbursement.toMap();
    reimbursementMap['updatedAt'] = FieldValue.serverTimestamp();
    await _reimbursementsCol.doc(reimbursement.id).update(reimbursementMap);
  }

  // Timesheet Entries
  Future<List<TimesheetEntry>> fetchTimesheetEntries({
    required String teamId,
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _timesheetEntriesCol
          .where('teamId', isEqualTo: teamId);

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      if (startDate != null && endDate != null) {
        query = query
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.orderBy('date', descending: false).get();

      return snapshot.docs
          .map((doc) => TimesheetEntry.fromSnapshot(doc))
          .toList();
    } catch (e) {
      print('Error fetching timesheet entries: $e');
      rethrow;
    }
  }

  Future<String> addTimesheetEntry(TimesheetEntry entry) async {
    final entryMap = entry.toMap();
    entryMap['createdAt'] = FieldValue.serverTimestamp();
    entryMap['updatedAt'] = FieldValue.serverTimestamp();
    final docRef = await _timesheetEntriesCol.add(entryMap);
    return docRef.id;
  }

  Future<void> updateTimesheetEntry(TimesheetEntry entry) async {
    final entryMap = entry.toMap();
    entryMap['updatedAt'] = FieldValue.serverTimestamp();
    await _timesheetEntriesCol.doc(entry.id).update(entryMap);
  }

  Future<void> deleteTimesheetEntry(String entryId) async {
    await _timesheetEntriesCol.doc(entryId).delete();
  }

  Future<TimesheetEntry?> getTimesheetEntryByDate({
    required String userId,
    required String teamId,
    required DateTime date,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _timesheetEntriesCol
          .where('userId', isEqualTo: userId)
          .where('teamId', isEqualTo: teamId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return TimesheetEntry.fromSnapshot(snapshot.docs.first);
    } catch (e) {
      print('Error fetching timesheet entry by date: $e');
      return null;
    }
  }
}

