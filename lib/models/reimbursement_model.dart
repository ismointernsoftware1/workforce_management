import 'package:cloud_firestore/cloud_firestore.dart';

class ReimbursementModel {
  const ReimbursementModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.expenseIds,
    required this.totalAmount,
    required this.currency,
    required this.submittedDate,
    required this.status,
    this.paidDate,
    this.paymentMethod,
    this.paymentReference,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final List<String> expenseIds; // List of expense IDs in this reimbursement
  final double totalAmount;
  final String currency;
  final DateTime submittedDate;
  final ReimbursementStatus status;
  final DateTime? paidDate;
  final String? paymentMethod;
  final String? paymentReference; // Transaction ID, check number, etc.
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ReimbursementModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? <String, dynamic>{};
    return ReimbursementModel.fromMap(data, id: snap.id);
  }

  factory ReimbursementModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return ReimbursementModel(
      id: id ?? data['id'] as String? ?? '',
      employeeId: data['employeeId'] as String? ?? '',
      employeeName: data['employeeName'] as String? ?? '',
      expenseIds: (data['expenseIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'USD',
      submittedDate: (data['submittedDate'] is Timestamp)
          ? (data['submittedDate'] as Timestamp).toDate()
          : DateTime.tryParse(data['submittedDate']?.toString() ?? '') ??
              DateTime.now(),
      status: _statusFrom(data['status']),
      paidDate: data['paidDate'] != null
          ? (data['paidDate'] is Timestamp)
              ? (data['paidDate'] as Timestamp).toDate()
              : DateTime.tryParse(data['paidDate']?.toString() ?? '')
          : null,
      paymentMethod: data['paymentMethod'] as String?,
      paymentReference: data['paymentReference'] as String?,
      notes: data['notes'] as String?,
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
    );
  }

  Map<String, dynamic> toMap() => {
        'employeeId': employeeId,
        'employeeName': employeeName,
        'expenseIds': expenseIds,
        'totalAmount': totalAmount,
        'currency': currency,
        'submittedDate': Timestamp.fromDate(submittedDate),
        'status': status.name,
        if (paidDate != null) 'paidDate': Timestamp.fromDate(paidDate!),
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (paymentReference != null) 'paymentReference': paymentReference,
        if (notes != null) 'notes': notes,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
        if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      };
}

enum ReimbursementStatus {
  draft,
  submitted,
  underReview,
  approved,
  paid,
  rejected,
  cancelled,
}

ReimbursementStatus _statusFrom(dynamic raw) {
  final value = raw?.toString().toLowerCase() ?? 'draft';
  return ReimbursementStatus.values.firstWhere(
    (s) => s.name.toLowerCase() == value,
    orElse: () => ReimbursementStatus.draft,
  );
}

