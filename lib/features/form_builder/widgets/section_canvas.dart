import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../widgets/shadcn/app_button.dart';
import '../../../widgets/shadcn/app_card.dart';
import '../../form_builder/controllers/form_builder_controller.dart';
import '../../form_builder/models/form_models.dart';

class SectionCanvas extends StatelessWidget {
  const SectionCanvas({
    super.key,
    required this.controller,
    required this.onAddFieldFromType,
  });

  final FormBuilderController controller;
  final void Function(FormFieldType type, String sectionId) onAddFieldFromType;

  @override
  Widget build(BuildContext context) {
    final form = controller.activeForm;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            controller: controller,
          ),
          const Divider(height: 1),
          Expanded(
            child: Container(
              color: const Color(0xFFF9FAFB), // Soft grey background
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      ...form?.sections.map((section) {
                            return _SectionCard(
                              key: ValueKey(section.id), // Force rebuild when section changes
                              section: section,
                              controller: controller,
                              onAddFieldFromType: (type) =>
                                  onAddFieldFromType(type, section.id),
                            );
                          }).toList() ??
                          <Widget>[],
                      _AddSectionCard(onTap: controller.addSection),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatefulWidget {
  const _Header({required this.controller});
  final FormBuilderController controller;

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  late TextEditingController _nameController;
  bool _isUserTyping = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.controller.activeForm?.name ?? '',
    );
    widget.controller.addListener(_updateName);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateName);
    _nameController.dispose();
    super.dispose();
  }

  void _updateName() {
    // Only update if user is not currently typing
    if (!_isUserTyping) {
      final currentName = widget.controller.activeForm?.name ?? '';
      if (_nameController.text != currentName) {
        _nameController.text = currentName;
      }
    }
  }

  Future<void> _saveForm() async {
    // Update form name before saving
    widget.controller.setFormName(_nameController.text.trim().isEmpty
        ? 'Untitled Form'
        : _nameController.text.trim());
    
    try {
      await widget.controller.saveFormToFirestore();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Form saved successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving form: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deleteForm(BuildContext context) async {
    final form = widget.controller.activeForm;
    if (form == null || form.id.isEmpty) return;

    final isDefault = widget.controller.isDefaultForm(form.name);
    final formName = form.name;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDefault ? 'Delete Default Form?' : 'Delete Form?'),
        content: Text(
          isDefault
              ? 'You are about to delete "$formName". This is a default form used by the application. Are you sure you want to continue?\n\nNote: This may affect the "Add Task" or "Add Expense" pages.'
              : 'Are you sure you want to delete "$formName"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await widget.controller.deleteForm(form.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Form "$formName" deleted successfully'
                  : 'Error deleting form',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: ShadInput(
              controller: _nameController,
              placeholder: const Text('Untitled Form'),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
              onChanged: (value) {
                // Mark that user is typing to prevent overwriting
                _isUserTyping = true;
                // Update form name in real-time as user types
                widget.controller.setFormName(value.trim().isEmpty
                    ? 'Untitled Form'
                    : value.trim());
              },
              onSubmitted: (value) {
                // User finished typing
                _isUserTyping = false;
                // Also update on submit for consistency
                widget.controller.setFormName(value.trim().isEmpty
                    ? 'Untitled Form'
                    : value.trim());
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppButton(
            variant: AppButtonVariant.outline,
            icon: Icons.add,
            label: 'Add Section',
            onPressed: widget.controller.addSection,
          ),
          const SizedBox(width: AppSpacing.sm),
          // Delete button (only show if form is saved)
          if (widget.controller.activeForm?.id.isNotEmpty == true)
            AppButton(
              variant: AppButtonVariant.ghost,
              icon: Icons.delete_outline,
              onPressed: () => _deleteForm(context),
            ),
          const SizedBox(width: AppSpacing.sm),
          AppButton(
            variant: AppButtonVariant.primary,
            icon: Icons.save_outlined,
            label: widget.controller.isSaving ? 'Saving...' : 'Save Form',
            isLoading: widget.controller.isSaving,
            onPressed: widget.controller.isSaving ? null : _saveForm,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatefulWidget {
  const _SectionCard({
    super.key,
    required this.section,
    required this.controller,
    required this.onAddFieldFromType,
  });

  final FormSectionModel section;
  final FormBuilderController controller;
  final void Function(FormFieldType type) onAddFieldFromType;

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  late TextEditingController _titleController;
  bool _isUserTyping = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.section.title);
    widget.controller.addListener(_updateTitle);
  }

  @override
  void didUpdateWidget(_SectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If section changed (different section selected), update controller
    if (oldWidget.section.id != widget.section.id) {
      _titleController.dispose();
      _titleController = TextEditingController(text: widget.section.title);
      _isUserTyping = false;
    } else {
      // Same section, but title might have changed externally
      _updateTitle();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateTitle);
    _titleController.dispose();
    super.dispose();
  }

  void _updateTitle() {
    // Only update if user is not currently typing
    if (!_isUserTyping) {
      final currentTitle = widget.section.title;
      if (_titleController.text != currentTitle) {
        _titleController.text = currentTitle;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<FormFieldType>(
      onAcceptWithDetails: (details) {
        widget.onAddFieldFromType(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return SizedBox(
          width: 1000, // Wider section to allow horizontal field layout
          child: AppCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(AppSpacing.md),
            backgroundColor: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            showShadow: true,
            border: Border.all(
              color: (candidateData.isNotEmpty
                      ? AppColors.primary
                      : AppColors.border)
                  .withValues(alpha: 0.5),
              width: 1,
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ShadInput(
                      controller: _titleController,
                      placeholder: const Text('Untitled Section'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      onChanged: (value) {
                        // Mark that user is typing to prevent overwriting
                        _isUserTyping = true;
                        // Update section title in real-time as user types
                        widget.controller.updateSectionTitle(
                          widget.section.id,
                          value.trim().isEmpty ? 'Untitled Section' : value.trim(),
                        );
                      },
                      onSubmitted: (value) {
                        // User finished typing
                        _isUserTyping = false;
                        widget.controller.updateSectionTitle(
                          widget.section.id,
                          value.trim().isEmpty ? 'Untitled Section' : value.trim(),
                        );
                      },
                    ),
                  ),
                  AppButton(
                    variant: AppButtonVariant.ghost,
                    icon: Icons.delete_outline,
                    onPressed: () => widget.controller.deleteSection(widget.section.id),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Fields arranged in a Wrap to allow both horizontal and vertical layout
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  // Drop zone before first field (full width for vertical placement)
                  if (widget.section.fields.isEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: _DropZone(
                        onAccept: (type) {
                          widget.controller.addField(
                            type,
                            sectionId: widget.section.id,
                            insertIndex: 0,
                          );
                        },
                        isVertical: true,
                      ),
                    ),
                  // Fields with drop zones for both horizontal and vertical placement
                  ...widget.section.fields.asMap().entries.expand((entry) {
                    final index = entry.key;
                    final field = entry.value;
                    final isLastInRow = (index + 1) % 2 == 0 || index == widget.section.fields.length - 1;
                    return [
                      // Drop zone above field (full width for vertical placement)
                      SizedBox(
                        width: double.infinity,
                        child: _DropZone(
                          onAccept: (type) {
                            widget.controller.addField(
                              type,
                              sectionId: widget.section.id,
                              insertIndex: index,
                            );
                          },
                          isVertical: true,
                        ),
                      ),
                      // Field tile (flexible width - can be half or full)
                      SizedBox(
                        width: 480, // Half width for horizontal, will expand if alone
                        child: _FieldPreviewTile(
                          field: field,
                          selected: widget.controller.selectedField?.id == field.id,
                          onTap: () => widget.controller.selectField(field, widget.section),
                          onDelete: () =>
                              widget.controller.deleteField(widget.section.id, field.id),
                          sectionId: widget.section.id,
                          controller: widget.controller,
                        ),
                      ),
                      // Drop zone to the right (for horizontal placement)
                      SizedBox(
                        width: 480,
                        child: _DropZone(
                          onAccept: (type) {
                            widget.controller.addField(
                              type,
                              sectionId: widget.section.id,
                              insertIndex: index + 1,
                            );
                          },
                          isVertical: false,
                        ),
                      ),
                      // Drop zone below field (full width for vertical placement)
                      if (isLastInRow)
                        SizedBox(
                          width: double.infinity,
                          child: _DropZone(
                            onAccept: (type) {
                              widget.controller.addField(
                                type,
                                sectionId: widget.section.id,
                                insertIndex: index + 1,
                              );
                            },
                            isVertical: true,
                          ),
                        ),
                    ];
                  }).toList(),
                ],
              ),
              // Empty section drop zone (only show if no fields)
              if (widget.section.fields.isEmpty)
                DragTarget<FormFieldType>(
                  onAcceptWithDetails: (details) {
                    widget.controller.addField(
                      details.data,
                      sectionId: widget.section.id,
                    );
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      height: 88,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: candidateData.isNotEmpty
                            ? AppColors.primarySoft
                            : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: candidateData.isNotEmpty
                              ? AppColors.primary
                              : AppColors.border.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        candidateData.isNotEmpty ? 'Drop field here' : 'Drop here',
                        style: TextStyle(
                          color: candidateData.isNotEmpty
                              ? AppColors.primary
                              : AppColors.textMuted,
                          fontWeight: candidateData.isNotEmpty
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      );
      },
    );
  }
}

class _AddSectionCard extends StatelessWidget {
  const _AddSectionCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 560,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        backgroundColor: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        showShadow: true,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
          width: 1,
        ),
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppColors.primary, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Add Section',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropZone extends StatelessWidget {
  const _DropZone({
    required this.onAccept,
    this.isVertical = false,
  });

  final void Function(FormFieldType) onAccept;
  final bool isVertical; // true for vertical placement, false for horizontal

  @override
  Widget build(BuildContext context) {
    return DragTarget<FormFieldType>(
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final isActive = candidateData.isNotEmpty;
        return Container(
          height: isVertical ? (isActive ? 60 : 40) : (isActive ? 80 : 60),
          margin: EdgeInsets.symmetric(
            vertical: AppSpacing.xs,
            horizontal: isVertical ? 0 : AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primarySoft
                : AppColors.surfaceAlt.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? AppColors.primary
                  : AppColors.border.withValues(alpha: 0.3),
              width: isActive ? 2 : 1,
              style: isActive ? BorderStyle.solid : BorderStyle.solid,
            ),
          ),
          alignment: Alignment.center,
          child: isActive
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVertical ? Icons.arrow_downward : Icons.arrow_forward,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isVertical ? 'Drop below' : 'Drop beside',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }
}

class _FieldPreviewTile extends StatelessWidget {
  const _FieldPreviewTile({
    required this.field,
    required this.selected,
    required this.onTap,
    required this.onDelete,
    required this.sectionId,
    required this.controller,
  });

  final FormFieldModel field;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final String sectionId;
  final FormBuilderController controller;

  @override
  Widget build(BuildContext context) {
    final tile = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (selected ? AppColors.primary : AppColors.border)
                  .withValues(alpha: selected ? 1.0 : 0.5),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(_iconFor(field.type), size: 16, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  field.label.isEmpty ? 'Untitled Field' : field.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.close,
                    size: 16, color: AppColors.danger),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );

    // Make field draggable for reordering
    return LongPressDraggable<FormFieldModel>(
      data: field,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.8,
          child: tile,
        ),
      ),
      child: tile,
      onDragEnd: (details) {
        // Handle drag end if needed
      },
    );
  }

  IconData _iconFor(FormFieldType t) {
    switch (t) {
      case FormFieldType.text:
        return Icons.text_fields;
      case FormFieldType.number:
        return Icons.pin;
      case FormFieldType.email:
        return Icons.alternate_email;
      case FormFieldType.dropdown:
        return Icons.arrow_drop_down_circle_outlined;
      case FormFieldType.checkbox:
        return Icons.check_box_outlined;
      case FormFieldType.radio:
        return Icons.radio_button_checked_outlined;
      case FormFieldType.date:
        return Icons.event;
      case FormFieldType.textarea:
        return Icons.notes;
      case FormFieldType.fileUpload:
        return Icons.upload_file;
      case FormFieldType.sectionTitle:
        return Icons.title;
      case FormFieldType.divider:
        return Icons.horizontal_rule;
    }
  }
}


