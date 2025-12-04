import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../widgets/shadcn/shadcn_widgets.dart';

class InviteDialog extends StatefulWidget {
  final Function(List<String>, String) onInvite;

  const InviteDialog({super.key, required this.onInvite});

  @override
  State<InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<InviteDialog> {
  final _emailController = TextEditingController();
  String _selectedRole = 'Member';
  final List<String> _roles = ['Member', 'Manager', 'Admin'];

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleInvite() {
    final emails = _emailController.text
        .split(RegExp(r'[,\s]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && _isValidEmail(e))
        .toList();

    if (emails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid email addresses')),
      );
      return;
    }

    widget.onInvite(emails, _selectedRole);
    Navigator.of(context).pop();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Invite people',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.textMuted,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            // Invite by email section
            const Text(
              'Invite by email',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'Email, comma or space separated',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
              ),
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Invite as section
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.people,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'Invite as',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: AppSelect<String>(
                placeholder: 'Select Role',
                value: _selectedRole,
                options: SelectOption.fromStringList(_roles),
                selectedOptionBuilder: (context, value) => Text(value ?? 'Select Role'),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRole = value);
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _getRoleDescription(_selectedRole),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  onPressed: _handleInvite,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Send invite'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleDescription(String role) {
    switch (role) {
      case 'Member':
        return 'Can access all public items in your Workspace.';
      case 'Manager':
        return 'Can manage team members and access all workspace items.';
      case 'Admin':
        return 'Full access to workspace settings and all features.';
      default:
        return 'Can access all public items in your Workspace.';
    }
  }
}

