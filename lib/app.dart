import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'controllers/chat_controller.dart';
import 'controllers/expense_controller.dart';
import 'controllers/task_controller.dart';
import 'controllers/team_controller.dart';
import 'providers/dashboard_provider.dart';
import 'providers/expense_provider.dart';
import 'services/firebase_service.dart';
import 'views/dashboard_view.dart';

class WorkforceApp extends StatelessWidget {
  WorkforceApp({
    super.key,
    FirebaseService? firebaseService,
  }) : _firebaseService = firebaseService ?? FirebaseService();

  final FirebaseService _firebaseService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(
            taskController: TaskController(_firebaseService),
            teamController: TeamController(_firebaseService),
            chatController: ChatController(_firebaseService),
          )..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => ExpenseProvider(
            expenseController: ExpenseController(_firebaseService),
          )..initialize(),
        ),
      ],
      child: MaterialApp(
        title: 'Workforce Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const DashboardView(),
        routes: {
          '/dashboard': (context) => const DashboardView(),
        },
      ),
    );
  }
}

