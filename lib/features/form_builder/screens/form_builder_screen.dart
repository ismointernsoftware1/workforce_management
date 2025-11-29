import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../form_builder/controllers/form_builder_controller.dart';
import '../../form_builder/services/form_builder_firestore_service.dart';
import '../../form_builder/services/default_forms_initializer.dart';
import '../../form_builder/widgets/field_controls_panel.dart';
import '../../form_builder/widgets/properties_panel.dart';
import '../../form_builder/widgets/section_canvas.dart';

class FormBuilderScreen extends StatefulWidget {
  const FormBuilderScreen({super.key});

  @override
  State<FormBuilderScreen> createState() => _FormBuilderScreenState();
}

class _FormBuilderScreenState extends State<FormBuilderScreen> {
  late FormBuilderController _controller;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _controller = FormBuilderController(FormBuilderFirestoreService());
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    try {
      // Initialize default forms first
      final initializer = DefaultFormsInitializer(FormBuilderFirestoreService());
      await initializer.initializeDefaultForms();
      // Then load all forms (this will refresh the list)
      await _controller.loadForms();
      // Create a new empty form for editing
      _controller.loadFormById(null);
      debugPrint('Forms initialized. Total forms: ${_controller.availableForms.length}');
      for (var form in _controller.availableForms) {
        debugPrint('  - ${form.name} (${form.id})');
      }
    } catch (e) {
      // Handle error silently or show message
      debugPrint('Error initializing forms: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FormBuilderController>.value(
      value: _controller,
      child: _isInitializing
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : const _FormBuilderBody(),
    );
  }
}

class _FormBuilderBody extends StatelessWidget {
  const _FormBuilderBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FormBuilderController>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Dynamic Form Builder',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: controller.activeForm?.id.isNotEmpty == true
                      ? controller.activeForm!.id
                      : '__new__',
                  hint: const Text('Select Form'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '__new__',
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 18),
                          SizedBox(width: AppSpacing.sm),
                          Text('New Form'),
                        ],
                      ),
                    ),
                    ...controller.availableForms
                        .map(
                          (f) => DropdownMenuItem(
                            value: f.id,
                            child: Text(f.name),
                          ),
                        )
                        .toList(),
                  ],
                  onChanged: (id) {
                    if (id == '__new__') {
                      // Explicitly create new form, clearing unsaved state
                      controller.createNewForm();
                    } else if (id != null) {
                      controller.loadFormById(id);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldControlsPanel(
            onPicked: (type) {
              controller.addField(type);
            },
          ),
          SectionCanvas(
            controller: controller,
            onAddFieldFromType: (type, sectionId) {
              controller.addField(type, sectionId: sectionId);
            },
          ),
          PropertiesPanel(controller: controller),
        ],
      ),
    );
  }
}


