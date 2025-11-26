import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseReceipt {
  const ExpenseReceipt({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.uploadedAt,
    this.fileHash, // For duplicate detection
    this.uploadedBy,
    this.fileType,
    this.thumbnailUrl,
    this.ocrData, // Extracted text from receipt via OCR
  });

  final String id;
  final String fileName;
  final String fileUrl;
  final int fileSize; // in bytes
  final DateTime uploadedAt;
  final String? fileHash; // MD5 or SHA256 hash for duplicate detection
  final String? uploadedBy;
  final String? fileType; // e.g., 'image/jpeg', 'application/pdf'
  final String? thumbnailUrl;
  final Map<String, dynamic>? ocrData; // OCR extracted data (amount, merchant, date, etc.)

  factory ExpenseReceipt.fromMap(Map<String, dynamic> data) {
    return ExpenseReceipt(
      id: data['id'] as String? ?? '',
      fileName: data['fileName'] as String? ?? '',
      fileUrl: data['fileUrl'] as String? ?? '',
      fileSize: data['fileSize'] as int? ?? 0,
      uploadedAt: (data['uploadedAt'] is Timestamp)
          ? (data['uploadedAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['uploadedAt']?.toString() ?? '') ??
              DateTime.now(),
      fileHash: data['fileHash'] as String?,
      uploadedBy: data['uploadedBy'] as String?,
      fileType: data['fileType'] as String?,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      ocrData: data['ocrData'] != null
          ? Map<String, dynamic>.from(data['ocrData'])
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'fileName': fileName,
        'fileUrl': fileUrl,
        'fileSize': fileSize,
        'uploadedAt': Timestamp.fromDate(uploadedAt),
        if (fileHash != null) 'fileHash': fileHash,
        if (uploadedBy != null) 'uploadedBy': uploadedBy,
        if (fileType != null) 'fileType': fileType,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        if (ocrData != null) 'ocrData': ocrData,
      };

  ExpenseReceipt copyWith({
    String? id,
    String? fileName,
    String? fileUrl,
    int? fileSize,
    DateTime? uploadedAt,
    String? fileHash,
    String? uploadedBy,
    String? fileType,
    String? thumbnailUrl,
    Map<String, dynamic>? ocrData,
  }) {
    return ExpenseReceipt(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      fileSize: fileSize ?? this.fileSize,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      fileHash: fileHash ?? this.fileHash,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      fileType: fileType ?? this.fileType,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      ocrData: ocrData ?? this.ocrData,
    );
  }
}

