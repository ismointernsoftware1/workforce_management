import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'controllers/chat_controller.dart';
import 'controllers/expense_controller.dart';
import 'controllers/realtime_chat_controller.dart';
import 'controllers/task_controller.dart';
import 'controllers/team_controller.dart';
import 'providers/dashboard_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/realtime_chat_provider.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/realtime_chat_service.dart';
import 'views/auth/login_view.dart';
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
        // Auth service provider
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        // Other providers will be added after authentication
      ],
      child: Consumer<AuthService>(
        builder: (context, authService, _) {
          return MaterialApp(
            title: 'Workforce Management',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: StreamBuilder<User?>(
              stream: authService.authStateChanges,
              builder: (context, snapshot) {
                // Show loading while checking auth state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                // If user is authenticated, show dashboard
                if (snapshot.hasData && snapshot.data != null) {
                  return _buildAuthenticatedApp(snapshot.data!);
                }

                // If user is not authenticated, show login
                return const LoginView();
              },
            ),
            routes: {
              '/dashboard': (context) => const DashboardView(),
            },
          );
        },
      ),
    );
  }

  Widget _buildAuthenticatedApp(User user) {
    // Get user info
    final userId = user.uid;
    final userName = user.displayName ?? user.email?.split('@')[0] ?? 'User';

    // Initialize chat service and controller
    final realtimeChatService = RealtimeChatService();
    final realtimeChatController = RealtimeChatController(
      service: realtimeChatService,
      currentUserId: userId,
      currentUserName: userName,
    );

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
        ChangeNotifierProvider(
          create: (_) => RealtimeChatProvider(
            controller: realtimeChatController,
          ),
        ),
      ],
      child: const DashboardView(),
    );
  }
}
