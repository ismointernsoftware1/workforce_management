import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:shadcn_ui/shadcn_ui.dart';
import '../../utils/animation_utils.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/shadcn/shadcn_widgets.dart';
import '../widgets/stat_card.dart';
import 'add_expense_view.dart';
import 'edit_expense_view.dart';

class ExpensesView extends StatefulWidget {
  const ExpensesView({super.key});

  @override
  State<ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends State<ExpensesView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    // Refresh expenses when view becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshExpenses();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshExpenses() async {
    if (!mounted) return;
    final provider = context.read<ExpenseProvider>();
    // Always refresh to ensure latest data is loaded
    await provider.refreshExpenses();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final isMobile = ResponsiveUtils.isMobile(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: ResponsiveUtils.getPadding(context),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              maxWidth: constraints.maxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                if (isMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderTitle(context)
                          .animate()
                          .fade(
                            duration: AnimationUtils.normalDuration,
                            delay: AnimationUtils.shortDelay,
                          )
                          .slide(
                            begin: const Offset(0, -10),
                            end: Offset.zero,
                            duration: AnimationUtils.normalDuration,
                            delay: AnimationUtils.shortDelay,
                            curve: Curves.easeOutCubic,
                          ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          onPressed: () => _openAddExpense(context),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 18),
                              SizedBox(width: 8),
                              Text('New Expense'),
                            ],
                          ),
                        )
                            .animate()
                            .fade(
                              duration: AnimationUtils.normalDuration,
                              delay: AnimationUtils.mediumDelay,
                            )
                            .slide(
                              begin: const Offset(0, -10),
                              end: Offset.zero,
                              duration: AnimationUtils.normalDuration,
                              delay: AnimationUtils.mediumDelay,
                              curve: Curves.easeOutCubic,
                            ),
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildHeaderTitle(context)
                            .animate()
                            .fade(
                              duration: AnimationUtils.normalDuration,
                              delay: AnimationUtils.shortDelay,
                            )
                            .slide(
                              begin: const Offset(0, -10),
                              end: Offset.zero,
                              duration: AnimationUtils.normalDuration,
                              delay: AnimationUtils.shortDelay,
                              curve: Curves.easeOutCubic,
                            ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      AppButton(
                        onPressed: () => _openAddExpense(context),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 20),
                            SizedBox(width: 8),
                            Text('New Expense'),
                          ],
                        ),
                      )
                          .animate()
                          .fade(
                            duration: AnimationUtils.normalDuration,
                            delay: AnimationUtils.mediumDelay,
                          )
                          .slide(
                            begin: const Offset(0, -10),
                            end: Offset.zero,
                            duration: AnimationUtils.normalDuration,
                            delay: AnimationUtils.mediumDelay,
                            curve: Curves.easeOutCubic,
                          ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.xl),
                
                // Search Bar
                ShadInput(
                  controller: _searchController,
                  placeholder: const Text('Search expenses...'),
                  leading: const Icon(Icons.search, color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.xl),
                
                // Summary Cards
                isMobile
                    ? Column(
                        children: [
                          StatCard(
                            title: 'Total Expenses',
                            value: _formatCurrency(provider.totalAmount),
                          )
                              .animate()
                              .scale(
                                begin: const Offset(0.95, 0.95),
                                end: const Offset(1, 1),
                                duration: AnimationUtils.normalDuration,
                                delay: AnimationUtils.shortDelay,
                                curve: Curves.easeOutCubic,
                              )
                              .fade(
                                duration: AnimationUtils.normalDuration,
                                delay: AnimationUtils.shortDelay,
                              ),
                          const SizedBox(height: AppSpacing.md),
                          StatCard(
                            title: 'Approved',
                            value: _formatCurrency(provider.approvedAmount),
                            badge: _coloredBadge('Approved', AppColors.success),
                          )
                              .animate()
                              .scale(
                                begin: const Offset(0.95, 0.95),
                                end: const Offset(1, 1),
                                duration: AnimationUtils.normalDuration,
                                delay: AnimationUtils.mediumDelay,
                                curve: Curves.easeOutCubic,
                              )
                              .fade(
                                duration: AnimationUtils.normalDuration,
                                delay: AnimationUtils.mediumDelay,
                              ),
                          const SizedBox(height: AppSpacing.md),
                          StatCard(
                            title: 'Pending',
                            value: _formatCurrency(provider.pendingAmount),
                            badge: _coloredBadge('Pending', AppColors.warning),
                          )
                              .animate()
                              .scale(
                                begin: const Offset(0.95, 0.95),
                                end: const Offset(1, 1),
                                duration: AnimationUtils.normalDuration,
                                delay: AnimationUtils.longDelay,
                                curve: Curves.easeOutCubic,
                              )
                              .fade(
                                duration: AnimationUtils.normalDuration,
                                delay: AnimationUtils.longDelay,
                              ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Total Expenses',
                              value: _formatCurrency(provider.totalAmount),
                            )
                                .animate()
                                .scale(
                                  begin: const Offset(0.95, 0.95),
                                  end: const Offset(1, 1),
                                  duration: AnimationUtils.normalDuration,
                                  delay: AnimationUtils.shortDelay,
                                  curve: Curves.easeOutCubic,
                                )
                                .fade(
                                  duration: AnimationUtils.normalDuration,
                                  delay: AnimationUtils.shortDelay,
                                ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: StatCard(
                              title: 'Approved',
                              value: _formatCurrency(provider.approvedAmount),
                              badge: _coloredBadge('Approved', AppColors.success),
                            )
                                .animate()
                                .scale(
                                  begin: const Offset(0.95, 0.95),
                                  end: const Offset(1, 1),
                                  duration: AnimationUtils.normalDuration,
                                  delay: AnimationUtils.mediumDelay,
                                  curve: Curves.easeOutCubic,
                                )
                                .fade(
                                  duration: AnimationUtils.normalDuration,
                                  delay: AnimationUtils.mediumDelay,
                                ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: StatCard(
                              title: 'Pending',
                              value: _formatCurrency(provider.pendingAmount),
                              badge: _coloredBadge('Pending', AppColors.warning),
                            )
                                .animate()
                                .scale(
                                  begin: const Offset(0.95, 0.95),
                                  end: const Offset(1, 1),
                                  duration: AnimationUtils.normalDuration,
                                  delay: AnimationUtils.longDelay,
                                  curve: Curves.easeOutCubic,
                                )
                                .fade(
                                  duration: AnimationUtils.normalDuration,
                                  delay: AnimationUtils.longDelay,
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
                      return isSelected
                          ? AppButton(
                              onPressed: () => provider.changeStatusFilter(filter),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(filter),
                                ],
                              ),
                            )
                          : AppButton(
                              variant: AppButtonVariant.outline,
                              onPressed: () => provider.changeStatusFilter(filter),
                              child: Text(filter),
                            );
                    },
                  ).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Expenses Table
                if (_getFilteredExpenses(provider).isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl * 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'No expenses found',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No expenses match your search'
                              : 'Add a new expense to get started',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textMuted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _ExpensesTable(
                    expenses: _getFilteredExpenses(provider),
                    isMobile: isMobile,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _coloredBadge(String label, Color color) {
    return ShadBadge(
      child: Text(label),
    );
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  Widget _buildHeaderTitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expense Management',
          style: TextStyle(
            fontSize: ResponsiveUtils.getFontSize(
              context,
              mobile: 28,
              tablet: 32,
              desktop: 36,
            ),
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.8,
            height: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Track and approve employee expenses',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: ResponsiveUtils.getFontSize(
              context,
              mobile: 14,
              tablet: 15,
              desktop: 16,
            ),
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  List<ExpenseModel> _getFilteredExpenses(ExpenseProvider provider) {
    var filtered = provider.filteredExpenses;
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((expense) {
        final merchant = expense.merchant?.toLowerCase() ?? '';
        return expense.description.toLowerCase().contains(query) ||
            expense.category.name.toLowerCase().contains(query) ||
            expense.employeeName.toLowerCase().contains(query) ||
            merchant.contains(query);
      }).toList();
    }
    
    return filtered;
  }

  Future<void> _openAddExpense(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    await navigator.push(
      MaterialPageRoute(
        builder: (_) => const AddExpenseView(),
        fullscreenDialog: true,
      ),
    );
    if (!mounted) return;
    await context.read<ExpenseProvider>().refreshExpenses();
  }

  Future<void> _handleApprove(
    BuildContext context,
    ExpenseModel expense,
  ) async {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Approve Expense'),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to approve "${expense.description}"?',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Amount: \$${expense.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
          AppButton(
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          AppButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await provider.updateExpenseStatus(expense.id, ExpenseStatus.approved);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Expense approved successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to approve expense: ${e.toString()}'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReject(
    BuildContext context,
    ExpenseModel expense,
  ) async {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Reject Expense'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to reject "${expense.description}"?',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            ShadInput(
              controller: reasonController,
              placeholder: const Text('Enter reason for rejection (optional)'),
            ),
          ],
        ),
        actions: [
          AppButton(
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          AppButton(
            variant: AppButtonVariant.destructive,
            onPressed: () async {
              Navigator.pop(context);
              try {
                await provider.updateExpenseStatus(expense.id, ExpenseStatus.rejected);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Expense rejected successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to reject expense: ${e.toString()}'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEdit(
    BuildContext context,
    ExpenseModel expense,
  ) async {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditExpenseView(expense: expense),
      ),
    );
    if (context.mounted) {
      await provider.refreshExpenses();
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    ExpenseModel expense,
  ) {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Delete Expense'),
        child: Text(
          'Are you sure you want to delete "${expense.description}"? This action cannot be undone.',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          AppButton(
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          AppButton(
            variant: AppButtonVariant.destructive,
            onPressed: () async {
              Navigator.pop(context);
              try {
                await provider.deleteExpense(expense.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Expense deleted successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete expense: ${e.toString()}'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ExpensesTable extends StatelessWidget {
  const _ExpensesTable({
    required this.expenses,
    required this.isMobile,
  });

  final List<ExpenseModel> expenses;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('yyyy-MM-dd');
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isMobile
          ? SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: ListView(
                children: expenses.asMap().entries.map((entry) {
                  final viewState = context.findAncestorStateOfType<_ExpensesViewState>();
                  return _ExpenseMobileCard(
                    expense: entry.value,
                    dateFormatter: dateFormatter,
                    currencyFormatter: currencyFormatter,
                    viewState: viewState,
                  )
                      .animate()
                      .fade(
                        duration: AnimationUtils.normalDuration,
                        delay: AnimationUtils.shortDelay * (entry.key + 1),
                      )
                      .slide(
                        begin: const Offset(0, 20),
                        end: Offset.zero,
                        duration: AnimationUtils.normalDuration,
                        delay: AnimationUtils.shortDelay * (entry.key + 1),
                        curve: Curves.easeOutCubic,
                      );
                }).toList(),
              ),
            )
          : SizedBox(
              height: MediaQuery.of(context).size.height * 
                  (ResponsiveUtils.isMobile(context) ? 0.5 : 0.65),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.isTablet(context) 
                          ? AppSpacing.md 
                          : AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: ResponsiveUtils.isTablet(context) ? 2 : 3,
                          child: Text(
                            'Description',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: ResponsiveUtils.getFontSize(
                                context,
                                mobile: 12,
                                tablet: 13,
                                desktop: 14,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: ResponsiveUtils.isTablet(context) ? 1 : 2,
                          child: Text(
                            'Category',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: ResponsiveUtils.getFontSize(
                                context,
                                mobile: 12,
                                tablet: 13,
                                desktop: 14,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: ResponsiveUtils.isTablet(context) ? 1 : 2,
                          child: Text(
                            'Employee',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: ResponsiveUtils.getFontSize(
                                context,
                                mobile: 12,
                                tablet: 13,
                                desktop: 14,
                              ),
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
                              fontSize: ResponsiveUtils.getFontSize(
                                context,
                                mobile: 12,
                                tablet: 13,
                                desktop: 14,
                              ),
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
                              fontSize: ResponsiveUtils.getFontSize(
                                context,
                                mobile: 12,
                                tablet: 13,
                                desktop: 14,
                              ),
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
                              fontSize: ResponsiveUtils.getFontSize(
                                context,
                                mobile: 12,
                                tablet: 13,
                                desktop: 14,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: ResponsiveUtils.isTablet(context) ? 2 : 3,
                          child: Text(
                            'Actions',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: ResponsiveUtils.getFontSize(
                                context,
                                mobile: 12,
                                tablet: 13,
                                desktop: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Table Rows - make scrollable
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final viewState = context.findAncestorStateOfType<_ExpensesViewState>();
                        return ListView.builder(
                          shrinkWrap: false,
                          itemCount: expenses.length,
                          itemBuilder: (context, index) {
                            final expense = expenses[index];
                            return _ExpenseTableRow(
                              expense: expense,
                              dateFormatter: dateFormatter,
                              currencyFormatter: currencyFormatter,
                              viewState: viewState,
                            )
                                .animate()
                                .fade(
                                  duration: AnimationUtils.normalDuration,
                                  delay: AnimationUtils.shortDelay * (index + 1),
                                )
                                .slide(
                                  begin: const Offset(0, 20),
                                  end: Offset.zero,
                                  duration: AnimationUtils.normalDuration,
                                  delay: AnimationUtils.shortDelay * (index + 1),
                                  curve: Curves.easeOutCubic,
                                );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ExpenseTableRow extends StatelessWidget {
  const _ExpenseTableRow({
    required this.expense,
    required this.dateFormatter,
    required this.currencyFormatter,
    required this.viewState,
  });

  final ExpenseModel expense;
  final DateFormat dateFormatter;
  final NumberFormat currencyFormatter;
  final _ExpensesViewState? viewState;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: ResponsiveUtils.isTablet(context) ? 2 : 3,
            child: Text(
              expense.description,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: ResponsiveUtils.getFontSize(
                  context,
                  mobile: 12,
                  tablet: 13,
                  desktop: 14,
                ),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: ResponsiveUtils.isTablet(context) ? 1 : 2,
            child: Text(
              expense.category.name,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: ResponsiveUtils.getFontSize(
                  context,
                  mobile: 12,
                  tablet: 13,
                  desktop: 14,
                ),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: ResponsiveUtils.isTablet(context) ? 1 : 2,
            child: Text(
              expense.employeeName,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: ResponsiveUtils.getFontSize(
                  context,
                  mobile: 12,
                  tablet: 13,
                  desktop: 14,
                ),
              ),
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
                fontSize: ResponsiveUtils.getFontSize(
                  context,
                  mobile: 12,
                  tablet: 13,
                  desktop: 14,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              dateFormatter.format(expense.expenseDate),
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: ResponsiveUtils.getFontSize(
                  context,
                  mobile: 12,
                  tablet: 13,
                  desktop: 14,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: _StatusBadge(status: expense.status),
          ),
          Expanded(
            flex: ResponsiveUtils.isTablet(context) ? 2 : 3,
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                // Approve/Reject buttons for pending expenses
                if (expense.status == ExpenseStatus.submitted || 
                    expense.status == ExpenseStatus.underReview ||
                    expense.status == ExpenseStatus.draft)
                  ...[
                ShadTooltip(
                  builder: (context) => const Text('Approve Expense'),
                  child: AppButton(
                    onPressed: () => viewState?._handleApprove(context, expense),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Approve',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                ShadTooltip(
                  builder: (context) => const Text('Reject Expense'),
                  child: AppButton(
                    variant: AppButtonVariant.destructive,
                    onPressed: () => viewState?._handleReject(context, expense),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Reject',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                  ],
                // Edit button
                ShadTooltip(
                  builder: (context) => const Text('Edit Expense'),
                  child: AppButton(
                    variant: AppButtonVariant.outline,
                    onPressed: () => viewState?._handleEdit(context, expense),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Edit',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                // Delete button
                ShadTooltip(
                  builder: (context) => const Text('Delete Expense'),
                  child: ShadIconButton(
                    onPressed: () => viewState?._showDeleteConfirmation(context, expense),
                    icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseMobileCard extends StatelessWidget {
  const _ExpenseMobileCard({
    required this.expense,
    required this.dateFormatter,
    required this.currencyFormatter,
    required this.viewState,
  });

  final ExpenseModel expense;
  final DateFormat dateFormatter;
  final NumberFormat currencyFormatter;
  final _ExpensesViewState? viewState;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expense.category.name,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: expense.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormatter.format(expense.amount),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormatter.format(expense.expenseDate),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Employee',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expense.employeeName,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (expense.status == ExpenseStatus.submitted ||
                  expense.status == ExpenseStatus.underReview ||
                  expense.status == ExpenseStatus.draft)
                ...[
                  AppButton(
                    onPressed: () => viewState?._handleApprove(context, expense),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Approve'),
                      ],
                    ),
                  ),
                  AppButton(
                    variant: AppButtonVariant.destructive,
                    onPressed: () => viewState?._handleReject(context, expense),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Reject'),
                      ],
                    ),
                  ),
                ],
              AppButton(
                variant: AppButtonVariant.outline,
                onPressed: () => viewState?._handleEdit(context, expense),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_outlined, size: 16),
                    SizedBox(width: 4),
                    Text('Edit'),
                  ],
                ),
              ),
              ShadIconButton(
                onPressed: () => viewState?._showDeleteConfirmation(context, expense),
                icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
              ),
            ],
          ),
        ],
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

    switch (status) {
      case ExpenseStatus.approved:
        label = 'Approved';
        break;
      case ExpenseStatus.rejected:
        label = 'Rejected';
        break;
      case ExpenseStatus.submitted:
      case ExpenseStatus.underReview:
        label = 'Pending';
        break;
      case ExpenseStatus.paid:
        label = 'Paid';
        break;
      case ExpenseStatus.draft:
        label = 'Draft';
        break;
    }

    return ShadBadge(
      child: Text(label),
    );
  }
}

