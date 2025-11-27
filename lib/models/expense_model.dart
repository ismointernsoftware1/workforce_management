import 'package:cloud_firestore/cloud_firestore.dart';

import 'expense_receipt.dart';
import 'expense_approval.dart';
import 'expense_category.dart';

enum ExpenseStatus { draft, submitted, underReview, approved, rejected, paid }

enum ExpenseType { receipt, mileage, other }

class ExpenseModel {
  const ExpenseModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.amount,
    required this.currency,
    required this.expenseDate,
    required this.description,
    required this.category,
    required this.status,
    required this.expenseType,
    required this.receipts,
    required this.approvals,
    this.mileage,
    this.reimbursementId,
    this.createdAt,
    this.updatedAt,
    this.duplicateFlag,
    this.duplicateReason,
    this.taxAmount,
    this.merchant,
    this.paymentMethod,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final double amount;
  final String currency;
  final DateTime expenseDate;
  final String description;
  final ExpenseCategory category;
  final ExpenseStatus status;
  final ExpenseType expenseType;
  final List<ExpenseReceipt> receipts;
  final List<ExpenseApproval> approvals;
  final ExpenseMileage? mileage;
  final String? reimbursementId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? duplicateFlag;
  final String? duplicateReason;
  final double? taxAmount;
  final String? merchant;
  final String? paymentMethod;

  factory ExpenseModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? <String, dynamic>{};
    return ExpenseModel.fromMap(data, id: snap.id);
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return ExpenseModel(
      id: id ?? data['id'] as String? ?? '',
      employeeId: data['employeeId'] as String? ?? '',
      employeeName: data['employeeName'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'USD',
      expenseDate: (data['expenseDate'] is Timestamp)
          ? (data['expenseDate'] as Timestamp).toDate()
          : DateTime.tryParse(data['expenseDate']?.toString() ?? '') ??
              DateTime.now(),
      description: data['description'] as String? ?? '',
      category: ExpenseCategory.fromMap(Map<String, dynamic>.from(data['category'] ?? {})),
      status: _statusFrom(data['status']),
      expenseType: _typeFrom(data['expenseType']),
      receipts: ((data['receipts'] as List<dynamic>?) ?? [])
          .map((r) => ExpenseReceipt.fromMap(Map<String, dynamic>.from(r)))
          .toList(),
      approvals: ((data['approvals'] as List<dynamic>?) ?? [])
          .map((a) => ExpenseApproval.fromMap(Map<String, dynamic>.from(a)))
          .toList(),
      mileage: data['mileage'] != null
          ? ExpenseMileage.fromMap(Map<String, dynamic>.from(data['mileage']))
          : null,
      reimbursementId: data['reimbursementId'] as String?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp)
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['createdAt']?.toString() ?? '')
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp)
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['updatedAt']?.toString() ?? '')
          : null,
      duplicateFlag: data['duplicateFlag'] as bool?,
      duplicateReason: data['duplicateReason'] as String?,
      taxAmount: (data['taxAmount'] as num?)?.toDouble(),
      merchant: data['merchant'] as String?,
      paymentMethod: data['paymentMethod'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'employeeId': employeeId,
        'employeeName': employeeName,
        'amount': amount,
        'currency': currency,
        'expenseDate': Timestamp.fromDate(expenseDate),
        'description': description,
        'category': category.toMap(),
        'status': status.name,
        'expenseType': expenseType.name,
        'receipts': receipts.map((r) => r.toMap()).toList(),
        'approvals': approvals.map((a) => a.toMap()).toList(),
        if (mileage != null) 'mileage': mileage!.toMap(),
        if (reimbursementId != null) 'reimbursementId': reimbursementId,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
        if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
        if (duplicateFlag != null) 'duplicateFlag': duplicateFlag,
        if (duplicateReason != null) 'duplicateReason': duplicateReason,
        if (taxAmount != null) 'taxAmount': taxAmount,
        if (merchant != null) 'merchant': merchant,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
      };

  ExpenseModel copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    double? amount,
    String? currency,
    DateTime? expenseDate,
    String? description,
    ExpenseCategory? category,
    ExpenseStatus? status,
    ExpenseType? expenseType,
    List<ExpenseReceipt>? receipts,
    List<ExpenseApproval>? approvals,
    ExpenseMileage? mileage,
    String? reimbursementId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? duplicateFlag,
    String? duplicateReason,
    double? taxAmount,
    String? merchant,
    String? paymentMethod,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      expenseDate: expenseDate ?? this.expenseDate,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      expenseType: expenseType ?? this.expenseType,
      receipts: receipts ?? this.receipts,
      approvals: approvals ?? this.approvals,
      mileage: mileage ?? this.mileage,
      reimbursementId: reimbursementId ?? this.reimbursementId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      duplicateFlag: duplicateFlag ?? this.duplicateFlag,
      duplicateReason: duplicateReason ?? this.duplicateReason,
      taxAmount: taxAmount ?? this.taxAmount,
      merchant: merchant ?? this.merchant,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}

ExpenseStatus _statusFrom(dynamic raw) {
  final value = raw?.toString().toLowerCase() ?? 'draft';
  return ExpenseStatus.values.firstWhere(
    (s) => s.name.toLowerCase() == value,
    orElse: () => ExpenseStatus.draft,
  );
}

ExpenseType _typeFrom(dynamic raw) {
  final value = raw?.toString().toLowerCase() ?? 'receipt';
  return ExpenseType.values.firstWhere(
    (t) => t.name.toLowerCase() == value,
    orElse: () => ExpenseType.receipt,
  );
}

class ExpenseMileage {
  const ExpenseMileage({
    required this.distance,
    required this.rate,
    required this.startLocation,
    required this.endLocation,
    required this.purpose,
    this.startDate,
    this.endDate,
  });

  final double distance;
  final double rate;
  final String startLocation;
  final String endLocation;
  final String purpose;
  final DateTime? startDate;
  final DateTime? endDate;

  double get totalAmount => distance * rate;

  factory ExpenseMileage.fromMap(Map<String, dynamic> data) {
    return ExpenseMileage(
      distance: (data['distance'] as num?)?.toDouble() ?? 0.0,
      rate: (data['rate'] as num?)?.toDouble() ?? 0.0,
      startLocation: data['startLocation'] as String? ?? '',
      endLocation: data['endLocation'] as String? ?? '',
      purpose: data['purpose'] as String? ?? '',
      startDate: data['startDate'] != null
          ? (data['startDate'] is Timestamp)
              ? (data['startDate'] as Timestamp).toDate()
              : DateTime.tryParse(data['startDate']?.toString() ?? '')
          : null,
      endDate: data['endDate'] != null
          ? (data['endDate'] is Timestamp)
              ? (data['endDate'] as Timestamp).toDate()
              : DateTime.tryParse(data['endDate']?.toString() ?? '')
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'distance': distance,
        'rate': rate,
        'startLocation': startLocation,
        'endLocation': endLocation,
        'purpose': purpose,
        if (startDate != null) 'startDate': Timestamp.fromDate(startDate!),
        if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      };
}

