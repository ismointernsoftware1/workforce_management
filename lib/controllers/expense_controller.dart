import '../models/expense_model.dart';
import '../models/expense_category.dart';
import '../models/reimbursement_model.dart';
import '../services/firebase_service.dart';

class ExpenseController {
  const ExpenseController(this._service);

  final FirebaseService _service;

  Future<List<ExpenseModel>> fetchExpenses({String? employeeId}) =>
      _service.fetchExpenses(employeeId: employeeId);

  Future<String> createExpense(ExpenseModel expense) =>
      _service.addExpense(expense);

  Future<void> updateExpense(ExpenseModel expense) =>
      _service.updateExpense(expense);

  Future<void> deleteExpense(String expenseId) =>
      _service.deleteExpense(expenseId);

  Future<void> updateExpenseStatus(String expenseId, ExpenseStatus status) =>
      _service.updateExpenseStatus(expenseId, status);

  Future<bool> checkDuplicateReceipt(String fileHash, String employeeId) =>
      _service.checkDuplicateReceipt(fileHash, employeeId);

  Future<List<ExpenseCategory>> fetchCategories() =>
      _service.fetchExpenseCategories();

  Future<List<ReimbursementModel>> fetchReimbursements({String? employeeId}) =>
      _service.fetchReimbursements(employeeId: employeeId);

  Future<String> createReimbursement(ReimbursementModel reimbursement) =>
      _service.addReimbursement(reimbursement);

  Future<void> updateReimbursement(ReimbursementModel reimbursement) =>
      _service.updateReimbursement(reimbursement);
}

