import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../components/shadcn/shadcn.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/expense_receipt.dart';
import '../../services/storage_service.dart';

class ReceiptPicker extends StatefulWidget {
  const ReceiptPicker({
    super.key,
    required this.receipts,
    required this.onReceiptsChanged,
    required this.employeeId,
    this.enabled = true,
  });

  final List<ExpenseReceipt> receipts;
  final ValueChanged<List<ExpenseReceipt>> onReceiptsChanged;
  final String employeeId;
  final bool enabled;

  @override
  State<ReceiptPicker> createState() => _ReceiptPickerState();
}

class _ReceiptPickerState extends State<ReceiptPicker> {
  final _storageService = StorageService();
  final _uuid = const Uuid();
  bool _isUploading = false;

  Future<void> _pickReceipts() async {
    if (!widget.enabled || _isUploading) return;

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _isUploading = true;
      });

      try {
        final newReceipts = <ExpenseReceipt>[];
        
        for (var file in result.files) {
          if (file.bytes != null) {
            // Calculate file hash for duplicate detection
            final fileHash = _storageService.calculateFileHash(
              Uint8List.fromList(file.bytes!),
            );
            
            // Check for duplicates
            // Note: This is a placeholder - in production you'd check against existing receipts
            // For now, we'll just create the receipt with the hash
            
            final receiptId = _uuid.v4();
            final receipt = ExpenseReceipt(
              id: receiptId,
              fileName: file.name,
              fileUrl: '', // Will be set after upload
              fileSize: file.size,
              uploadedAt: DateTime.now(),
              fileHash: fileHash,
              fileType: file.extension,
            );
            
            newReceipts.add(receipt);
          }
        }

        widget.onReceiptsChanged([...widget.receipts, ...newReceipts]);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: ShadAlert(
                title: 'Error',
                description: 'Failed to process receipts: ${e.toString()}',
                variant: ShadAlertVariant.destructive,
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              padding: const EdgeInsets.all(16),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      }
    }
  }

  void _removeReceipt(int index) {
    final updated = List<ExpenseReceipt>.from(widget.receipts);
    updated.removeAt(index);
    widget.onReceiptsChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Receipts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Upload receipt images for this expense',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            ShadButton(
              onPressed: widget.enabled && !_isUploading
                  ? _pickReceipts
                  : null,
              variant: ShadButtonVariant.outline,
              size: ShadButtonSize.sm,
              disabled: !widget.enabled || _isUploading,
              icon: _isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate, size: 18),
              child: const Text('Add Receipts'),
            ),
          ],
        ),
        if (widget.receipts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          ...widget.receipts.asMap().entries.map((entry) {
            final index = entry.key;
            final receipt = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.receipt_long,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            receipt.fileName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _formatFileSize(receipt.fileSize),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          if (receipt.fileHash != null)
                            Text(
                              'Hash: ${receipt.fileHash!.substring(0, 8)}...',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (widget.enabled)
                      ShadButton(
                        onPressed: () => _removeReceipt(index),
                        variant: ShadButtonVariant.ghost,
                        size: ShadButtonSize.icon,
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppColors.danger,
                        ),
                        child: const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

