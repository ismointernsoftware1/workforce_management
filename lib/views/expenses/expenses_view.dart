import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../components/shadcn/shadcn.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../widgets/stat_card.dart';
import 'add_expense_view.dart';

class ExpensesView extends StatelessWidget {
  const ExpensesView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              maxWidth: constraints.maxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expense Management',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Track and approve employee expenses',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                    ShadButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AddExpenseView(),
                          ),
                        );
                        if (context.mounted) {
                          await provider.refreshExpenses();
                        }
                      },
                      variant: ShadButtonVariant.default_,
                      size: ShadButtonSize.md,
                      icon: const Icon(Icons.add, size: 20),
                      child: const Text('New Expense'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Total Expenses',
                        value: _formatCurrency(provider.totalAmount),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: StatCard(
                        title: 'Approved',
                        value: _formatCurrency(provider.approvedAmount),
                        badge: _coloredBadge('Approved', AppColors.success),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: StatCard(
                        title: 'Pending',
                        value: _formatCurrency(provider.pendingAmount),
                        badge: _coloredBadge('Pending', AppColors.warning),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                
                // Filter Tabs
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: ExpenseProvider.statusFilters.map(
                    (filter) {
                      final isSelected = provider.statusFilter == filter;
                      return ShadButton(
                        onPressed: () => provider.changeStatusFilter(filter),
                        variant: isSelected
                            ? ShadButtonVariant.default_
                            : ShadButtonVariant.outline,
                        size: ShadButtonSize.sm,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            if (isSelected) const SizedBox(width: AppSpacing.xs),
                            Text(filter),
                          ],
                        ),
                      );
                    },
                  ).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Expenses Table
                if (provider.filteredExpenses.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'No expenses found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Add a new expense to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _ExpensesTable(expenses: provider.filteredExpenses),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _coloredBadge(String label, Color color) {
    ShadBadgeVariant variant;
    if (color == AppColors.success) {
      variant = ShadBadgeVariant.default_;
    } else if (color == AppColors.warning) {
      variant = ShadBadgeVariant.secondary;
    } else {
      variant = ShadBadgeVariant.secondary;
    }

    return ShadBadge(
      label: label,
      variant: variant,
    );
  }

  static String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }
}

class _ExpensesTable extends StatelessWidget {
  const _ExpensesTable({required this.expenses});

  final List<ExpenseModel> expenses;

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('yyyy-MM-dd');
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Description',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Category',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Employee',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Amount',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Date',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Status',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Action',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table Rows
          ...expenses.map((expense) => _ExpenseTableRow(
                expense: expense,
                dateFormatter: dateFormatter,
                currencyFormatter: currencyFormatter,
              )),
        ],
      ),
    );
  }
}

class _ExpenseTableRow extends StatelessWidget {
  const _ExpenseTableRow({
    required this.expense,
    required this.dateFormatter,
    required this.currencyFormatter,
  });

  final ExpenseModel expense;
  final DateFormat dateFormatter;
  final NumberFormat currencyFormatter;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              expense.description,
              style: TextStyle(color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              expense.category.name,
              style: TextStyle(color: AppColors.textMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              expense.employeeName,
              style: TextStyle(color: AppColors.textMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              currencyFormatter.format(expense.amount),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              dateFormatter.format(expense.expenseDate),
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            flex: 1,
            child: _StatusBadge(status: expense.status),
          ),
          Expanded(
            flex: 1,
            child: ShadButton(
              onPressed: () => _showDeleteConfirmation(context, expense, provider),
              variant: ShadButtonVariant.ghost,
              size: ShadButtonSize.icon,
              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
              child: const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    ExpenseModel expense,
    ExpenseProvider provider,
  ) {
    ShadDialog.show(
      context: context,
      title: 'Delete Expense',
      content: Text(
        'Are you sure you want to delete "${expense.description}"? This action cannot be undone.',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      actions: [
        ShadButton(
          onPressed: () => Navigator.pop(context),
          variant: ShadButtonVariant.outline,
          child: const Text('Cancel'),
        ),
        ShadButton(
          onPressed: () async {
            Navigator.pop(context);
            try {
              await provider.deleteExpense(expense.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: ShadAlert(
                      title: 'Success',
                      description: 'Expense deleted successfully',
                      variant: ShadAlertVariant.success,
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    padding: const EdgeInsets.all(16),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: ShadAlert(
                      title: 'Error',
                      description: 'Failed to delete expense: ${e.toString()}',
                      variant: ShadAlertVariant.destructive,
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    padding: const EdgeInsets.all(16),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          variant: ShadButtonVariant.destructive,
          child: const Text('Delete'),
        ),
      ],
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

