import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/invite_model.dart';
import '../../services/invite_service.dart';
import '../../widgets/shadcn/app_button.dart';

class AcceptInviteScreen extends StatefulWidget {
  const AcceptInviteScreen({
    super.key,
    required this.token,
  });

  final String token;

  @override
  State<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends State<AcceptInviteScreen> {
  final _inviteService = InviteService();
  bool _isLoading = true;
  bool _isProcessing = false;
  InviteModel? _invite;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _verifyToken();
  }

  Future<void> _verifyToken() async {
    try {
      final invite = await _inviteService.validateInviteToken(widget.token);
      
      if (!mounted) return;

      if (invite == null) {
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

  Future<void> _handleAcceptInvite() async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      // User not logged in - redirect to login/signup
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final success = await _inviteService.markInviteUsed(
        _invite!.inviteId,
        user.uid,
      );

      if (!mounted) return;

      if (success) {
        // Navigate to dashboard
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Failed to accept invitation. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
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
                  : _buildInviteAcceptState(),
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
          onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
          child: const Text('Go to Login'),
        ),
      ],
    );
  }

  Widget _buildInviteAcceptState() {
    final email = _invite!.email;
    final user = FirebaseAuth.instance.currentUser;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.mail_outline,
          size: 64,
          color: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'You\'re Invited!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'You have been invited to join the workspace',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.email, size: 20, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (user == null) ...[
          const Text(
            'Please sign in or create an account to accept this invitation.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
            fullWidth: true,
            child: const Text('Sign In / Sign Up'),
          ),
        ] else ...[
          AppButton(
            onPressed: _isProcessing ? null : _handleAcceptInvite,
            isLoading: _isProcessing,
            fullWidth: true,
            child: const Text('Accept Invitation'),
          ),
        ],
      ],
    );
  }
}

