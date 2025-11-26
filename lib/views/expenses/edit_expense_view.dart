import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../components/shadcn/shadcn.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/expense_model.dart';
import '../../models/expense_category.dart';
import '../../providers/expense_provider.dart';

class EditExpenseView extends StatefulWidget {
  const EditExpenseView({super.key, required this.expense});

  final ExpenseModel expense;

  @override
  State<EditExpenseView> createState() => _EditExpenseViewState();
}

class _EditExpenseViewState extends State<EditExpenseView> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  
  DateTime? _selectedExpenseDate;
  ExpenseCategory? _selectedCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize form fields with existing expense data
    _descriptionController.text = widget.expense.description;
    _amountController.text = widget.expense.amount.toStringAsFixed(2);
    _merchantController.text = widget.expense.merchant ?? '';
    _selectedExpenseDate = widget.expense.expenseDate;
    _selectedCategory = widget.expense.category;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _merchantController.dispose();
    super.dispose();
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

  Future<void> _updateExpense() async {
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

    final parsedAmount = double.tryParse(_amountController.text);
    if (parsedAmount == null || parsedAmount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<ExpenseProvider>();
      
      // Update expense model
      final updatedExpense = widget.expense.copyWith(
        amount: parsedAmount,
        expenseDate: _selectedExpenseDate!,
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        merchant: _merchantController.text.trim().isEmpty
            ? null
            : _merchantController.text.trim(),
      );

      await provider.updateExpense(updatedExpense);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ShadAlert(
              title: 'Success',
              description: 'Expense updated successfully!',
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
        _showError('Error updating expense: ${e.toString()}');
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
          'Edit Expense',
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
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Expense',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Update expense details',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Category Selection
              ShadSelect<ExpenseCategory>(
                label: 'Category *',
                hint: 'Select category',
                value: _selectedCategory,
                prefixIcon: const Icon(Icons.label, color: AppColors.primary),
                items: categories.map((category) {
                  return ShadSelectItem<ExpenseCategory>(
                    value: category,
                    label: category.name,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
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
              const SizedBox(height: AppSpacing.xl),

              // Status Info (read-only)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Status: ',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    _StatusBadge(status: widget.expense.status),
                  ],
                ),
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
                onPressed: _isLoading ? null : _updateExpense,
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
                        'Update Expense',
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
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ExpenseStatus status;

  @override
  Widget build(BuildContext context) {
    String label;
    ShadBadgeVariant variant;

    switch (status) {
      case ExpenseStatus.approved:
        label = 'Approved';
        variant = ShadBadgeVariant.default_;
        break;
      case ExpenseStatus.rejected:
        label = 'Rejected';
        variant = ShadBadgeVariant.destructive;
        break;
      case ExpenseStatus.submitted:
      case ExpenseStatus.underReview:
        label = 'Pending';
        variant = ShadBadgeVariant.secondary;
        break;
      case ExpenseStatus.paid:
        label = 'Paid';
        variant = ShadBadgeVariant.default_;
        break;
      case ExpenseStatus.draft:
        label = 'Draft';
        variant = ShadBadgeVariant.outline;
        break;
    }

    return ShadBadge(
      label: label,
      variant: variant,
    );
  }
}

