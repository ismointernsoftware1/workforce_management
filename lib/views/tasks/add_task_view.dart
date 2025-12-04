import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/shadcn/shadcn.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/task_attachment.dart';
import '../../models/task_model.dart';
import '../../features/form_builder/models/form_models.dart';
import '../../features/form_builder/services/form_builder_firestore_service.dart';
import '../../features/form_builder/services/default_forms_initializer.dart';
import '../../features/form_builder/widgets/enhanced_form_renderer.dart';
import '../../providers/dashboard_provider.dart';
import '../../utils/responsive_utils.dart';
import '../widgets/attachment_picker.dart';

class AddTaskView extends StatefulWidget {
  const AddTaskView({super.key});

  @override
  State<AddTaskView> createState() => _AddTaskViewState();
}

class _AddTaskViewState extends State<AddTaskView> {
  final _formKey = GlobalKey<FormState>();
  final _subTaskControllers = <TextEditingController>[];
  final _subTaskDoneStates = <bool>[];

  bool _isLoading = false;
  bool _isLoadingForm = true;
  List<TaskAttachment> _attachments = [];
  final _formService = FormBuilderFirestoreService();
  final _formInitializer = DefaultFormsInitializer(FormBuilderFirestoreService());
  FormModel? _defaultTaskForm;
  Map<String, dynamic> _formValues = {};

  @override
  void initState() {
    super.initState();
    _loadDefaultForm();
  }

  Future<void> _loadDefaultForm() async {
    try {
      // Initialize default forms if they don't exist
      await _formInitializer.initializeDefaultForms();
      
      // Load the default "Add Task Form"
      final formId = await _formInitializer.getDefaultFormId('Add Task Form');
      if (formId != null) {
        final form = await _formService.getForm(formId);
        if (mounted && form != null) {
          setState(() {
            _defaultTaskForm = form;
            _isLoadingForm = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingForm = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingForm = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _subTaskControllers) {
      controller.dispose();
    }
    super.dispose();
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

  // Helper to extract value from form by field label
  String? _getFormValue(String label) {
    if (_defaultTaskForm == null) return null;
    for (final section in _defaultTaskForm!.sections) {
      for (final field in section.fields) {
        if (field.label == label) {
          final value = _formValues[field.id];
          if (value is Set<String>) {
            // For checkbox fields, return comma-separated string
            return value.join(', ');
          }
          return value?.toString();
        }
      }
    }
    return null;
  }

  // Helper to extract list of values from form by field label (for multiple selections)
  List<String> _getFormValueList(String label) {
    if (_defaultTaskForm == null) return [];
    for (final section in _defaultTaskForm!.sections) {
      for (final field in section.fields) {
        if (field.label == label) {
          final value = _formValues[field.id];
          if (value is Set<String>) {
            return value.toList();
          } else if (value is List) {
            return value.map((e) => e.toString()).toList();
          } else if (value is String && value.isNotEmpty) {
            // Handle comma-separated string
            return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          }
          return [];
        }
      }
    }
    return [];
  }

  DateTime? _getFormDateValue(String label) {
    if (_defaultTaskForm == null) return null;
    for (final section in _defaultTaskForm!.sections) {
      for (final field in section.fields) {
        if (field.label == label) {
          return _formValues[field.id] as DateTime?;
        }
      }
    }
    return null;
  }

  TaskPriority _parsePriority(String? priorityStr) {
    if (priorityStr == null) return TaskPriority.medium;
    switch (priorityStr.toLowerCase()) {
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }

  TaskStatus _parseStatus(String? statusStr) {
    if (statusStr == null) return TaskStatus.pending;
    final status = statusStr.toLowerCase().replaceAll(' ', '');
    switch (status) {
      case 'inprogress':
      case 'in-progress':
      case 'in progress':
        return TaskStatus.inProgress;
      case 'completed':
      case 'done':
        return TaskStatus.completed;
      case 'pending':
      default:
        return TaskStatus.pending;
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Extract values from form
    final title = _getFormValue('Task Title') ?? '';
    final description = _getFormValue('Task Description') ?? '';
    final dueDate = _getFormDateValue('Due Date');
    final priorityStr = _getFormValue('Priority');
    final assignedToUsers = _getFormValueList('Assigned To');
    final assignedTo = assignedToUsers.isNotEmpty 
        ? assignedToUsers.join(', ') 
        : _getFormValue('Assigned To') ?? '';
    final statusStr = _getFormValue('Status');

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: ShadAlert(
            title: 'Validation Error',
            description: 'Please enter a task title',
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

    if (dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: ShadAlert(
            title: 'Validation Error',
            description: 'Please select a due date',
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

    if (assignedToUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: ShadAlert(
            title: 'Validation Error',
            description: 'Please select at least one assignee',
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
          .asMap()
          .entries
          .where((entry) => entry.value.text.trim().isNotEmpty)
          .map((entry) {
            final index = entry.key;
            return SubTask(
              id: 'sub-$index',
              label: entry.value.text.trim(),
              isDone: index < _subTaskDoneStates.length 
                  ? _subTaskDoneStates[index] 
                  : false,
            );
          })
          .toList();

      // Snapshot form definition and values
      String? formId;
      Map<String, dynamic>? formDefinition;
      Map<String, dynamic>? formValues;
      if (_defaultTaskForm != null) {
        formId = _defaultTaskForm!.id;
        formDefinition = {
          'id': _defaultTaskForm!.id,
          'name': _defaultTaskForm!.name,
          'sections':
              _defaultTaskForm!.sections.map((s) => s.toMap()).toList(),
        };
        formValues = Map<String, dynamic>.from(_formValues);
      }

      // Create task model
      final task = TaskModel(
        id: '', // Will be generated by Firestore
        title: title,
        description: description,
        priority: _parsePriority(priorityStr),
        dueDate: dueDate,
        assignedTo: assignedTo, // For backward compatibility
        assignedToUsers: assignedToUsers, // New field for multiple users
        status: _parseStatus(statusStr),
        subTasks: subTasks,
        attachments: _attachments,
        formId: formId,
        formDefinition: formDefinition,
        formValues: formValues,
      );

      // Add task through provider
      await provider.addTask(task);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ShadAlert(
              title: 'Success',
              description: 'Task added successfully!',
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
              description: 'Error adding task: ${e.toString()}',
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

  Widget _buildSection({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title and Subtitle
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // Section Fields
        ...children,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final teamMembers = provider.members;

    // Build dynamic options map for dropdowns
    final dynamicOptions = <String, List<String>>{};
    if (_defaultTaskForm != null) {
      for (final section in _defaultTaskForm!.sections) {
        for (final field in section.fields) {
          if (field.label == 'Assigned To') {
            // Populate with team members
            dynamicOptions[field.id] = teamMembers
                .map((m) => '${m.name} - ${m.role}')
                .toList();
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add New Task',
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
      body: _isLoadingForm
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: ResponsiveUtils.getPadding(context),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dynamic Form from Firebase
                        if (_defaultTaskForm != null) ...[
                          EnhancedFormRenderer(
                            form: _defaultTaskForm!,
                            dynamicOptions: dynamicOptions,
                            onChanged: (values) {
                              setState(() {
                                _formValues = values;
                              });
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ] else ...[
                          // Fallback if form not loaded
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Text(
                                'Form template not available. Please create "Add Task Form" in Form Builder.',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],

              // Task Details Section
              _buildSection(
                title: 'Task Details',
                subtitle: 'Essential attachment information.',
                children: [
                  AttachmentPicker(
                    attachments: _attachments,
                    onAttachmentsChanged: (attachments) {
                      setState(() {
                        _attachments = attachments;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Subtasks Section
              _buildSection(
                title: 'Subtasks',
                subtitle: 'Break down your task into smaller steps.',
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ShadButton(
                        onPressed: _addSubTaskField,
                        variant: ShadButtonVariant.outline,
                        size: ShadButtonSize.sm,
                        icon: const Icon(Icons.add, size: 18),
                        child: const Text('Add Subtask'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                              decoration: BoxDecoration(
                                border: isDone
                                    ? Border.all(color: AppColors.primary, width: 2)
                                    : Border.all(color: AppColors.border, width: 1),
                                borderRadius: BorderRadius.circular(4),
                              ),
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
                              hintText: 'Enter subtask ${index + 1}',
                              enabled: !isDone,
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
                  if (_subTaskControllers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Text(
                        'No subtasks added yet. Click "Add Subtask" to create one.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Save Button
              ShadButton(
                onPressed: _isLoading ? null : _saveTask,
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
                        'Add Task',
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
    ),
  ),
);
  }
}

