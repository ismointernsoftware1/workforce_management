import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_models.dart';
import '../models/task_model.dart';
import '../models/team_model.dart';
import '../models/user_model.dart';
import '../models/team_member.dart';
import '../models/expense_model.dart';
import '../models/expense_category.dart';
import '../models/reimbursement_model.dart';

class FirebaseService {
  FirebaseService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  FirebaseService.stub() : _firestore = null;

  final FirebaseFirestore? _firestore;

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

  Future<void> addUser(UserModel user) async {
    final docRef = _usersCol.doc();
    await docRef.set({
      ...user.toMap(),
      'id': docRef.id,
    });
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
}

