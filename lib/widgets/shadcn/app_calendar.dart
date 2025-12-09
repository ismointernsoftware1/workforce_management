import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import 'app_button.dart';

/// A reusable calendar date picker widget using ShadCalendar
/// 
/// This widget provides a clean interface for selecting dates with
/// a dropdown year selector. It can be used as a standalone calendar
/// or wrapped in a dialog/popover.
class AppCalendar extends StatefulWidget {
  const AppCalendar({
    super.key,
    this.selectedDate,
    this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.captionLayout = ShadCalendarCaptionLayout.dropdownYears,
  });

  /// The currently selected date
  final DateTime? selectedDate;

  /// Callback when a date is selected
  final void Function(DateTime)? onDateSelected;

  /// The earliest selectable date (defaults to 2000-01-01)
  final DateTime? firstDate;

  /// The latest selectable date (defaults to 2100-12-31)
  final DateTime? lastDate;

  /// The caption layout for the calendar
  final ShadCalendarCaptionLayout captionLayout;

  @override
  State<AppCalendar> createState() => _AppCalendarState();
}

class _AppCalendarState extends State<AppCalendar> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
  }

  @override
  void didUpdateWidget(AppCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      _selectedDate = widget.selectedDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShadCalendar(
      selected: _selectedDate,
      onChanged: (date) {
        if (date != null) {
          setState(() {
            _selectedDate = date;
          });
          widget.onDateSelected?.call(date);
        }
      },
      captionLayout: widget.captionLayout,
    );
  }
}

/// A date picker input field that opens a calendar dialog
class AppDatePicker extends StatelessWidget {
  const AppDatePicker({
    super.key,
    this.selectedDate,
    this.onDateSelected,
    this.placeholder = 'Select date',
    this.label,
    this.required = false,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
  });

  /// The currently selected date
  final DateTime? selectedDate;

  /// Callback when a date is selected
  final void Function(DateTime)? onDateSelected;

  /// Placeholder text when no date is selected
  final String placeholder;

  /// Optional label for the field
  final String? label;

  /// Whether the field is required
  final bool required;

  /// The earliest selectable date
  final DateTime? firstDate;

  /// The latest selectable date
  final DateTime? lastDate;

  /// Whether the field is enabled
  final bool enabled;

  Future<void> _showDatePickerDialog(BuildContext context) async {
    if (!enabled) {
      debugPrint('AppDatePicker: Field is disabled, not opening dialog');
      return;
    }

    debugPrint('AppDatePicker: Opening date picker dialog');
    final pickedDate = await showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        debugPrint('AppDatePicker: Building dialog content');
        return _DatePickerDialogContent(
          initialDate: selectedDate,
          label: label,
          required: required,
          firstDate: firstDate,
          lastDate: lastDate,
        );
      },
    );

    debugPrint('AppDatePicker: Dialog closed, picked date: $pickedDate');
    if (pickedDate != null) {
      onDateSelected?.call(pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label! + (required ? ' *' : ''),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        GestureDetector(
          onTap: enabled ? () {
            debugPrint('AppDatePicker: Tapped, opening dialog');
            _showDatePickerDialog(context);
          } : null,
          child: AbsorbPointer(
            child: ShadInput(
              placeholder: Text(selectedDate == null
                  ? placeholder
                  : DateFormat('MM/dd/yyyy').format(selectedDate!)),
              leading: const Icon(Icons.calendar_today, color: AppColors.primary),
              trailing: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
              readOnly: true,
              enabled: enabled,
            ),
          ),
        ),
      ],
    );
  }
}

/// Internal dialog content for date picker with state management
class _DatePickerDialogContent extends StatefulWidget {
  const _DatePickerDialogContent({
    required this.initialDate,
    this.label,
    this.required = false,
    this.firstDate,
    this.lastDate,
  });

  final DateTime? initialDate;
  final String? label;
  final bool required;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  State<_DatePickerDialogContent> createState() => _DatePickerDialogContentState();
}

class _DatePickerDialogContentState extends State<_DatePickerDialogContent> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.label != null) ...[
              Text(
                widget.label! + (widget.required ? ' *' : ''),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            AppCalendar(
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  variant: AppButtonVariant.outline,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  onPressed: _selectedDate != null
                      ? () => Navigator.of(context).pop(_selectedDate)
                      : null,
                  child: const Text('Select'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

