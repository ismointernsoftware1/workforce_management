import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:shadcn_ui/shadcn_ui.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/expense_model.dart';
import '../../models/expense_category.dart';
import '../../providers/expense_provider.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/shadcn/shadcn_widgets.dart';

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
  ExpenseStatus? _selectedStatus;
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
    _selectedStatus = widget.expense.status;
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
        status: _selectedStatus ?? widget.expense.status,
        merchant: _merchantController.text.trim().isEmpty
            ? null
            : _merchantController.text.trim(),
      );

      await provider.updateExpense(updatedExpense);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Expense updated successfully!'),
            backgroundColor: AppColors.success,
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
        content: Text(message),
        backgroundColor: AppColors.danger,
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
        padding: ResponsiveUtils.getPadding(context),
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
              AppSelect<ExpenseCategory>(
                placeholder: 'Select category',
                value: _selectedCategory,
                options: categories.map((category) => SelectOption<ExpenseCategory>(
                  value: category,
                  label: category.name,
                )).toList(),
                selectedOptionBuilder: (context, value) {
                  return Text(value != null ? value.name : 'Select category');
                },
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Description
              ShadInput(
                controller: _descriptionController,
                placeholder: const Text('Enter expense description'),
                leading: const Icon(Icons.description, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Expense Date
              GestureDetector(
                onTap: _selectExpenseDate,
                child: ShadInput(
                  placeholder: Text(_selectedExpenseDate == null
                      ? 'Select date'
                      : DateFormat('MM/dd/yyyy').format(_selectedExpenseDate!)),
                  leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                  trailing: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                  readOnly: true,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Amount Field
              ShadInput(
                controller: _amountController,
                placeholder: const Text('0.00'),
                leading: const Icon(Icons.attach_money, color: AppColors.primary),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Merchant (optional)
              ShadInput(
                controller: _merchantController,
                placeholder: const Text('Enter merchant name'),
                leading: const Icon(Icons.store, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Status Selection
              AppSelect<ExpenseStatus>(
                placeholder: 'Select status',
                value: _selectedStatus,
                options: ExpenseStatus.values.map((status) {
                  String label;
                  switch (status) {
                    case ExpenseStatus.approved:
                      label = 'Approved';
                      break;
                    case ExpenseStatus.rejected:
                      label = 'Rejected';
                      break;
                    case ExpenseStatus.submitted:
                      label = 'Submitted';
                      break;
                    case ExpenseStatus.underReview:
                      label = 'Under Review';
                      break;
                    case ExpenseStatus.paid:
                      label = 'Paid';
                      break;
                    case ExpenseStatus.draft:
                      label = 'Draft';
                      break;
                  }
                  return SelectOption<ExpenseStatus>(
                    value: status,
                    label: label,
                  );
                }).toList(),
                selectedOptionBuilder: (context, value) {
                  if (value == null) return const Text('Select status');
                  String label;
                  switch (value) {
                    case ExpenseStatus.approved:
                      label = 'Approved';
                      break;
                    case ExpenseStatus.rejected:
                      label = 'Rejected';
                      break;
                    case ExpenseStatus.submitted:
                      label = 'Submitted';
                      break;
                    case ExpenseStatus.underReview:
                      label = 'Under Review';
                      break;
                    case ExpenseStatus.paid:
                      label = 'Paid';
                      break;
                    case ExpenseStatus.draft:
                      label = 'Draft';
                      break;
                  }
                  return Text(label);
                },
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // Divider before action button
              Divider(
                color: AppColors.border.withValues(alpha: 0.5),
                height: AppSpacing.xl,
              ),
              const SizedBox(height: AppSpacing.md),

              // Submit Button
              AppButton(
                onPressed: _isLoading ? null : _updateExpense,
                fullWidth: true,
                isLoading: _isLoading,
                child: const Text(
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

