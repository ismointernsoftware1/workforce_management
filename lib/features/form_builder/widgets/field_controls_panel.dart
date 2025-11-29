import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../form_builder/models/form_models.dart';

typedef OnFieldTypePicked = void Function(FormFieldType type);

class FieldControlsPanel extends StatelessWidget {
  const FieldControlsPanel({super.key, required this.onPicked});

  final OnFieldTypePicked onPicked;

  @override
  Widget build(BuildContext context) {
    final items = <_ControlItem>[
      _ControlItem('Text', Icons.text_fields, FormFieldType.text),
      _ControlItem('Number', Icons.pin, FormFieldType.number),
      _ControlItem('Email', Icons.alternate_email, FormFieldType.email),
      _ControlItem('Dropdown', Icons.arrow_drop_down_circle_outlined,
          FormFieldType.dropdown),
      _ControlItem('Checkbox', Icons.check_box_outlined, FormFieldType.checkbox),
      _ControlItem('Radio', Icons.radio_button_checked_outlined,
          FormFieldType.radio),
      _ControlItem('Date', Icons.event, FormFieldType.date),
      _ControlItem('Textarea', Icons.notes, FormFieldType.textarea),
      _ControlItem('File Upload', Icons.upload_file, FormFieldType.fileUpload),
      _ControlItem('Section Title', Icons.title, FormFieldType.sectionTitle),
      _ControlItem('Divider', Icons.horizontal_rule, FormFieldType.divider),
    ];

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Field Controls',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final item = items[index];
                final chip = _ControlChip(item: item, onTap: () => onPicked(item.type));
                return Draggable<FormFieldType>(
                  data: item.type,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Opacity(
                      opacity: 0.8,
                      child: Container(
                        width: 200,
                        child: _ControlChip(item: item),
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: chip,
                  ),
                  child: chip,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlChip extends StatelessWidget {
  const _ControlChip({required this.item, this.onTap});

  final _ControlItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Icon(item.icon, size: 18, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.drag_indicator, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _ControlItem {
  _ControlItem(this.label, this.icon, this.type);
  final String label;
  final IconData icon;
  final FormFieldType type;
}


