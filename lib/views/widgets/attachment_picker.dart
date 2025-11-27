import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../components/shadcn/shadcn.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/task_attachment.dart';

class AttachmentPicker extends StatelessWidget {
  const AttachmentPicker({
    super.key,
    required this.attachments,
    this.onAttachmentsChanged,
    this.taskId,
    this.enabled = true,
  });

  final List<TaskAttachment> attachments;
  final ValueChanged<List<TaskAttachment>>? onAttachmentsChanged;
  final String? taskId;
  final bool enabled;

  Future<void> _pickFiles(BuildContext context) async {
    if (!enabled) return;

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null && result.files.isNotEmpty) {
      final newAttachments = result.files.map((file) {
        return TaskAttachment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          fileName: file.name,
          fileUrl: '', // Will be set after upload
          fileSize: file.size,
          uploadedAt: DateTime.now(),
          fileType: file.extension,
        );
      }).toList();

      onAttachmentsChanged?.call([...attachments, ...newAttachments]);
    }
  }

  void _removeAttachment(int index) {
    final updated = List<TaskAttachment>.from(attachments);
    updated.removeAt(index);
    onAttachmentsChanged?.call(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File Upload Area (Drag and Drop Style)
        GestureDetector(
          onTap: enabled ? () => _pickFiles(context) : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl * 2, horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.border,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 48,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Drop items here (or)',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ShadButton(
                  onPressed: enabled ? () => _pickFiles(context) : null,
                  variant: ShadButtonVariant.default_,
                  size: ShadButtonSize.md,
                  child: const Text('Browse files'),
                  disabled: !enabled,
                ),
              ],
            ),
          ),
        ),
        if (attachments.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          ...attachments.asMap().entries.map((entry) {
            final index = entry.key;
            final attachment = entry.value;
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
                    Icon(
                      _getFileIcon(attachment.fileType),
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            attachment.fileName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (attachment.fileSize > 0)
                            Text(
                              _formatFileSize(attachment.fileSize),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (enabled)
                      ShadButton(
                        onPressed: () => _removeAttachment(index),
                        variant: ShadButtonVariant.ghost,
                        size: ShadButtonSize.icon,
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
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

  IconData _getFileIcon(String? fileType) {
    switch (fileType?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}


