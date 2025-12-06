import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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
import 'utils/rbac_utils.dart';
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
    return Provider<AuthService>(
      create: (_) => AuthService(),
      child: Consumer<AuthService>(
        builder: (context, authService, _) {
          return StreamBuilder<User?>(
            stream: authService.authStateChanges,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildMaterialApp(
                  const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              final user = snapshot.data;
              if (user == null) {
                // Clear RBAC cache on logout
                RBACUtils.clearCache();
                return _buildMaterialApp(const LoginView());
              }

              // Clear RBAC cache on new login to ensure fresh data
              print('RBAC: User logged in - UID: ${user.uid}, Email: ${user.email}');
              print('RBAC: Clearing cache to fetch fresh user data...');
              RBACUtils.clearCache();

              final realtimeChatController = RealtimeChatController(
                service: RealtimeChatService(),
                currentUserId: user.uid,
                currentUserName:
                    user.displayName ?? user.email?.split('@')[0] ?? 'User',
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
                child: _buildMaterialApp(const DashboardView()),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMaterialApp(Widget home) {
    return ShadTheme(
      data: ShadThemeData(),
      child: MaterialApp(
        title: 'Workforce Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: home,
        routes: {
          '/dashboard': (context) => const DashboardView(),
        },
      ),
    );
  }
}
