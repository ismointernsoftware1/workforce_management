import 'package:flutter/material.dart';
import 'task_screen_view.dart';

// Re-export TaskScreenView as TasksView for backward compatibility
class TasksView extends StatelessWidget {
  const TasksView({super.key});

  @override
  Widget build(BuildContext context) {
    return const TaskScreenView();
  }
}

