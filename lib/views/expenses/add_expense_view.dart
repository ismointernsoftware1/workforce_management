import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../components/shadcn/shadcn.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/expense_model.dart';
import '../../models/expense_category.dart';
import '../../models/expense_receipt.dart';
import '../../providers/expense_provider.dart';
import '../../services/mileage_service.dart';
import '../../utils/responsive_utils.dart';
import '../widgets/receipt_picker.dart';

class AddExpenseView extends StatefulWidget {
  const AddExpenseView({super.key});

  @override
  State<AddExpenseView> createState() => _AddExpenseViewState();
}

class _AddExpenseViewState extends State<AddExpenseView> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  
  // Mileage fields
  final _distanceController = TextEditingController();
  final _rateController = TextEditingController();
  final _startLocationController = TextEditingController();
  final _endLocationController = TextEditingController();
  final _purposeController = TextEditingController();

  DateTime? _selectedExpenseDate;
  ExpenseType _selectedExpenseType = ExpenseType.receipt;
  ExpenseCategory? _selectedCategory;
  String _selectedCurrency = 'USD';
  String? _selectedPaymentMethod;
  bool _isLoading = false;
  
  List<ExpenseReceipt> _receipts = [];
  final _mileageService = MileageService();

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _merchantController.dispose();
    _distanceController.dispose();
    _rateController.dispose();
    _startLocationController.dispose();
    _endLocationController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Initialize rate with default value
    _rateController.text = MileageService.defaultMileageRate.toStringAsFixed(2);
    
    // Ensure categories are loaded when view opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ExpenseProvider>();
      if (provider.categories.isEmpty) {
        provider.loadCategories();
      }
    });
  }

  Future<void> _selectExpenseDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpenseDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
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
    if (picked != null && picked != _selectedExpenseDate) {
      setState(() {
        _selectedExpenseDate = picked;
      });
    }
  }

  double? _calculateMileageAmount() {
    final distance = double.tryParse(_distanceController.text);
    final rate = double.tryParse(_rateController.text) ?? MileageService.defaultMileageRate;
    if (distance != null && distance > 0) {
      return _mileageService.calculateMileageAmount(
        distance: distance,
        customRate: rate,
      );
    }
    return null;
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedExpenseDate == null) {
      _showError('Please select an expense date');
      return;
    }

    if (_selectedCategory == null) {
      _showError('Please select a category');
      return;
    }

    // For mileage expenses, validate mileage fields
    if (_selectedExpenseType == ExpenseType.mileage) {
      final distance = double.tryParse(_distanceController.text);
      if (distance == null || distance <= 0) {
        _showError('Please enter a valid distance');
        return;
      }
      if (_startLocationController.text.trim().isEmpty ||
          _endLocationController.text.trim().isEmpty) {
        _showError('Please enter start and end locations');
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<ExpenseProvider>();
      
      // Get amount - use mileage calculation if mileage type
      double amount;
      ExpenseMileage? mileage;
      
      if (_selectedExpenseType == ExpenseType.mileage) {
        final calculatedAmount = _calculateMileageAmount();
        if (calculatedAmount == null) {
          _showError('Invalid mileage calculation');
          return;
        }
        amount = calculatedAmount;
        mileage = ExpenseMileage(
          distance: double.parse(_distanceController.text),
          rate: double.tryParse(_rateController.text) ?? MileageService.defaultMileageRate,
          startLocation: _startLocationController.text.trim(),
          endLocation: _endLocationController.text.trim(),
          purpose: _purposeController.text.trim(),
          startDate: _selectedExpenseDate,
          endDate: _selectedExpenseDate,
        );
      } else {
        final parsedAmount = double.tryParse(_amountController.text);
        if (parsedAmount == null || parsedAmount <= 0) {
          _showError('Please enter a valid amount');
          return;
        }
        amount = parsedAmount;
      }

      // TODO: Get actual employee info from auth
      const employeeId = 'current_user_id';
      const employeeName = 'Current User';

      // Create expense model
      final expense = ExpenseModel(
        id: '', // Will be generated by Firestore
        employeeId: employeeId,
        employeeName: employeeName,
        amount: amount,
        currency: _selectedCurrency,
        expenseDate: _selectedExpenseDate!,
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        status: ExpenseStatus.draft,
        expenseType: _selectedExpenseType,
        receipts: _receipts,
        approvals: const [],
        mileage: mileage,
        merchant: _merchantController.text.trim().isEmpty
            ? null
            : _merchantController.text.trim(),
        paymentMethod: _selectedPaymentMethod,
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
      body: SingleChildScrollView(
        padding: ResponsiveUtils.getPadding(context),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

              // Expense Type Selection
              ShadSelect<ExpenseType>(
                label: 'Expense Type *',
                hint: 'Select expense type',
                value: _selectedExpenseType,
                prefixIcon: const Icon(Icons.category, color: AppColors.primary),
                items: ExpenseType.values.map((type) {
                  String label;
                  IconData icon;
                  switch (type) {
                    case ExpenseType.receipt:
                      label = 'Receipt';
                      icon = Icons.receipt;
                      break;
                    case ExpenseType.mileage:
                      label = 'Mileage';
                      icon = Icons.directions_car;
                      break;
                    case ExpenseType.other:
                      label = 'Other';
                      icon = Icons.category;
                      break;
                  }
                  return ShadSelectItem(
                    value: type,
                    label: label,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Text(label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedExpenseType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Category Selection
              if (provider.isLoading && categories.isEmpty)
                ShadInput(
                  label: 'Category *',
                  hintText: 'Loading categories...',
                  prefixIcon: const Icon(Icons.label, color: AppColors.primary),
                  enabled: false,
                )
              else
                ShadSelect<ExpenseCategory>(
                  label: 'Category *',
                  hint: categories.isEmpty ? 'No categories available' : 'Select category',
                  value: _selectedCategory,
                  prefixIcon: const Icon(Icons.label, color: AppColors.primary),
                  enabled: categories.isNotEmpty,
                  items: categories.map((category) {
                    return ShadSelectItem<ExpenseCategory>(
                      value: category,
                      label: category.name,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (categories.isNotEmpty) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: AppSpacing.lg),

              // Description
              ShadInput(
                controller: _descriptionController,
                label: 'Description *',
                hintText: 'Enter expense description',
                prefixIcon: const Icon(Icons.description, color: AppColors.primary),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Expense Date
              ShadInput(
                label: 'Expense Date *',
                hintText: _selectedExpenseDate == null
                    ? 'Select date'
                    : DateFormat('MM/dd/yyyy').format(_selectedExpenseDate!),
                prefixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
                suffixIcon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                readOnly: true,
                onTap: _selectExpenseDate,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Amount or Mileage Fields based on type
              if (_selectedExpenseType == ExpenseType.mileage) ...[
                // Mileage Calculator Section
                _MileageCalculator(
                  distanceController: _distanceController,
                  rateController: _rateController,
                  startLocationController: _startLocationController,
                  endLocationController: _endLocationController,
                  purposeController: _purposeController,
                  onAmountCalculated: () => setState(() {}),
                ),
              ] else ...[
                // Amount Field
                ShadInput(
                  controller: _amountController,
                  label: 'Amount *',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.attach_money, color: AppColors.primary),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Merchant (optional)
                ShadInput(
                  controller: _merchantController,
                  label: 'Merchant',
                  hintText: 'Enter merchant name',
                  prefixIcon: const Icon(Icons.store, color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Payment Method (optional)
                ShadSelect<String>(
                  label: 'Payment Method',
                  hint: 'Select payment method',
                  value: _selectedPaymentMethod,
                  prefixIcon: const Icon(Icons.payment, color: AppColors.primary),
                  items: const [
                    'Credit Card',
                    'Debit Card',
                    'Cash',
                    'Bank Transfer',
                    'Other',
                  ].map((method) {
                    return ShadSelectItem(
                      value: method,
                      label: method,
                      child: Text(method),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Receipt Upload Section
                ReceiptPicker(
                  receipts: _receipts,
                  onReceiptsChanged: (newReceipts) {
                    setState(() {
                      _receipts = newReceipts;
                    });
                  },
                  employeeId: 'current_user_id', // TODO: Get from auth
                ),
              ],

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

class _MileageCalculator extends StatefulWidget {
  const _MileageCalculator({
    required this.distanceController,
    required this.rateController,
    required this.startLocationController,
    required this.endLocationController,
    required this.purposeController,
    required this.onAmountCalculated,
  });

  final TextEditingController distanceController;
  final TextEditingController rateController;
  final TextEditingController startLocationController;
  final TextEditingController endLocationController;
  final TextEditingController purposeController;
  final VoidCallback onAmountCalculated;

  @override
  State<_MileageCalculator> createState() => _MileageCalculatorState();
}

class _MileageCalculatorState extends State<_MileageCalculator> {
  final _mileageService = MileageService();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mileage Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        // Rate input - Editable by user
        ShadInput(
          controller: widget.rateController,
          label: 'Rate per Mile (\$/mile) *',
          hintText: '0.65',
          prefixIcon: const Icon(Icons.attach_money, color: AppColors.primary),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) {
            setState(() {}); // Trigger rebuild to update calculation
            widget.onAmountCalculated();
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter rate per mile';
            }
            final rate = double.tryParse(value);
            if (rate == null || rate <= 0) {
              return 'Please enter a valid rate';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.md),

        // Start Location
        ShadInput(
          controller: widget.startLocationController,
          label: 'Start Location *',
          hintText: 'Enter starting location',
          prefixIcon: const Icon(Icons.location_on, color: AppColors.primary),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter start location';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.md),

        // End Location
        ShadInput(
          controller: widget.endLocationController,
          label: 'End Location *',
          hintText: 'Enter destination',
          prefixIcon: const Icon(Icons.location_on, color: AppColors.primary),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter end location';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.md),
        
        // Distance
        ShadInput(
          controller: widget.distanceController,
          label: 'Distance (miles) *',
          hintText: '0.0',
          prefixIcon: const Icon(Icons.straighten, color: AppColors.primary),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) {
            setState(() {}); // Trigger rebuild to update calculation
            widget.onAmountCalculated();
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter distance';
            }
            final distance = double.tryParse(value);
            if (distance == null || distance <= 0) {
              return 'Please enter a valid distance';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.md),

        // Purpose
        ShadInput(
          controller: widget.purposeController,
          label: 'Purpose',
          hintText: 'Business purpose of trip',
          prefixIcon: const Icon(Icons.description, color: AppColors.primary),
          maxLines: 2,
        ),
        const SizedBox(height: AppSpacing.md),

        // Calculated Amount Display with Breakdown
        Builder(
          builder: (context) {
            final distance = double.tryParse(widget.distanceController.text);
            final rate = double.tryParse(widget.rateController.text) ?? MileageService.defaultMileageRate;
            
            if (distance != null && distance > 0 && rate > 0) {
              final totalAmount = _mileageService.calculateMileageAmount(
                distance: distance,
                customRate: rate,
              );
              
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Calculation Breakdown
                    Builder(
                      builder: (context) {
                        final isMobile = ResponsiveUtils.isMobile(context);
                        if (isMobile) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Calculation:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${distance.toStringAsFixed(2)} miles × \$${rate.toStringAsFixed(2)}/mile',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          );
                        }
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                'Calculation:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                '${distance.toStringAsFixed(2)} miles × \$${rate.toStringAsFixed(2)}/mile',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Total Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Total Reimbursement:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '\$${totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

