import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../components/shadcn/shadcn.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../models/form_models.dart';

/// Enhanced form renderer that supports dynamic dropdown options
/// and better integration with ShadCN components.
class EnhancedFormRenderer extends StatefulWidget {
  const EnhancedFormRenderer({
    super.key,
    required this.form,
    this.initialValues = const <String, dynamic>{},
    this.dynamicOptions = const <String, List<String>>{},
    required this.onChanged,
  });

  final FormModel form;
  final Map<String, dynamic> initialValues;
  final Map<String, List<String>> dynamicOptions; // fieldId -> options
  final void Function(Map<String, dynamic> values) onChanged;

  @override
  State<EnhancedFormRenderer> createState() => _EnhancedFormRendererState();
}

class _EnhancedFormRendererState extends State<EnhancedFormRenderer> {
  late Map<String, dynamic> _values;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _values = Map<String, dynamic>.from(widget.initialValues);
    // Initialize controllers for text fields
    for (final section in widget.form.sections) {
      for (final field in section.fields) {
        if (_needsController(field.type)) {
          _controllers[field.id] = TextEditingController(
            text: _values[field.id]?.toString() ?? '',
          );
        }
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _needsController(FormFieldType type) {
    return type == FormFieldType.text ||
        type == FormFieldType.email ||
        type == FormFieldType.number ||
        type == FormFieldType.textarea;
  }

  void _update(String fieldId, dynamic value) {
    _values[fieldId] = value;
    widget.onChanged(_values);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.form.sections.map((section) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Group fields related to ${section.title.toLowerCase()}.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ...section.fields.map((field) {
                final value = _values[field.id];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: _buildField(field, value, (v) => _update(field.id, v)),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildField(
    FormFieldModel field,
    dynamic value,
    void Function(dynamic) onChanged,
  ) {
    // Get dynamic options if available
    final options = widget.dynamicOptions[field.id] ?? field.options;

    switch (field.type) {
      case FormFieldType.text:
      case FormFieldType.email:
        return ShadInput(
          controller: _controllers[field.id],
          label: field.label + (field.required ? ' *' : ''),
          hintText: field.placeholder,
          prefixIcon: Icon(
            field.type == FormFieldType.email
                ? Icons.email
                : Icons.text_fields,
            color: AppColors.primary,
          ),
          validator: field.required
              ? (v) => v?.isEmpty ?? true ? 'This field is required' : null
              : null,
          onChanged: (v) => onChanged(v),
        );
      case FormFieldType.number:
        return ShadInput(
          controller: _controllers[field.id],
          label: field.label + (field.required ? ' *' : ''),
          hintText: field.placeholder,
          prefixIcon: const Icon(Icons.numbers, color: AppColors.primary),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: field.required
              ? (v) {
                  if (v?.isEmpty ?? true) return 'This field is required';
                  if (double.tryParse(v!) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                }
              : null,
          onChanged: (v) => onChanged(v),
        );
      case FormFieldType.textarea:
        return ShadInput(
          controller: _controllers[field.id],
          label: field.label + (field.required ? ' *' : ''),
          hintText: field.placeholder,
          prefixIcon: const Icon(Icons.description, color: AppColors.primary),
          maxLines: 4,
          validator: field.required
              ? (v) => v?.isEmpty ?? true ? 'This field is required' : null
              : null,
          onChanged: (v) => onChanged(v),
        );
      case FormFieldType.dropdown:
        return ShadSelect<String>(
          value: value as String?,
          label: field.label + (field.required ? ' *' : ''),
          hint: field.placeholder,
          prefixIcon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
          items: options.map((o) {
            return ShadSelectItem<String>(
              value: o,
              label: o,
              child: Text(o),
            );
          }).toList(),
          onChanged: (v) => onChanged(v),
          validator: field.required
              ? (v) => v == null ? 'This field is required' : null
              : null,
        );
      case FormFieldType.checkbox:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label + (field.required ? ' *' : ''),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: options.map((o) {
                final set = (value as Set<String>?) ?? <String>{};
                final checked = set.contains(o);
                return FilterChip(
                  label: Text(o),
                  selected: checked,
                  onSelected: (sel) {
                    final next = Set<String>.from(set);
                    if (sel) {
                      next.add(o);
                    } else {
                      next.remove(o);
                    }
                    onChanged(next);
                  },
                );
              }).toList(),
            ),
          ],
        );
      case FormFieldType.radio:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label + (field.required ? ' *' : ''),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...options.map((o) {
              return RadioListTile<String>(
                dense: true,
                value: o,
                groupValue: value as String?,
                title: Text(o),
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => onChanged(v),
              );
            }),
          ],
        );
      case FormFieldType.date:
        return ShadInput(
          label: field.label + (field.required ? ' *' : ''),
          hintText: value == null
              ? field.placeholder
              : DateFormat('MM/dd/yyyy').format(value as DateTime),
          prefixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
          suffixIcon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
          readOnly: true,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value as DateTime? ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
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
            if (picked != null) onChanged(picked);
          },
          validator: field.required
              ? (v) => value == null ? 'This field is required' : null
              : null,
        );
      case FormFieldType.fileUpload:
        return ShadInput(
          label: field.label + (field.required ? ' *' : ''),
          hintText: 'File upload not implemented',
          prefixIcon: const Icon(Icons.upload_file, color: AppColors.primary),
          enabled: false,
        );
      case FormFieldType.sectionTitle:
        return Text(
          field.label.isEmpty ? 'Section' : field.label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        );
      case FormFieldType.divider:
        return const Divider();
    }
  }
}

