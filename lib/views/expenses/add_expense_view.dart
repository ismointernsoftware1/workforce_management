import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/shadcn/shadcn.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/expense_model.dart';
import '../../models/expense_category.dart';
import '../../models/expense_receipt.dart';
import '../../providers/expense_provider.dart';
import '../../services/mileage_service.dart';
import '../../utils/responsive_utils.dart';
import '../../features/form_builder/models/form_models.dart';
import '../../features/form_builder/services/form_builder_firestore_service.dart';
import '../../features/form_builder/services/default_forms_initializer.dart';
import '../../features/form_builder/widgets/enhanced_form_renderer.dart';
import '../widgets/receipt_picker.dart';

class AddExpenseView extends StatefulWidget {
  const AddExpenseView({super.key});

  @override
  State<AddExpenseView> createState() => _AddExpenseViewState();
}

class _AddExpenseViewState extends State<AddExpenseView> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingForm = true;
  List<ExpenseReceipt> _receipts = [];
  final _mileageService = MileageService();
  final _formService = FormBuilderFirestoreService();
  final _formInitializer = DefaultFormsInitializer(FormBuilderFirestoreService());
  FormModel? _defaultExpenseForm;
  Map<String, dynamic> _formValues = {};

  @override
  void initState() {
    super.initState();
    _loadDefaultForm();
    // Ensure categories are loaded when view opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ExpenseProvider>();
      if (provider.categories.isEmpty) {
        provider.loadCategories();
      }
    });
  }

  Future<void> _loadDefaultForm() async {
    try {
      // Initialize default forms if they don't exist
      await _formInitializer.initializeDefaultForms();
      
      // Load the default "Add Expense Form"
      final formId = await _formInitializer.getDefaultFormId('Add Expense Form');
      if (formId != null) {
        final form = await _formService.getForm(formId);
        if (mounted && form != null) {
          setState(() {
            _defaultExpenseForm = form;
            _isLoadingForm = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingForm = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingForm = false;
        });
      }
    }
  }

  // Helper to extract value from form by field label
  String? _getFormValue(String label) {
    if (_defaultExpenseForm == null) return null;
    for (final section in _defaultExpenseForm!.sections) {
      for (final field in section.fields) {
        if (field.label == label) {
          return _formValues[field.id]?.toString();
        }
      }
    }
    return null;
  }

  DateTime? _getFormDateValue(String label) {
    if (_defaultExpenseForm == null) return null;
    for (final section in _defaultExpenseForm!.sections) {
      for (final field in section.fields) {
        if (field.label == label) {
          return _formValues[field.id] as DateTime?;
        }
      }
    }
    return null;
  }

  double? _getFormNumberValue(String label) {
    if (_defaultExpenseForm == null) return null;
    for (final section in _defaultExpenseForm!.sections) {
      for (final field in section.fields) {
        if (field.label == label) {
          final value = _formValues[field.id];
          if (value is num) return value.toDouble();
          if (value is String) return double.tryParse(value);
        }
      }
    }
    return null;
  }

  ExpenseType _parseExpenseType(String? typeStr) {
    if (typeStr == null) return ExpenseType.receipt;
    switch (typeStr.toLowerCase()) {
      case 'mileage':
        return ExpenseType.mileage;
      case 'other':
        return ExpenseType.other;
      default:
        return ExpenseType.receipt;
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Extract values from form
    final expenseTypeStr = _getFormValue('Expense Type');
    final categoryStr = _getFormValue('Category');
    final description = _getFormValue('Description') ?? '';
    final expenseDate = _getFormDateValue('Expense Date');
    final amount = _getFormNumberValue('Amount');
    final merchant = _getFormValue('Merchant');
    final paymentMethod = _getFormValue('Payment Method');
    
    // Mileage fields
    final rate = _getFormNumberValue('Rate per Mile') ?? MileageService.defaultMileageRate;
    final startLocation = _getFormValue('Start Location') ?? '';
    final endLocation = _getFormValue('End Location') ?? '';
    final distance = _getFormNumberValue('Distance (miles)');
    final purpose = _getFormValue('Purpose') ?? '';

    if (expenseDate == null) {
      _showError('Please select an expense date');
      return;
    }

    if (categoryStr == null || categoryStr.isEmpty) {
      _showError('Please select a category');
      return;
    }

    final expenseType = _parseExpenseType(expenseTypeStr);

    // For mileage expenses, validate mileage fields
    if (expenseType == ExpenseType.mileage) {
      if (distance == null || distance <= 0) {
        _showError('Please enter a valid distance');
        return;
      }
      if (startLocation.isEmpty || endLocation.isEmpty) {
        _showError('Please enter start and end locations');
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<ExpenseProvider>();
      
      // Find category by name
      final category = provider.categories.firstWhere(
        (c) => c.name == categoryStr,
        orElse: () => provider.categories.isNotEmpty
            ? provider.categories.first
            : ExpenseCategory(
                id: 'default',
                name: categoryStr,
                code: 'OTHER',
                icon: 'category',
                color: '#6B7280',
              ),
      );
      
      // Get amount - use mileage calculation if mileage type
      double finalAmount;
      ExpenseMileage? mileage;
      
      if (expenseType == ExpenseType.mileage) {
        if (distance == null || distance <= 0) {
          _showError('Invalid mileage calculation');
          return;
        }
        finalAmount = _mileageService.calculateMileageAmount(
          distance: distance,
          customRate: rate,
        );
        mileage = ExpenseMileage(
          distance: distance,
          rate: rate,
          startLocation: startLocation,
          endLocation: endLocation,
          purpose: purpose,
          startDate: expenseDate,
          endDate: expenseDate,
        );
      } else {
        if (amount == null || amount <= 0) {
          _showError('Please enter a valid amount');
          return;
        }
        finalAmount = amount;
      }

      // TODO: Get actual employee info from auth
      const employeeId = 'current_user_id';
      const employeeName = 'Current User';

      // Snapshot form definition and values
      String? formId;
      Map<String, dynamic>? formDefinition;
      Map<String, dynamic>? formValues;
      if (_defaultExpenseForm != null) {
        formId = _defaultExpenseForm!.id;
        formDefinition = {
          'id': _defaultExpenseForm!.id,
          'name': _defaultExpenseForm!.name,
          'sections':
              _defaultExpenseForm!.sections.map((s) => s.toMap()).toList(),
        };
        formValues = Map<String, dynamic>.from(_formValues);
      }

      // Create expense model
      final expense = ExpenseModel(
        id: '', // Will be generated by Firestore
        employeeId: employeeId,
        employeeName: employeeName,
        amount: finalAmount,
        currency: 'USD',
        expenseDate: expenseDate,
        description: description,
        category: category,
        status: ExpenseStatus.draft,
        expenseType: expenseType,
        receipts: _receipts,
        approvals: const [],
        mileage: mileage,
        merchant: merchant?.isEmpty ?? true ? null : merchant,
        paymentMethod: paymentMethod,
        formId: formId,
        formDefinition: formDefinition,
        formValues: formValues,
      );

      // Add expense through provider
      await provider.addExpense(expense);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ShadAlert(
              title: 'Success',
              description: 'Expense added successfully!',
              variant: ShadAlertVariant.success,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.all(16),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showError('Error adding expense: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ShadAlert(
          title: 'Error',
          description: message,
          variant: ShadAlertVariant.destructive,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: const EdgeInsets.all(16),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final categories = provider.categories;

    // Build dynamic options map for dropdowns
    final dynamicOptions = <String, List<String>>{};
    if (_defaultExpenseForm != null) {
      for (final section in _defaultExpenseForm!.sections) {
        for (final field in section.fields) {
          if (field.label == 'Category') {
            // Populate with expense categories
            dynamicOptions[field.id] = categories
                .map((c) => c.name)
                .toList();
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'New Expense',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.border.withValues(alpha: 0.5),
          ),
        ),
      ),
      backgroundColor: AppColors.background,
      body: _isLoadingForm
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: ResponsiveUtils.getPadding(context),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dynamic Form from Firebase
                        if (_defaultExpenseForm != null) ...[
                          EnhancedFormRenderer(
                            form: _defaultExpenseForm!,
                            dynamicOptions: dynamicOptions,
                            onChanged: (values) {
                              setState(() {
                                _formValues = values;
                              });
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ] else ...[
                          // Fallback if form not loaded
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Text(
                                'Form template not available. Please create "Add Expense Form" in Form Builder.',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],

                        // Receipt Upload Section (still separate)
                        ReceiptPicker(
                          receipts: _receipts,
                          onReceiptsChanged: (newReceipts) {
                            setState(() {
                              _receipts = newReceipts;
                            });
                          },
                          employeeId: 'current_user_id', // TODO: Get from auth
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Divider before action button
                        Divider(
                          color: AppColors.border.withValues(alpha: 0.5),
                          height: AppSpacing.xl,
                        ),
                        const SizedBox(height: AppSpacing.md),

              // Submit Button
              ShadButton(
                onPressed: _isLoading ? null : _saveExpense,
                variant: ShadButtonVariant.default_,
                size: ShadButtonSize.lg,
                width: double.infinity,
                disabled: _isLoading,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Expense',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}
