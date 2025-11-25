import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_models.dart';
import '../models/task_model.dart';
import '../models/team_member.dart';

class FirebaseService {
  FirebaseService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  FirebaseService.stub() : _firestore = null;

  final FirebaseFirestore? _firestore;

  CollectionReference<Map<String, dynamic>> get _tasksCol =>
      _firestore!.collection('tasks');
  CollectionReference<Map<String, dynamic>> get _teamCol =>
      _firestore!.collection('team');
  CollectionReference<Map<String, dynamic>> get _conversationsCol =>
      _firestore!.collection('conversations');

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

  Future<List<TeamMember>> fetchMembers() async {
    final snapshot = await _teamCol.orderBy('name').get();
    return snapshot.docs
        .map((doc) => TeamMember.fromMap(doc.data(), id: doc.id))
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
}

