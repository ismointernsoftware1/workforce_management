import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/app_user.dart';
import '../../models/invite_model.dart';
import '../../services/invite_service.dart';
import '../../services/user_service.dart';
import '../../widgets/shadcn/app_button.dart';
import '../auth/login_view.dart';

/// InviteAcceptSignupPage - handles signup with role assignment from invite
class InviteAcceptSignupPage extends StatefulWidget {
  const InviteAcceptSignupPage({
    super.key,
    required this.token,
  });

  final String token;

  @override
  State<InviteAcceptSignupPage> createState() => _InviteAcceptSignupPageState();
}

class _InviteAcceptSignupPageState extends State<InviteAcceptSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _inviteService = InviteService();
  final _userService = UserService();
  final _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  bool _isProcessing = false;
  InviteModel? _invite;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _validateToken();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _validateToken() async {
    try {
      final invite = await _inviteService.validateInviteToken(widget.token);

      if (!mounted) return;

      if (invite == null || !invite.isValid) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid or expired invitation';
        });
      } else {
        setState(() {
          _isLoading = false;
          _invite = invite;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error verifying invitation: ${e.toString()}';
      });
    }
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_invite == null) {
      _showError('Invalid invitation');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: _invite!.email,
        password: _passwordController.text.trim(),
      );

      if (credential.user == null) {
        throw Exception('Failed to create user');
      }

      // Update user display name
      await credential.user!.updateDisplayName(_nameController.text.trim());
      await credential.user!.reload();

      // Create AppUser document with role
      await _userService.createAppUser(
        AppUser(
          uid: credential.user!.uid,
          email: _invite!.email,
          roleId: _invite!.roleId,
        ),
      );

      // Mark invite as used
      await _inviteService.markInviteUsed(_invite!.inviteId, credential.user!.uid);

      if (!mounted) return;

      // Navigate to login (user needs to sign in with new credentials)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginView(),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully! Please sign in.'),
          backgroundColor: AppColors.success,
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to create account';
      if (e.code == 'weak-password') {
        errorMessage = 'Password is too weak';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email is already registered. Please sign in instead.';
      }
      _showError(errorMessage);
    } catch (e) {
      _showError('Error creating account: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: _isLoading
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: AppSpacing.lg),
                    Text(
                      'Verifying invitation...',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                )
              : _errorMessage != null
                  ? _buildErrorState()
                  : _buildSignupForm(),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline,
          size: 64,
          color: AppColors.danger,
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Invalid Invitation',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _errorMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginView()),
          ),
          child: const Text('Go to Login'),
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.person_add_outlined,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Create Your Account',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'You\'ve been invited to join with email: ${_invite!.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Name field
            TextFormField(
              controller: _nameController,
              enabled: !_isProcessing,
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            // Password field
            TextFormField(
              controller: _passwordController,
              enabled: !_isProcessing,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.lock),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            // Confirm Password field
            TextFormField(
              controller: _confirmPasswordController,
              enabled: !_isProcessing,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Confirm your password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              onPressed: _isProcessing ? null : _handleSignup,
              isLoading: _isProcessing,
              fullWidth: true,
              child: const Text('Create Account'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: _isProcessing
                  ? null
                  : () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const LoginView()),
                      ),
              child: const Text('Already have an account? Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}

