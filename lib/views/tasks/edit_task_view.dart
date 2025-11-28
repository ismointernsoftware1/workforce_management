import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../components/shadcn/shadcn.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/task_model.dart';
import '../../providers/dashboard_provider.dart';
import '../../utils/responsive_utils.dart';

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
  late final List<TextEditingController> _subTaskControllers;

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
    _selectedPriority = widget.task.priority;
    _selectedAssignedTo = widget.task.assignedTo;
    _subTaskControllers = widget.task.subTasks
        .map((sub) => TextEditingController(text: sub.label))
        .toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var controller in _subTaskControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  void _addSubTaskField() {
    setState(() {
      _subTaskControllers.add(TextEditingController());
    });
  }

  void _removeSubTaskField(int index) {
    setState(() {
      _subTaskControllers[index].dispose();
      _subTaskControllers.removeAt(index);
    });
  }

  Future<void> _updateTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAssignedTo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: ShadAlert(
            title: 'Validation Error',
            description: 'Please select an assignee',
            variant: ShadAlertVariant.destructive,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.all(16),
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
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList()
          .asMap()
          .entries
          .map((entry) {
            // Preserve existing subtask if it matches
            if (entry.key < widget.task.subTasks.length) {
              final existing = widget.task.subTasks[entry.key];
              if (existing.label == entry.value) {
                return existing;
              }
            }
            return SubTask(
              id: entry.key < widget.task.subTasks.length
                  ? widget.task.subTasks[entry.key].id
                  : 'sub-${entry.key}',
              label: entry.value,
              isDone: entry.key < widget.task.subTasks.length
                  ? widget.task.subTasks[entry.key].isDone
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
            content: ShadAlert(
              title: 'Success',
              description: 'Task updated successfully!',
              variant: ShadAlertVariant.success,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.all(16),
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
            content: ShadAlert(
              title: 'Error',
              description: 'Error updating task: ${e.toString()}',
              variant: ShadAlertVariant.destructive,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.all(16),
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
                label: 'Task Title *',
                hintText: 'Enter task title',
                prefixIcon: const Icon(Icons.task_alt, color: AppColors.primary),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a task title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Task Description
              ShadInput(
                controller: _descriptionController,
                label: 'Task Description *',
                hintText: 'Enter task description',
                prefixIcon: const Icon(Icons.description, color: AppColors.primary),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a task description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Due Date
              ShadInput(
                label: 'Due Date *',
                hintText: DateFormat('MM/dd/yyyy').format(_selectedDueDate),
                prefixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
                suffixIcon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                readOnly: true,
                onTap: _selectDueDate,
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Divider
              Divider(
                color: AppColors.border.withValues(alpha: 0.5),
                height: AppSpacing.xl,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Priority Dropdown
              ShadSelect<TaskPriority>(
                value: _selectedPriority,
                label: 'Priority *',
                hint: 'Select priority',
                prefixIcon: const Icon(Icons.flag, color: AppColors.primary),
                items: TaskPriority.values.map((priority) {
                  String label;
                  Color color;
                  switch (priority) {
                    case TaskPriority.high:
                      label = 'High';
                      color = AppColors.danger;
                      break;
                    case TaskPriority.medium:
                      label = 'Medium';
                      color = AppColors.warning;
                      break;
                    case TaskPriority.low:
                      label = 'Low';
                      color = AppColors.success;
                      break;
                  }
                  return ShadSelectItem<TaskPriority>(
                    value: priority,
                    label: label,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(label),
                      ],
                    ),
                  );
                }).toList(),
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
              ShadSelect<String>(
                value: _selectedAssignedTo,
                label: 'Assigned To *',
                hint: 'Select team member',
                prefixIcon: const Icon(Icons.person, color: AppColors.primary),
                items: teamMembers.map((member) {
                  return ShadSelectItem<String>(
                    value: member.name,
                    label: '${member.name} - ${member.role}',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.primarySoft,
                          child: Text(
                            member.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            '${member.name} - ${member.role}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAssignedTo = value ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an assignee';
                  }
                  return null;
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
                  ShadButton(
                    onPressed: _addSubTaskField,
                    variant: ShadButtonVariant.outline,
                    size: ShadButtonSize.sm,
                    icon: const Icon(Icons.add, size: 18),
                    child: const Text('Add Subtask'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              
              // Subtask Fields
              ...List.generate(_subTaskControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: ShadInput(
                          controller: _subTaskControllers[index],
                          hintText: 'Enter subtask ${index + 1}',
                          prefixIcon: const Icon(Icons.check_box_outline_blank, size: 20),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ShadButton(
                        onPressed: () => _removeSubTaskField(index),
                        variant: ShadButtonVariant.ghost,
                        size: ShadButtonSize.icon,
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                        child: const SizedBox.shrink(),
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
              ShadButton(
                onPressed: _isLoading ? null : _updateTask,
                variant: ShadButtonVariant.default_,
                size: ShadButtonSize.lg,
                width: double.infinity,
                disabled: _isLoading,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
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

