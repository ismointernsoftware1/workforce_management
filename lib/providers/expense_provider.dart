import 'package:flutter/foundation.dart';

import '../controllers/expense_controller.dart';
import '../models/expense_model.dart';
import '../models/expense_category.dart';

class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider({
    required ExpenseController expenseController,
  }) : _expenseController = expenseController;

  final ExpenseController _expenseController;

  bool isLoading = false;
  String? lastError;

  List<ExpenseModel> expenses = const [];
  List<ExpenseCategory> categories = const [];

  String statusFilter = 'All';
  static const List<String> statusFilters = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
  ];

  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();

    try {
      expenses = await _expenseController.fetchExpenses();
      categories = await _expenseController.fetchCategories();
      lastError = null;
    } catch (error) {
      lastError = error.toString();
      expenses = [];
      // On error, still try to get default categories
      try {
        categories = await _expenseController.fetchCategories();
      } catch (_) {
        categories = [];
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> loadCategories() async {
    if (categories.isNotEmpty) return; // Already loaded
    
    try {
      categories = await _expenseController.fetchCategories();
      notifyListeners();
    } catch (error) {
      print('Error loading categories: $error');
    }
  }

  List<ExpenseModel> get filteredExpenses {
    switch (statusFilter) {
      case 'Pending':
        return expenses
            .where((expense) =>
                expense.status == ExpenseStatus.submitted ||
                expense.status == ExpenseStatus.underReview)
            .toList();
      case 'Approved':
        return expenses
            .where((expense) => expense.status == ExpenseStatus.approved)
            .toList();
      case 'Rejected':
        return expenses
            .where((expense) => expense.status == ExpenseStatus.rejected)
            .toList();
      default:
        return expenses;
    }
  }

  double get totalAmount =>
      expenses.fold(0.0, (sum, expense) => sum + expense.amount);

  double get approvedAmount => expenses
      .where((expense) => expense.status == ExpenseStatus.approved)
      .fold(0.0, (sum, expense) => sum + expense.amount);

  double get pendingAmount => expenses
      .where((expense) =>
          expense.status == ExpenseStatus.submitted ||
          expense.status == ExpenseStatus.underReview)
      .fold(0.0, (sum, expense) => sum + expense.amount);

  void changeStatusFilter(String filter) {
    statusFilter = filter;
    notifyListeners();
  }

  Future<void> addExpense(ExpenseModel expense) async {
    try {
      await _expenseController.createExpense(expense);
      expenses = await _expenseController.fetchExpenses();
      notifyListeners();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      await _expenseController.updateExpense(expense);
      expenses = await _expenseController.fetchExpenses();
      notifyListeners();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      await _expenseController.deleteExpense(expenseId);
      expenses = await _expenseController.fetchExpenses();
      notifyListeners();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> refreshExpenses() async {
    try {
      expenses = await _expenseController.fetchExpenses();
      lastError = null;
      notifyListeners();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
    }
  }

  Future<bool> checkDuplicateReceipt(String fileHash, String employeeId) async {
    try {
      return await _expenseController.checkDuplicateReceipt(fileHash, employeeId);
    } catch (error) {
      print('Error checking duplicate receipt: $error');
      return false;
    }
  }
}

