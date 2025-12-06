import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../widgets/shadcn/app_button.dart';
import '../../../widgets/shadcn/app_card.dart';
import '../../form_builder/controllers/form_builder_controller.dart';
import '../../form_builder/models/form_models.dart';

class PropertiesPanel extends StatelessWidget {
  const PropertiesPanel({super.key, required this.controller});

  final FormBuilderController controller;

  @override
  Widget build(BuildContext context) {
    final field = controller.selectedField;
    final section = controller.selectedSection;

    return Container(
      width: 320,
      color: const Color(0xFFF9FAFB), // Soft grey background
      child: AppCard(
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        backgroundColor: AppColors.surface,
        borderRadius: BorderRadius.zero,
        showShadow: false,
        border: Border(
          left: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Properties',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: field != null
                      ? _FieldProperties(
                          key: ValueKey(field.id), // Force rebuild when field changes
                          controller: controller,
                          field: field,
                        )
                      : section != null
                          ? _SectionProperties(
                              controller: controller,
                              section: section,
                            )
                          : Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Text(
                                  'Select a field or section',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldProperties extends StatefulWidget {
  const _FieldProperties({
    super.key,
    required this.controller,
    required this.field,
  });
  final FormBuilderController controller;
  final FormFieldModel field;

  @override
  State<_FieldProperties> createState() => _FieldPropertiesState();
}

class _FieldPropertiesState extends State<_FieldProperties> {
  late TextEditingController _labelCtrl;
  late TextEditingController _placeholderCtrl;
  late TextEditingController _helpCtrl;
  late bool _required;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _labelCtrl = TextEditingController(text: widget.field.label);
    _placeholderCtrl = TextEditingController(text: widget.field.placeholder);
    _helpCtrl = TextEditingController(text: widget.field.helpText);
    _required = widget.field.required;
  }

  @override
  void didUpdateWidget(_FieldProperties oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If field changed (different field selected), update controllers
    if (oldWidget.field.id != widget.field.id) {
      _labelCtrl.dispose();
      _placeholderCtrl.dispose();
      _helpCtrl.dispose();
      _initializeControllers();
    } else {
      // Same field, but data might have changed externally
      if (_labelCtrl.text != widget.field.label) {
        _labelCtrl.text = widget.field.label;
      }
      if (_placeholderCtrl.text != widget.field.placeholder) {
        _placeholderCtrl.text = widget.field.placeholder;
      }
      if (_helpCtrl.text != widget.field.helpText) {
        _helpCtrl.text = widget.field.helpText;
      }
      if (_required != widget.field.required) {
        setState(() {
          _required = widget.field.required;
        });
      }
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _placeholderCtrl.dispose();
    _helpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOptions =
        widget.field.type == FormFieldType.dropdown ||
            widget.field.type == FormFieldType.radio ||
            widget.field.type == FormFieldType.checkbox;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabeledField(
            label: 'Label',
            child: ShadInput(
              controller: _labelCtrl,
              onChanged: (v) =>
                  widget.controller.updateField(widget.field, (f) {
                f.label = v;
              }),
            ),
          ),
          _LabeledField(
            label: 'Placeholder',
            child: ShadInput(
              controller: _placeholderCtrl,
              onChanged: (v) =>
                  widget.controller.updateField(widget.field, (f) {
                f.placeholder = v;
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                Text(
                  'Required',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                ShadSwitch(
                  value: _required,
                  onChanged: (v) {
                    setState(() => _required = v);
                    widget.controller.updateField(widget.field, (f) {
                      f.required = v;
                    });
                  },
                ),
              ],
            ),
          ),
          _LabeledField(
            label: 'Help text',
            child: ShadInput(
              controller: _helpCtrl,
              minLines: 2,
              maxLines: 3,
              onChanged: (v) =>
                  widget.controller.updateField(widget.field, (f) {
                f.helpText = v;
              }),
            ),
          ),
          if (isOptions) ...[
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Options',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.field.options.length,
              onReorder: (o, n) =>
                  widget.controller.reorderOptions(widget.field, o, n),
              itemBuilder: (context, index) {
                final option = widget.field.options[index];
                return Container(
                  key: ValueKey(option + index.toString()),
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.drag_indicator,
                          size: 16, color: AppColors.textMuted),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: ShadInput(
                          controller: TextEditingController(text: option)
                            ..selection = TextSelection.fromPosition(
                              TextPosition(offset: option.length),
                            ),
                          onChanged: (v) {
                            widget.controller.updateField(widget.field, (f) {
                              if (index < f.options.length) {
                                f.options[index] = v;
                              }
                            });
                          },
                          onSubmitted: (v) {
                            widget.controller.updateField(widget.field, (f) {
                              if (index < f.options.length) {
                                f.options[index] = v;
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      IconButton(
                        onPressed: () {
                          widget.controller.updateField(widget.field, (f) {
                            f.options.removeAt(index);
                          });
                        },
                        icon: const Icon(Icons.close,
                            size: 16, color: AppColors.danger),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              variant: AppButtonVariant.outline,
              icon: Icons.add,
              label: 'Add option',
              onPressed: () {
                widget.controller.updateField(widget.field, (f) {
                  f.options.add('Option ${f.options.length + 1}');
                });
              },
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            variant: AppButtonVariant.destructive,
            icon: Icons.delete_outline,
            label: 'Delete field',
            onPressed: () {
              final sectionId = widget.controller.selectedSection?.id;
              if (sectionId != null) {
                widget.controller.deleteField(sectionId, widget.field.id);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SectionProperties extends StatelessWidget {
  const _SectionProperties({required this.controller, required this.section});
  final FormBuilderController controller;
  final FormSectionModel section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LabeledField(
          label: 'Section label',
          child: ShadInput(
            controller: TextEditingController(text: section.title),
            onSubmitted: (v) => controller.updateSectionTitle(section.id, v),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          variant: AppButtonVariant.destructive,
          icon: Icons.delete_outline,
          label: 'Delete section',
          onPressed: () => controller.deleteSection(section.id),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}


