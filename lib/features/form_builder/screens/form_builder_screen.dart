import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../utils/responsive_utils.dart';
import '../../form_builder/controllers/form_builder_controller.dart';
import '../../form_builder/services/form_builder_firestore_service.dart';
import '../../form_builder/services/default_forms_initializer.dart';
import '../../form_builder/models/form_models.dart';
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
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: isMobile
            ? const Text(
                'Form Builder',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              )
            : Row(
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
                          Text('New Form'),
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
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
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


