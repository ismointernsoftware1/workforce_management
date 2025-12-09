import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../utils/responsive_utils.dart';
import '../../../utils/rbac_utils.dart';
import '../../form_builder/controllers/form_builder_controller.dart';
import '../../form_builder/services/form_builder_firestore_service.dart';
import '../../form_builder/services/default_forms_initializer.dart';
import '../../form_builder/models/form_models.dart';
import '../../form_builder/widgets/field_controls_panel.dart';
import '../../form_builder/widgets/properties_panel.dart';
import '../../form_builder/widgets/section_canvas.dart';
import '../../../widgets/shadcn/app_button.dart';

class ExpenseFormBuilderScreen extends StatefulWidget {
  const ExpenseFormBuilderScreen({super.key});

  @override
  State<ExpenseFormBuilderScreen> createState() => _ExpenseFormBuilderScreenState();
}

class _ExpenseFormBuilderScreenState extends State<ExpenseFormBuilderScreen> {
  late FormBuilderController _controller;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _controller = FormBuilderController(
      FormBuilderFirestoreService(),
      formType: FormType.expense,
    );
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    try {
      // Initialize default expense forms first
      final initializer = DefaultFormsInitializer(FormBuilderFirestoreService());
      final formIds = await initializer.initializeDefaultForms();
      debugPrint('Initialized default forms: $formIds');
      
      // Get the expense form ID directly from initialization result
      String? defaultFormId = formIds['expense'];
      debugPrint('Default expense form ID from initializer: $defaultFormId');
      
      // Try to load forms list (may fail due to index, but that's OK)
      try {
        await _controller.loadForms();
        debugPrint('Expense forms loaded. Total forms: ${_controller.availableForms.length}');
        for (var form in _controller.availableForms) {
          debugPrint('  - ${form.name} (${form.id}) with ${form.sections.length} sections');
        }
      } catch (e) {
        debugPrint('Warning: Could not load forms list (index may be missing): $e');
        // Continue anyway - we'll use the form ID from initializer
      }
      
      // Fallback: try to find it in availableForms if we have them
      if ((defaultFormId == null || defaultFormId.isEmpty) && _controller.availableForms.isNotEmpty) {
        try {
          final foundForm = _controller.availableForms.firstWhere(
            (f) => f.name == 'Add Expense Form',
          );
          defaultFormId = foundForm.id;
          debugPrint('Found form in availableForms: ${foundForm.name} (${foundForm.id}) with ${foundForm.sections.length} sections');
        } catch (_) {
          // Form not found in availableForms
          debugPrint('Form "Add Expense Form" not found in availableForms');
        }
      }
      
      if (defaultFormId != null && defaultFormId.isNotEmpty) {
        debugPrint('Loading default "Add Expense Form" with ID: $defaultFormId');
        await _controller.loadFormById(defaultFormId);
        // Wait a moment for the form to load
        await Future.delayed(const Duration(milliseconds: 300));
        if (_controller.activeForm != null) {
          debugPrint('✓ Form loaded successfully: "${_controller.activeForm!.name}"');
          debugPrint('  - Sections: ${_controller.activeForm!.sections.length}');
          for (var section in _controller.activeForm!.sections) {
            debugPrint('    - Section "${section.title}": ${section.fields.length} fields');
          }
        } else {
          debugPrint('✗ Form loaded but activeForm is null!');
          debugPrint('  - Trying to reload form...');
          // Try reloading
          await _controller.loadFormById(defaultFormId);
          await Future.delayed(const Duration(milliseconds: 200));
          if (_controller.activeForm != null) {
            debugPrint('✓ Form loaded on retry: "${_controller.activeForm!.name}"');
          }
        }
        // Force UI update
        if (mounted) {
          setState(() {});
        }
      } else {
        // Fallback: create a new empty form if default doesn't exist
        debugPrint('Default "Add Expense Form" not found, creating new empty form');
        _controller.loadFormById(null);
      }
    } catch (e, stackTrace) {
      debugPrint('Error initializing expense forms: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        // Force one more update after initialization
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: RBACUtils.isSuperAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.data != true) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Access Denied',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'This page is only accessible to Super Administrators.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        
        return ChangeNotifierProvider<FormBuilderController>.value(
          value: _controller,
          child: _isInitializing
              ? const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                )
              : _ExpenseFormBuilderBody(controller: _controller),
        );
      },
    );
  }
}

class _ExpenseFormBuilderBody extends StatelessWidget {
  const _ExpenseFormBuilderBody({required this.controller});
  
  final FormBuilderController controller;

  @override
  Widget build(BuildContext context) {
    // Watch the controller for changes
    context.watch<FormBuilderController>();
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: isMobile
            ? const Text(
                'Expense Form Builder',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              )
            : Row(
                children: [
                  const Text(
                    'Expense Form Builder',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  AppButton(
                    variant: AppButtonVariant.outline,
                    onPressed: () => _showFormSelectorDialog(context, controller),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          controller.activeForm?.id.isNotEmpty == true
                              ? controller.activeForm!.name
                              : 'New Expense Form',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        actions: isMobile
            ? [
                PopupMenuButton<String>(
                  onSelected: (id) {
                    if (id == '__new__') {
                      controller.createNewForm();
                    } else {
                      controller.loadFormById(id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: '__new__',
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 18),
                          SizedBox(width: AppSpacing.sm),
                          Text('New Expense Form'),
                        ],
                      ),
                    ),
                    ...controller.availableForms
                        .map(
                          (f) => PopupMenuItem<String>(
                            value: f.id,
                            child: Text(f.name),
                          ),
                        )
                        .toList(),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
              ]
            : null,
      ),
      body: isMobile
          ? _buildMobileLayout(context, controller)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FieldControlsPanel(
                  onPicked: (type) {
                    controller.addField(type);
                  },
                ),
                Expanded(
                  child: SectionCanvas(
                    controller: controller,
                    onAddFieldFromType: (type, sectionId) {
                      controller.addField(type, sectionId: sectionId);
                    },
                  ),
                ),
                if (!isTablet) PropertiesPanel(controller: controller),
              ],
            ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, FormBuilderController controller) {
    return Column(
      children: [
        // Field Controls Section
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Field Controls',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    _ControlChip(
                      item: _ControlItem('Text', Icons.text_fields, FormFieldType.text),
                      onTap: () => controller.addField(FormFieldType.text),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _ControlChip(
                      item: _ControlItem('Number', Icons.pin, FormFieldType.number),
                      onTap: () => controller.addField(FormFieldType.number),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _ControlChip(
                      item: _ControlItem('Email', Icons.alternate_email, FormFieldType.email),
                      onTap: () => controller.addField(FormFieldType.email),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _ControlChip(
                      item: _ControlItem('Dropdown', Icons.arrow_drop_down_circle_outlined, FormFieldType.dropdown),
                      onTap: () => controller.addField(FormFieldType.dropdown),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _ControlChip(
                      item: _ControlItem('Checkbox', Icons.check_box_outlined, FormFieldType.checkbox),
                      onTap: () => controller.addField(FormFieldType.checkbox),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _ControlChip(
                      item: _ControlItem('Radio', Icons.radio_button_checked_outlined, FormFieldType.radio),
                      onTap: () => controller.addField(FormFieldType.radio),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _ControlChip(
                      item: _ControlItem('Date', Icons.event, FormFieldType.date),
                      onTap: () => controller.addField(FormFieldType.date),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _ControlChip(
                      item: _ControlItem('Textarea', Icons.notes, FormFieldType.textarea),
                      onTap: () => controller.addField(FormFieldType.textarea),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _ControlChip(
                      item: _ControlItem('File Upload', Icons.upload_file, FormFieldType.fileUpload),
                      onTap: () => controller.addField(FormFieldType.fileUpload),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _ControlChip(
                      item: _ControlItem('Section Title', Icons.title, FormFieldType.sectionTitle),
                      onTap: () => controller.addField(FormFieldType.sectionTitle),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _ControlChip(
                      item: _ControlItem('Divider', Icons.horizontal_rule, FormFieldType.divider),
                      onTap: () => controller.addField(FormFieldType.divider),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Canvas Section
        Expanded(
          child: SectionCanvas(
            controller: controller,
            onAddFieldFromType: (type, sectionId) {
              controller.addField(type, sectionId: sectionId);
            },
          ),
        ),
      ],
    );
  }

  void _showFormSelectorDialog(BuildContext context, FormBuilderController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Expense Form'),
        content: SizedBox(
          width: 300,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.add, color: AppColors.primary),
                title: const Text('New Expense Form'),
                onTap: () {
                  controller.createNewForm();
                  Navigator.of(context).pop();
                },
              ),
              const Divider(),
              ...controller.availableForms.map(
                (form) => ListTile(
                  leading: const Icon(Icons.description, color: AppColors.textMuted),
                  title: Text(form.name),
                  trailing: controller.activeForm?.id == form.id
                      ? const Icon(Icons.check, color: AppColors.primary, size: 20)
                      : null,
                  onTap: () {
                    controller.loadFormById(form.id);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _ControlItem {
  _ControlItem(this.label, this.icon, this.type);
  final String label;
  final IconData icon;
  final FormFieldType? type;
}

class _ControlChip extends StatelessWidget {
  const _ControlChip({required this.item, this.onTap});

  final _ControlItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 18, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

