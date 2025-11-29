import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../form_builder/models/form_models.dart';

/// Renders a form from a [FormModel] into input widgets and
/// returns a value map through [onChanged] / [onSubmitted].
class DynamicFormRenderer extends StatefulWidget {
  const DynamicFormRenderer({
    super.key,
    required this.form,
    this.initialValues = const <String, dynamic>{},
    required this.onChanged,
  });

  final FormModel form;
  final Map<String, dynamic> initialValues;
  final void Function(Map<String, dynamic> values) onChanged;

  @override
  State<DynamicFormRenderer> createState() => _DynamicFormRendererState();
}

class _DynamicFormRendererState extends State<DynamicFormRenderer> {
  late Map<String, dynamic> _values;

  @override
  void initState() {
    super.initState();
    _values = Map<String, dynamic>.from(widget.initialValues);
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...section.fields.map((field) {
                final value = _values[field.id];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
    switch (field.type) {
      case FormFieldType.text:
      case FormFieldType.email:
      case FormFieldType.number:
      case FormFieldType.textarea:
        return TextField(
          controller: TextEditingController(text: value?.toString() ?? ''),
          maxLines: field.type == FormFieldType.textarea ? 4 : 1,
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.placeholder,
            border: const OutlineInputBorder(),
          ),
          onChanged: onChanged,
        );
      case FormFieldType.dropdown:
        return InputDecorator(
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: (value as String?),
              isExpanded: true,
              hint: Text(field.placeholder),
              items: field.options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (v) => onChanged(v),
            ),
          ),
        );
      case FormFieldType.checkbox:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: field.options.map((o) {
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
        return InputDecorator(
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: field.options.map((o) {
              return RadioListTile<String>(
                dense: true,
                value: o,
                groupValue: value as String?,
                title: Text(o),
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => onChanged(v),
              );
            }).toList(),
          ),
        );
      case FormFieldType.date:
        return _DateField(
          label: field.label,
          value: value as DateTime?,
          onChanged: (v) => onChanged(v),
        );
      case FormFieldType.fileUpload:
        return _PlaceholderTile(label: field.label, hint: 'File upload not implemented');
      case FormFieldType.sectionTitle:
        return Text(
          field.label.isEmpty ? 'Section' : field.label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        );
      case FormFieldType.divider:
        return const Divider();
    }
  }
}

class _PlaceholderTile extends StatelessWidget {
  const _PlaceholderTile({required this.label, required this.hint});
  final String label;
  final String hint;
  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Text(
        hint,
        style: const TextStyle(color: AppColors.textMuted),
      ),
    );
  }
}

class _DateField extends StatefulWidget {
  const _DateField({required this.label, required this.value, required this.onChanged});
  final String label;
  final DateTime? value;
  final void Function(DateTime?) onChanged;

  @override
  State<_DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<_DateField> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          initialDate: widget.value ?? DateTime.now(),
        );
        if (picked != null) widget.onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          widget.value?.toIso8601String().split('T').first ?? 'Select date',
          style: TextStyle(
            color: widget.value == null ? AppColors.textMuted : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}


