import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:shadcn_ui/shadcn_ui.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/task_model.dart';
import '../../providers/dashboard_provider.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/shadcn/shadcn_widgets.dart';

class EditTaskView extends StatefulWidget {
  const EditTaskView({super.key, required this.task});

  final TaskModel task;

  @override
  State<EditTaskView> createState() => _EditTaskViewState();
}

class _EditTaskViewState extends State<EditTaskView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _dueDateController;
  late final List<TextEditingController> _subTaskControllers;
  late final List<bool> _subTaskDoneStates;

  late DateTime _selectedDueDate;
  late TaskPriority _selectedPriority;
  late String _selectedAssignedTo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
    _selectedDueDate = widget.task.dueDate;
    _dueDateController = TextEditingController(
      text: DateFormat('MM/dd/yyyy').format(_selectedDueDate),
    );
    _selectedPriority = widget.task.priority;
    // Extract name from "name - role" format or use as-is
    _selectedAssignedTo = widget.task.assignedTo;
    _subTaskControllers = widget.task.subTasks
        .map((sub) => TextEditingController(text: sub.label))
        .toList();
    _subTaskDoneStates = widget.task.subTasks
        .map((sub) => sub.isDone)
        .toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dueDateController.dispose();
    for (var controller in _subTaskControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
        _dueDateController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  void _addSubTaskField() {
    setState(() {
      _subTaskControllers.add(TextEditingController());
      _subTaskDoneStates.add(false);
    });
  }

  void _removeSubTaskField(int index) {
    setState(() {
      _subTaskControllers[index].dispose();
      _subTaskControllers.removeAt(index);
      _subTaskDoneStates.removeAt(index);
    });
  }

  void _toggleSubTaskDone(int index) {
    setState(() {
      _subTaskDoneStates[index] = !_subTaskDoneStates[index];
    });
  }


  Future<void> _updateTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAssignedTo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an assignee'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<DashboardProvider>();
      
      // Build subtasks list
      final subTasks = _subTaskControllers
          .asMap()
          .entries
          .where((entry) => entry.value.text.trim().isNotEmpty)
          .map((entry) {
            final index = entry.key;
            final label = entry.value.text.trim();
            // Preserve existing subtask ID if it matches
            final existingId = index < widget.task.subTasks.length
                ? widget.task.subTasks[index].id
                : 'sub-$index';
            return SubTask(
              id: existingId,
              label: label,
              isDone: index < _subTaskDoneStates.length
                  ? _subTaskDoneStates[index]
                  : false,
            );
          })
          .toList();

      // Update task model
      final updatedTask = widget.task.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        dueDate: _selectedDueDate,
        assignedTo: _selectedAssignedTo,
        subTasks: subTasks,
      );

      // Update task through provider
      await provider.updateTask(updatedTask);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Task updated successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating task: ${e.toString()}'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final teamMembers = provider.members;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Task',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.border.withValues(alpha: 0.5),
          ),
        ),
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: ResponsiveUtils.getPadding(context),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit task',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Update task details below',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl + AppSpacing.md),
              // Task Title
              ShadInput(
                controller: _titleController,
                placeholder: const Text('Enter task title'),
                leading: const Icon(Icons.task_alt, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Task Description
              ShadInput(
                controller: _descriptionController,
                placeholder: const Text('Enter task description'),
                leading: const Icon(Icons.description, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Due Date
              GestureDetector(
                onTap: _selectDueDate,
                child: ShadInput(
                  placeholder: const Text('Select due date'),
                  leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                  readOnly: true,
                  controller: _dueDateController,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Divider
              Divider(
                color: AppColors.border.withValues(alpha: 0.5),
                height: AppSpacing.xl,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Priority Dropdown
              AppSelect<TaskPriority>(
                placeholder: 'Select priority',
                value: _selectedPriority,
                options: TaskPriority.values.map((priority) {
                  String label;
                  switch (priority) {
                    case TaskPriority.high:
                      label = 'High';
                      break;
                    case TaskPriority.medium:
                      label = 'Medium';
                      break;
                    case TaskPriority.low:
                      label = 'Low';
                      break;
                  }
                  return SelectOption<TaskPriority>(
                    value: priority,
                    label: label,
                  );
                }).toList(),
                selectedOptionBuilder: (context, value) {
                  String label;
                  switch (value) {
                    case TaskPriority.high:
                      label = 'High';
                      break;
                    case TaskPriority.medium:
                      label = 'Medium';
                      break;
                    case TaskPriority.low:
                      label = 'Low';
                      break;
                    case null:
                      return const Text('Select priority');
                  }
                  return Text(label);
                },
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPriority = value;
                    });
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Assigned To Dropdown
              AppSelect<String>(
                placeholder: 'Select team member',
                value: _selectedAssignedTo.isEmpty ? null : _selectedAssignedTo,
                options: teamMembers.map((member) {
                  final displayValue = '${member.name} - ${member.role}';
                  return SelectOption<String>(
                    value: displayValue,
                    label: displayValue,
                  );
                }).toList(),
                selectedOptionBuilder: (context, value) {
                  return Text(value ?? 'Select team member');
                },
                onChanged: (value) {
                  setState(() {
                    _selectedAssignedTo = value ?? '';
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Divider
              Divider(
                color: AppColors.border.withValues(alpha: 0.5),
                height: AppSpacing.xl,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Subtasks Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subtasks',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Break down your task into smaller steps',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  AppButton(
                    variant: AppButtonVariant.outline,
                    onPressed: _addSubTaskField,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 18),
                        SizedBox(width: 4),
                        Text('Add Subtask'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              
              // Subtask Fields
              ...List.generate(_subTaskControllers.length, (index) {
                final isDone = index < _subTaskDoneStates.length 
                    ? _subTaskDoneStates[index] 
                    : false;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => _toggleSubTaskDone(index),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            isDone ? Icons.check_box : Icons.check_box_outline_blank,
                            size: 20,
                            color: isDone ? AppColors.primary : AppColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: ShadInput(
                          controller: _subTaskControllers[index],
                          placeholder: Text('Enter subtask ${index + 1}'),
                          enabled: !isDone,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ShadIconButton(
                        onPressed: () => _removeSubTaskField(index),
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: AppSpacing.xl),
              
              // Divider before action button
              Divider(
                color: AppColors.border.withValues(alpha: 0.5),
                height: AppSpacing.xl,
              ),
              const SizedBox(height: AppSpacing.md),

              // Update Button
              AppButton(
                onPressed: _isLoading ? null : _updateTask,
                fullWidth: true,
                isLoading: _isLoading,
                child: const Text(
                  'Update Task',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

