import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../services/user_migration_service.dart';

class MigrateUsersDialog extends StatefulWidget {
  const MigrateUsersDialog({super.key});

  @override
  State<MigrateUsersDialog> createState() => _MigrateUsersDialogState();
}

class _MigrateUsersDialogState extends State<MigrateUsersDialog> {
  final _migrationService = UserMigrationService();
  MigrationStatus? _status;
  List<MigrationResult>? _results;
  bool _isLoading = false;
  bool _isMigrating = false;
  final TextEditingController _passwordController = TextEditingController(
    text: 'TempPassword123!',
  );
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoading = true);
    try {
      final status = await _migrationService.getMigrationStatus();
      setState(() {
        _status = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading status: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _startMigration() async {
    if (_passwordController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() {
      _isMigrating = true;
      _results = null;
    });

    try {
      final results = await _migrationService.migrateUsers(
        defaultPassword: _passwordController.text.trim(),
      );

      setState(() {
        _results = results;
        _isMigrating = false;
      });

      // Reload status
      await _loadStatus();

      if (mounted) {
        final successCount = results.where((r) => r.success).length;
        final failCount = results.where((r) => !r.success).length;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Migration complete: $successCount succeeded, $failCount failed',
            ),
            backgroundColor: failCount == 0 ? AppColors.success : AppColors.warning,
          ),
        );
      }
    } catch (e) {
      setState(() => _isMigrating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Migration failed: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Migrate Users to Firebase Auth',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'This will create Firebase Authentication accounts for existing users so they can sign in and use the chat feature.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_status != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Migration Status',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildStatRow('Total Users', '${_status!.totalUsers}'),
                    _buildStatRow(
                      'With Auth Accounts',
                      '${_status!.withAuthAccounts}',
                      color: AppColors.success,
                    ),
                    _buildStatRow(
                      'Need Migration',
                      '${_status!.withoutAuthAccounts}',
                      color: AppColors.warning,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_status!.withoutAuthAccounts > 0) ...[
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Default Password for New Accounts',
                    hintText: 'Users will need to change this on first login',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  '⚠️ Users will receive this temporary password. They should change it on first login.',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isMigrating ? null : _startMigration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isMigrating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Start Migration'),
                  ),
                ),
              ] else
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success),
                      const SizedBox(width: AppSpacing.sm),
                      const Text(
                        'All users have Auth accounts!',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
            if (_results != null) ...[
              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Migration Results',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results!.length,
                  itemBuilder: (context, index) {
                    final result = _results![index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: result.success
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            result.success
                                ? Icons.check_circle
                                : Icons.error,
                            color: result.success
                                ? AppColors.success
                                : AppColors.danger,
                            size: 16,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  result.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  result.email,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                if (result.message.isNotEmpty)
                                  Text(
                                    result.message,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isMigrating
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textMuted)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

