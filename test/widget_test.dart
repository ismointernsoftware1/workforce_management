// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:workforce_app/app.dart';
import 'package:workforce_app/data/sample_data.dart';
import 'package:workforce_app/models/chat_models.dart';
import 'package:workforce_app/models/task_model.dart';
import 'package:workforce_app/models/team_member.dart';
import 'package:workforce_app/services/firebase_service.dart';

void main() {
  testWidgets(
    'Dashboard renders navigation tabs',
    (WidgetTester tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final view = tester.view;
      view.physicalSize = const Size(1920, 1080);
      view.devicePixelRatio = 1.0;

      addTearDown(() {
        view.resetPhysicalSize();
        view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        WorkforceApp(
          firebaseService: _FakeFirebaseService(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Tasks & Workflow'), findsOneWidget);
      expect(find.text('Team'), findsWidgets);
      expect(find.text('Chat'), findsWidgets);
    },
  );
}

class _FakeFirebaseService extends FirebaseService {
  _FakeFirebaseService() : super.stub();

  @override
  Future<List<TaskModel>> fetchTasks() async {
    return SampleData.tasks();
  }

  @override
  Future<void> addTask(TaskModel task) async {}

  @override
  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {}

  @override
  Future<List<TeamMember>> fetchMembers() async {
    return SampleData.members();
  }

  @override
  Future<List<Conversation>> fetchConversations() async {
    return SampleData.conversations();
  }

  @override
  Future<void> sendMessage(String conversationId, ChatMessage message) async {}
}
