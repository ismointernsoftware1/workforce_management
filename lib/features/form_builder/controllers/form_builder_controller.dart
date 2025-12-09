import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/form_models.dart';
import '../services/form_builder_firestore_service.dart';

/// Controller (MVC-style) that manages state and operations for the form builder.
class FormBuilderController extends ChangeNotifier {
  FormBuilderController(this._service, {this.formType});

  final FormBuilderFirestoreService _service;
  final FormType? formType; // Filter forms by type
  final _uuid = const Uuid();

  List<FormModel> availableForms = <FormModel>[];
  FormModel? activeForm;
  FormModel? _unsavedForm; // Store unsaved form state

  FormSectionModel? selectedSection;
  FormFieldModel? selectedField;

  bool isLoading = false;
  bool isSaving = false;

  Future<void> loadForms() async {
    isLoading = true;
    notifyListeners();
    try {
      availableForms = await _service.getForms(formType: formType);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFormById(String? id) async {
    // Save current unsaved form state before switching
    if (activeForm != null && activeForm!.id.isEmpty) {
      _unsavedForm = activeForm;
    }
    
    if (id == null || id.isEmpty) {
      // If we have an unsaved form, restore it; otherwise create new
      if (_unsavedForm != null) {
        activeForm = _unsavedForm;
      } else {
        _createEmptyForm();
      }
      selectedSection = null;
      selectedField = null;
      notifyListeners();
      return;
    }
    isLoading = true;
    notifyListeners();
    try {
      debugPrint('FormBuilderController: Loading form with id: $id');
      final form = await _service.getForm(id);
      debugPrint('FormBuilderController: getForm returned: ${form != null ? "form found" : "null"}');
      if (form != null) {
        debugPrint('FormBuilderController: Setting activeForm to form "${form.name}"');
        activeForm = form;
        selectedSection = null;
        selectedField = null;
        debugPrint('FormBuilderController: Loaded form "${form.name}" with ${form.sections.length} sections');
        for (var section in form.sections) {
          debugPrint('  - Section "${section.title}" with ${section.fields.length} fields');
        }
        // Force notify after setting activeForm
        debugPrint('FormBuilderController: Notifying listeners after setting activeForm');
        notifyListeners();
        // Double-check activeForm is set
        if (activeForm == null) {
          debugPrint('FormBuilderController: WARNING - activeForm is null after setting!');
        } else {
          debugPrint('FormBuilderController: activeForm confirmed set: "${activeForm!.name}"');
        }
      } else {
        debugPrint('FormBuilderController: Form with id $id not found in Firestore');
        activeForm = null;
      }
    } catch (e, stackTrace) {
      debugPrint('FormBuilderController: Error loading form $id: $e');
      debugPrint('Stack trace: $stackTrace');
      activeForm = null;
    } finally {
      isLoading = false;
      debugPrint('FormBuilderController: Setting isLoading=false, activeForm=${activeForm?.name ?? "null"}');
      notifyListeners();
    }
  }

  void _createEmptyForm() {
    activeForm = FormModel(
      id: '',
      name: 'Untitled Form',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      formType: formType ?? FormType.general,
      sections: <FormSectionModel>[],
    );
    selectedSection = null;
    selectedField = null;
    notifyListeners();
  }

  /// Explicitly create a new form, clearing any unsaved state
  void createNewForm() {
    _unsavedForm = null;
    _createEmptyForm();
  }

  void setFormName(String name) {
    if (activeForm == null) return;
    activeForm!.name = name;
    notifyListeners();
  }

  void addSection() {
    if (activeForm == null) {
      _createEmptyForm();
    }
    final section = FormSectionModel(
      id: _uuid.v4(),
      title: 'Untitled Section',
      fields: <FormFieldModel>[],
    );
    activeForm!.sections.add(section);
    selectedSection = section;
    selectedField = null;
    notifyListeners();
  }

  void deleteSection(String sectionId) {
    if (activeForm == null) return;
    activeForm!.sections.removeWhere((s) => s.id == sectionId);
    if (selectedSection?.id == sectionId) {
      selectedSection = null;
      selectedField = null;
    }
    notifyListeners();
  }

  void addField(FormFieldType type, {String? sectionId, int? insertIndex}) {
    // Ensure we have an active form
    activeForm ??= FormModel(
      id: '',
      name: 'Untitled Form',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      formType: formType ?? FormType.general,
      sections: <FormSectionModel>[],
    );

    // Resolve target section (create one if none exists)
    FormSectionModel targetSection = sectionId != null
        ? (activeForm!.sections.firstWhere(
            (s) => s.id == sectionId,
            orElse: () => selectedSection ??
                (activeForm!.sections.isNotEmpty
                    ? activeForm!.sections.first
                    : _createSectionAndReturn()),
          ))
        : (selectedSection ??
            (activeForm!.sections.isNotEmpty
                ? activeForm!.sections.first
                : _createSectionAndReturn()));
    final field = FormFieldModel(
      id: _uuid.v4(),
      type: type,
      label: 'Untitled Field',
      placeholder: 'Placeholder',
    );
    
    // Insert at specific index if provided, otherwise append
    if (insertIndex != null && insertIndex >= 0 && insertIndex <= targetSection.fields.length) {
      targetSection.fields.insert(insertIndex, field);
    } else {
      targetSection.fields.add(field);
    }
    
    selectedSection = targetSection;
    selectedField = field;
    notifyListeners();
  }

  FormSectionModel _createSectionAndReturn() {
    final section = FormSectionModel(
      id: _uuid.v4(),
      title: 'Untitled Section',
      fields: <FormFieldModel>[],
    );
    activeForm ??= FormModel(
      id: '',
      name: 'Untitled Form',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      formType: formType ?? FormType.general,
      sections: <FormSectionModel>[],
    );
    activeForm!.sections.add(section);
    return section;
  }

  void updateSectionTitle(String sectionId, String title) {
    final section =
        activeForm?.sections.firstWhere((s) => s.id == sectionId, orElse: () {
      return selectedSection ?? _createSectionAndReturn();
    });
    section?.title = title;
    notifyListeners();
  }

  void selectSection(FormSectionModel section) {
    selectedSection = section;
    selectedField = null;
    notifyListeners();
  }

  void selectField(FormFieldModel field, FormSectionModel section) {
    selectedSection = section;
    selectedField = field;
    notifyListeners();
  }

  void updateField(FormFieldModel field, void Function(FormFieldModel) updater) {
    updater(field);
    notifyListeners();
  }

  void deleteField(String sectionId, String fieldId) {
    final section =
        activeForm?.sections.firstWhere((s) => s.id == sectionId, orElse: () {
      return selectedSection ?? _createSectionAndReturn();
    });
    if (section == null) return;
    section.fields.removeWhere((f) => f.id == fieldId);
    if (selectedField?.id == fieldId) {
      selectedField = null;
    }
    notifyListeners();
  }

  void reorderFields(String sectionId, int oldIndex, int newIndex) {
    final section =
        activeForm?.sections.firstWhere((s) => s.id == sectionId, orElse: () {
      return selectedSection ?? _createSectionAndReturn();
    });
    if (section == null) return;
    if (newIndex > oldIndex) newIndex -= 1;
    final item = section.fields.removeAt(oldIndex);
    section.fields.insert(newIndex, item);
    notifyListeners();
  }

  void reorderOptions(FormFieldModel field, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = field.options.removeAt(oldIndex);
    field.options.insert(newIndex, item);
    notifyListeners();
  }

  Future<String> saveFormToFirestore() async {
    if (activeForm == null) {
      _createEmptyForm();
    }
    isSaving = true;
    notifyListeners();
    try {
      String formId = activeForm!.id;
      if (formId.isEmpty) {
        formId = await _service.createForm(activeForm!);
        activeForm = await _service.getForm(formId);
        availableForms.insert(0, activeForm!);
        // Clear unsaved form since it's now saved
        _unsavedForm = null;
      } else {
        await _service.updateForm(activeForm!);
        await loadForms();
      }
      return formId;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteForm(String formId) async {
    try {
      await _service.deleteForm(formId);
      // Remove from available forms
      availableForms.removeWhere((f) => f.id == formId);
      // If the deleted form was active, create a new empty form
      if (activeForm?.id == formId) {
        _createEmptyForm();
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting form: $e');
      return false;
    }
  }

  bool isDefaultForm(String formName) {
    return formName == 'Add Task Form' || formName == 'Add Expense Form';
  }
}


