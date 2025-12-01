import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../models/team_member.dart';

enum TaskViewMode { overview, list, board, calendar, files }

class TaskScreenController extends ChangeNotifier {
  TaskScreenController();

  TaskViewMode _currentView = TaskViewMode.list;
  String? _selectedDueDateFilter;
  String? _selectedAssigneeFilter;
  String? _selectedPriorityFilter;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showAdvancedFilters = false;

  // Getters
  TaskViewMode get currentView => _currentView;
  String? get selectedDueDateFilter => _selectedDueDateFilter;
  String? get selectedAssigneeFilter => _selectedAssigneeFilter;
  String? get selectedPriorityFilter => _selectedPriorityFilter;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool get showAdvancedFilters => _showAdvancedFilters;

  // Setters
  void setView(TaskViewMode view) {
    _currentView = view;
    notifyListeners();
  }

  void setDueDateFilter(String? filter) {
    _selectedDueDateFilter = filter;
    notifyListeners();
  }

  void setAssigneeFilter(String? filter) {
    _selectedAssigneeFilter = filter;
    notifyListeners();
  }

  void setPriorityFilter(String? filter) {
    _selectedPriorityFilter = filter;
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  void toggleAdvancedFilters() {
    _showAdvancedFilters = !_showAdvancedFilters;
    notifyListeners();
  }

  // Filter tasks based on current filters
  List<TaskModel> filterTasks(
    List<TaskModel> tasks, {
    List<TeamMember>? members,
  }) {
    var filtered = List<TaskModel>.from(tasks);

    // Due date filter
    if (_startDate != null && _endDate != null) {
      filtered = filtered.where((task) {
        return task.dueDate.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
            task.dueDate.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    // Assignee filter
    if (_selectedAssigneeFilter != null && _selectedAssigneeFilter != 'All') {
      filtered = filtered.where((task) {
        return task.assignedTo == _selectedAssigneeFilter;
      }).toList();
    }

    // Priority filter
    if (_selectedPriorityFilter != null && _selectedPriorityFilter != 'All') {
      filtered = filtered.where((task) {
        final priorityMap = {
          'High': TaskPriority.high,
          'Medium': TaskPriority.medium,
          'Low': TaskPriority.low,
        };
        return task.priority == priorityMap[_selectedPriorityFilter];
      }).toList();
    }

    return filtered;
  }

  // Group tasks by status
  Map<TaskStatus, List<TaskModel>> groupTasksByStatus(List<TaskModel> tasks) {
    final grouped = <TaskStatus, List<TaskModel>>{
      TaskStatus.pending: [],
      TaskStatus.inProgress: [],
      TaskStatus.completed: [],
    };

    for (final task in tasks) {
      // Ensure the status exists in the map before adding
      if (grouped.containsKey(task.status)) {
        grouped[task.status]!.add(task);
      } else {
        // If status doesn't match, add to pending as fallback
        grouped[TaskStatus.pending]!.add(task);
      }
    }

    return grouped;
  }

  void resetFilters() {
    _selectedDueDateFilter = null;
    _selectedAssigneeFilter = 'All';
    _selectedPriorityFilter = 'All';
    _startDate = null;
    _endDate = null;
    _showAdvancedFilters = false;
    notifyListeners();
  }
}

