import 'package:cloud_firestore/cloud_firestore.dart';

class TaskAttachment {
  const TaskAttachment({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.uploadedAt,
    this.uploadedBy,
    this.fileType,
  });

  final String id;
  final String fileName;
  final String fileUrl;
  final int fileSize; // in bytes
  final DateTime uploadedAt;
  final String? uploadedBy;
  final String? fileType; // e.g., 'image/jpeg', 'application/pdf'

  factory TaskAttachment.fromMap(Map<String, dynamic> data) {
    return TaskAttachment(
      id: data['id'] as String? ?? '',
      fileName: data['fileName'] as String? ?? '',
      fileUrl: data['fileUrl'] as String? ?? '',
      fileSize: data['fileSize'] as int? ?? 0,
      uploadedAt: (data['uploadedAt'] is Timestamp)
          ? (data['uploadedAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['uploadedAt']?.toString() ?? '') ??
              DateTime.now(),
      uploadedBy: data['uploadedBy'] as String?,
      fileType: data['fileType'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'fileName': fileName,
        'fileUrl': fileUrl,
        'fileSize': fileSize,
        'uploadedAt': Timestamp.fromDate(uploadedAt),
        if (uploadedBy != null) 'uploadedBy': uploadedBy,
        if (fileType != null) 'fileType': fileType,
      };

  TaskAttachment copyWith({
    String? id,
    String? fileName,
    String? fileUrl,
    int? fileSize,
    DateTime? uploadedAt,
    String? uploadedBy,
    String? fileType,
  }) {
    return TaskAttachment(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      fileSize: fileSize ?? this.fileSize,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      fileType: fileType ?? this.fileType,
    );
  }
}

