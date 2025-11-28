import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

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

  // ============= CHAT ATTACHMENT METHODS =============

  Future<String> uploadChatAttachment({
    required String conversationId,
    required Uint8List fileData,
    required String fileName,
  }) async {
    try {
      if (fileData.isEmpty) {
        throw Exception('File data is empty');
      }

      final fileExtension = fileName.split('.').last;
      final uniqueFileName = '${_uuid.v4()}.$fileExtension';
      final ref = _storage.ref().child('chat/$conversationId/attachments/$uniqueFileName');

      // Set metadata for better organization
      final metadata = SettableMetadata(
        contentType: _getContentType(fileName),
        customMetadata: {
          'originalName': fileName,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('Starting upload: $fileName (${fileData.length} bytes)');
      
      UploadTask uploadTask = ref.putData(fileData, metadata);
      
      // Listen to upload progress
      uploadTask.snapshotEvents.listen((taskSnapshot) {
        final progress = (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) * 100;
        debugPrint('Upload progress: ${progress.toStringAsFixed(1)}%');
      });

      debugPrint('Waiting for upload to complete...');
      
      // Add timeout to prevent infinite hanging
      final snapshot = await uploadTask.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw Exception('Upload timeout: File upload took too long');
        },
      );
      
      debugPrint('Upload completed, getting download URL...');
      
      final downloadUrl = await snapshot.ref.getDownloadURL().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Download URL timeout: Failed to get download URL');
        },
      );
      
      debugPrint('Download URL obtained: $downloadUrl');

      return downloadUrl;
    } catch (e, stackTrace) {
      debugPrint('Upload error: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to upload chat attachment: $e');
    }
  }

  String? _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return null;
    }
  }

  Future<void> deleteChatAttachment(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete chat attachment: $e');
    }
  }
}

