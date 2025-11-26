import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  Future<String> uploadTaskAttachment({
    required String taskId,
    required String filePath,
    required Uint8List fileData,
    required String fileName,
  }) async {
    try {
      final fileExtension = fileName.split('.').last;
      final uniqueFileName = '${_uuid.v4()}.$fileExtension';
      final ref = _storage.ref().child('tasks/$taskId/attachments/$uniqueFileName');

      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = ref.putData(fileData);
      } else {
        // For mobile, you would use File here
        uploadTask = ref.putData(fileData);
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<void> deleteTaskAttachment(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  String getFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ============= EXPENSE RECEIPT METHODS =============

  Future<String> uploadExpenseReceipt({
    required String expenseId,
    required Uint8List fileData,
    required String fileName,
  }) async {
    try {
      final fileExtension = fileName.split('.').last;
      final uniqueFileName = '${_uuid.v4()}.$fileExtension';
      final ref = _storage.ref().child('expenses/$expenseId/receipts/$uniqueFileName');

      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = ref.putData(fileData);
      } else {
        uploadTask = ref.putData(fileData);
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload receipt: $e');
    }
  }

  // Calculate file hash for duplicate detection
  String calculateFileHash(Uint8List fileData) {
    final digest = sha256.convert(fileData);
    return digest.toString();
  }

  Future<void> deleteExpenseReceipt(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete receipt: $e');
    }
  }
}

