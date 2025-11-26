import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_models.dart';
import '../models/task_model.dart';
import '../models/team_model.dart';
import '../models/user_model.dart';

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

  Future<List<TaskModel>> fetchTasks() async {
    final snapshot = await _tasksCol.orderBy('dueDate').get();
    return snapshot.docs.map(TaskModel.fromSnapshot).toList(growable: false);
  }

  Future<void> addTask(TaskModel task) async {
    await _tasksCol.add(task.toMap());
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    await _tasksCol.doc(taskId).update({'status': status.name});
  }

  Future<List<UserModel>> fetchUsers() async {
    final snapshot = await _usersCol.orderBy('name').get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), id: doc.id))
        .toList(growable: false);
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
}

