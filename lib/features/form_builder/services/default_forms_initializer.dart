import 'package:uuid/uuid.dart';

import '../models/form_models.dart';
import 'form_builder_firestore_service.dart';

/// Service to initialize default form templates for Add Task and Add Expense pages.
class DefaultFormsInitializer {
  DefaultFormsInitializer(this._service);

  final FormBuilderFirestoreService _service;
  final _uuid = const Uuid();

  /// Initialize default forms if they don't exist.
  /// Returns the IDs of the default forms.
  Future<Map<String, String>> initializeDefaultForms() async {
    final forms = await _service.getForms();
    final result = <String, String>{};

    // Check if "Add Task Form" exists
    final taskForm = forms.firstWhere(
      (f) => f.name == 'Add Task Form',
      orElse: () => FormModel(
        id: '',
        name: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sections: [],
      ),
    );

    if (taskForm.id.isEmpty) {
      final taskFormId = await _createDefaultTaskForm();
      result['task'] = taskFormId;
    } else {
      result['task'] = taskForm.id;
    }

    // Check if "Add Expense Form" exists
    final expenseForm = forms.firstWhere(
      (f) => f.name == 'Add Expense Form',
      orElse: () => FormModel(
        id: '',
        name: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sections: [],
      ),
    );

    if (expenseForm.id.isEmpty) {
      final expenseFormId = await _createDefaultExpenseForm();
      result['expense'] = expenseFormId;
    } else {
      result['expense'] = expenseForm.id;
    }

    return result;
  }

  Future<String> _createDefaultTaskForm() async {
    final form = FormModel(
      id: '',
      name: 'Add Task Form',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      formType: FormType.task,
      sections: [
        FormSectionModel(
          id: _uuid.v4(),
          title: 'Task Information',
          fields: [
            FormFieldModel(
              id: _uuid.v4(),
              type: FormFieldType.text,
              label: 'Task Title',
              placeholder: 'Enter task title',
              required: true,
            ),
            FormFieldModel(
              id: _uuid.v4(),
              type: FormFieldType.textarea,
              label: 'Task Description',
              placeholder: 'Enter task description',
              required: true,
            ),
            FormFieldModel(
              id: _uuid.v4(),
              type: FormFieldType.date,
              label: 'Due Date',
              placeholder: 'Select due date',
              required: true,
            ),
          ],
        ),
        FormSectionModel(
          id: _uuid.v4(),
          title: 'Task Classification',
          fields: [
            FormFieldModel(
              id: _uuid.v4(),
              type: FormFieldType.dropdown,
              label: 'Priority',
              placeholder: 'Select priority',
              required: true,
              options: ['High', 'Medium', 'Low'],
            ),
            FormFieldModel(
              id: _uuid.v4(),
              type: FormFieldType.checkbox,
              label: 'Assigned To',
              placeholder: 'Select team members',
              required: true,
              options: [], // Will be populated dynamically
            ),
          ],
        ),
        FormSectionModel(
          id: _uuid.v4(),
          title: 'Task Details',
          fields: [
            FormFieldModel(
              id: _uuid.v4(),
              type: FormFieldType.textarea,
              label: 'Additional Notes',
              placeholder: 'Add any additional information',
              required: false,
            ),
          ],
        ),
      ],
    );

    return await _service.createForm(form);
  }

  Future<String> _createDefaultExpenseForm() async {
    final form = FormModel(
      id: '',
      name: 'Add Expense Form',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      formType: FormType.expense,
      sections: [
        FormSectionModel(
          id: _uuid.v4(),
          title: 'Expense Information',
          fields: [
            FormFieldModel(
              id: _uuid.v4(),
              type: FormFieldType.dropdown,
              label: 'Expense Type',
              placeholder: 'Select expense type',
              required: true,
              options: ['Receipt', 'Mileage', 'Other'],
            ),
            FormFieldModel(
              id: _uuid.v4(),
              type: FormFieldType.dropdown,
              label: 'Category',
              placeholder: 'Select category',
              required: true,
              options: [], // Will be populated dynamically
            ),
            FormFieldModel(
              id: _uuid.v4(),
              type: FormFieldType.textarea,
              label: 'Description',
              placeholder: 'Enter expense description',
              required: true,
            ),
            FormFieldModel(
              id: _uuid.v4(),
              type: FormFieldType.date,
              label: 'Expense Date',
              placeholder: 'Select date',
              required: true,
            ),
          ],
        ),
        FormSectionModel(
          id: _uuid.v4(),
          title: 'Amount Details',
          fields: [
            FormFieldModel(
              id: _uuid.v4(),
              type: FormFieldType.number,
              label: 'Amount',
              placeholder: '0.00',
              required: true,
            ),
            FormFieldModel(
              id: _uuid.v4(),
              type: FormFieldType.text,
              label: 'Merchant',
              placeholder: 'Enter merchant name',
              required: false,
            ),
            FormFieldModel(
              id: _uuid.v4(),
              type: FormFieldType.dropdown,
              label: 'Payment Method',
              placeholder: 'Select payment method',
              required: false,
              options: [
                'Credit Card',
                'Debit Card',
                'Cash',
                'Bank Transfer',
                'Other',
              ],
            ),
          ],
        ),
        FormSectionModel(
          id: _uuid.v4(),
          title: 'Mileage Details',
          fields: [
            FormFieldModel(
              id: _uuid.v4(),
              type: FormFieldType.number,
              label: 'Rate per Mile',
              placeholder: '0.65',
              required: false,
            ),
            FormFieldModel(
              id: _uuid.v4(),
              type: FormFieldType.text,
              label: 'Start Location',
              placeholder: 'Enter starting location',
              required: false,
            ),
            FormFieldModel(
              id: _uuid.v4(),
              type: FormFieldType.text,
              label: 'End Location',
              placeholder: 'Enter destination',
              required: false,
            ),
            FormFieldModel(
              id: _uuid.v4(),
              type: FormFieldType.number,
              label: 'Distance (miles)',
              placeholder: '0.0',
              required: false,
            ),
            FormFieldModel(
              id: _uuid.v4(),
              type: FormFieldType.textarea,
              label: 'Purpose',
              placeholder: 'Business purpose of trip',
              required: false,
            ),
          ],
        ),
      ],
    );

    return await _service.createForm(form);
  }

  /// Get the default form ID by name
  Future<String?> getDefaultFormId(String formName) async {
    final forms = await _service.getForms();
    try {
      final form = forms.firstWhere((f) => f.name == formName);
      return form.id;
    } catch (_) {
      return null;
    }
  }
}

