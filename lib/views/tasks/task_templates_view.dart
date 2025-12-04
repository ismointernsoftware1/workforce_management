import 'package:flutter/material.dart';

import 'package:shadcn_ui/shadcn_ui.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../widgets/shadcn/shadcn_widgets.dart';
import '../../models/task_model.dart';
import '../../models/task_template.dart';
import 'add_task_view.dart';

class TaskTemplatesView extends StatelessWidget {
  const TaskTemplatesView({super.key});

  // Sample templates - in production, these would come from Firestore
  static final List<TaskTemplate> _templates = [
    TaskTemplate(
      id: 'template-1',
      name: 'Project Kickoff',
      description: 'Standard template for starting a new project',
      priority: TaskPriority.high,
      dueDateDays: 14,
      defaultSubtasks: [
        'Define project scope',
        'Identify stakeholders',
        'Set up project timeline',
        'Create initial documentation',
      ],
      requiresApproval: true,
    ),
    TaskTemplate(
      id: 'template-2',
      name: 'Client Meeting',
      description: 'Template for preparing and conducting client meetings',
      priority: TaskPriority.medium,
      dueDateDays: 7,
      defaultSubtasks: [
        'Prepare agenda',
        'Review previous notes',
        'Prepare presentation',
        'Send meeting invite',
      ],
      requiresLocation: true,
    ),
    TaskTemplate(
      id: 'template-3',
      name: 'Bug Fix',
      description: 'Template for tracking and fixing bugs',
      priority: TaskPriority.high,
      dueDateDays: 3,
      defaultSubtasks: [
        'Reproduce bug',
        'Identify root cause',
        'Implement fix',
        'Test fix',
        'Deploy fix',
      ],
    ),
    TaskTemplate(
      id: 'template-4',
      name: 'Content Review',
      description: 'Template for reviewing and approving content',
      priority: TaskPriority.medium,
      dueDateDays: 5,
      defaultSubtasks: [
        'Initial review',
        'Request changes if needed',
        'Final approval',
      ],
      requiresApproval: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Task Templates',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: AppColors.background,
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.xl),
        itemCount: _templates.length,
        itemBuilder: (context, index) {
          final template = _templates[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _TemplateCard(template: template),
          );
        },
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template});

  final TaskTemplate template;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      template.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              ShadBadge(
                child: Text(template.priority.name.toUpperCase()),
              ),
            ],
          ),
          if (template.defaultSubtasks.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Default Subtasks:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...template.defaultSubtasks.map((subtask) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(Icons.check_box_outline_blank,
                        size: 16, color: AppColors.textMuted),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        subtask,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              if (template.requiresApproval)
                ShadBadge(
                  child: const Text('Requires Approval'),
                ),
              if (template.requiresLocation)
                ShadBadge(
                  child: const Text('Requires Location'),
                ),
              if (template.dueDateDays != null)
                ShadBadge(
                  child: Text('Due in ${template.dueDateDays} days'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            onPressed: () => _useTemplate(context),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 18),
                SizedBox(width: 4),
                Text('Use Template'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _useTemplate(BuildContext context) {
    // Navigate to add task view with template pre-filled
    // For now, just navigate to add task view
    // In production, you'd pass the template to pre-fill the form
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddTaskView(),
      ),
    );
  }
}

