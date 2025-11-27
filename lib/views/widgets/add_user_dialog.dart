import 'dart:math';

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/user_model.dart';

class AddUserDialog extends StatefulWidget {
  const AddUserDialog({
    super.key,
    required this.onSave,
    this.initialUser,
  });

  final Future<void> Function(UserModel user, {String? password}) onSave;
  final UserModel? initialUser;

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _roleController = TextEditingController();
  final _passwordController = TextEditingController();
  late DateTime _joinDate;
  late String _status;
  bool _isSaving = false;
  bool _obscurePassword = true;

  bool get _isEditing => widget.initialUser != null;

  @override
  void initState() {
    super.initState();
    final user = widget.initialUser;
    _nameController.text = user?.name ?? '';
    _emailController.text = user?.email ?? '';
    _roleController.text = user?.role ?? '';
    _joinDate = user?.joinDate ?? DateTime.now();
    _status = user?.status ?? 'Active';
    if (!_isEditing) {
      _passwordController.text = _generatePassword();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _generatePassword() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789@#%&*?';
    final rand = Random.secure();
    return List.generate(10, (index) => chars[rand.nextInt(chars.length)])
        .join();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    
    // For new users, password is required
    if (!_isEditing && _passwordController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password is required for new users'),
            backgroundColor: AppColors.danger,
          ),
        );
        setState(() => _isSaving = false);
      }
      return;
    }
    
    final user = UserModel(
      id: widget.initialUser?.id ?? '',
      name: _nameController.text.trim(),
      role: _roleController.text.trim(),
      department: widget.initialUser?.department ?? 'General',
      email: _emailController.text.trim(),
      status: _status,
      joinDate: _joinDate,
      manager: widget.initialUser?.manager,
      team: widget.initialUser?.team,
    );
    
    try {
      // Pass password for new users
      final password = _isEditing ? null : _passwordController.text.trim();
      await widget.onSave(user, password: password);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing 
                ? 'User updated successfully' 
                : 'User created successfully. They can now sign in with their email and password.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${_isEditing ? 'update' : 'add'} user: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : (isWide ? 120 : 40),
        vertical: isMobile ? 20 : 60,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: const Color(0xFFF4F5FA),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isWide ? 900 : MediaQuery.of(context).size.width * 0.9,
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditing ? 'Edit User' : 'Add User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: isWide ? 400 : double.infinity,
                      child: _buildTextField(
                        controller: _nameController,
                        label: 'Full name',
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Required'
                                : null,
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 400 : double.infinity,
                      child: _buildTextField(
                        controller: _roleController,
                        label: 'Role',
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Required'
                                : null,
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 400 : double.infinity,
                      child: _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          if (!value.contains('@')) {
                            return 'Invalid email';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (!_isEditing)
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Generate password',
                                icon: const Icon(Icons.refresh),
                                onPressed: () {
                                  setState(() {
                                    _passwordController.text =
                                        _generatePassword();
                                  });
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(
                                      () => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!_isEditing)
                      const Text(
                        'Share this temporary password with the user; they should change it after first login.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    SizedBox(
                      width: isWide ? 400 : double.infinity,
                      child: DropdownButtonFormField<String>(
                        decoration: _inputDecoration('Status'),
                        value: _status,
                        items: const [
                          DropdownMenuItem(
                            value: 'Active',
                            child: Text('Active'),
                          ),
                          DropdownMenuItem(
                            value: 'On leave',
                            child: Text('On leave'),
                          ),
                          DropdownMenuItem(
                            value: 'Inactive',
                            child: Text('Inactive'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _status = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 400;
                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            onPressed: _isSaving ? null : _handleSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(_isEditing ? 'Save Changes' : 'Add User'),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _isSaving
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ],
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: TextButton(
                            onPressed: _isSaving
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _handleSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(_isEditing ? 'Save Changes' : 'Add User'),
                                  ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextFormField _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label, suffixIcon: suffixIcon),
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
    );
  }

  InputDecoration _inputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      suffixIcon: suffixIcon,
    );
  }
}

