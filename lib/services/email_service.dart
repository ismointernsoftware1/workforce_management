import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sendgrid_service.dart';

/// Email service for sending invitation emails using SendGrid
class EmailService {
  EmailService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    SendGridService? sendGridService,
    String? sendGridApiKey,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _sendGridService = sendGridService ?? SendGridService(apiKey: sendGridApiKey);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final SendGridService _sendGridService;

  /// Sends invitation email to a single recipient using SendGrid
  Future<void> sendInvitationEmail({
    required String email,
    required String role,
    String? invitedBy,
  }) async {
    try {
      // Get current user email for the invitation
      final currentUser = _auth.currentUser;
      final inviterEmail = currentUser?.email ?? 'system';
      final inviterName = currentUser?.displayName ?? 'Team';

      // Create invitation document with unique ID
      final invitationRef = _firestore.collection('invitations').doc();
      final invitationId = invitationRef.id;

      await invitationRef.set({
        'id': invitationId,
        'email': email.trim(),
        'role': role,
        'status': 'pending',
        'invitedAt': FieldValue.serverTimestamp(),
        'invitedBy': invitedBy ?? currentUser?.uid,
        'inviterEmail': inviterEmail,
        'inviterName': inviterName,
        'emailSent': false,
      });

      // Send email via SendGrid
      try {
        await _sendGridService.sendInvitationEmail(
          toEmail: email.trim(),
          role: role,
          invitationId: invitationId,
          inviterName: inviterName,
          inviterEmail: inviterEmail,
        );

        // Update invitation to mark email as sent
        await invitationRef.update({
          'emailSent': true,
          'emailSentAt': FieldValue.serverTimestamp(),
        });
      } catch (emailError) {
        // Log email error but keep invitation in database
        print('Failed to send email via SendGrid: $emailError');
        // Still update to indicate we tried
        await invitationRef.update({
          'emailSent': false,
          'emailError': emailError.toString(),
        });
        // Re-throw to notify caller
        throw Exception('Failed to send email: $emailError');
      }
    } catch (e) {
      throw Exception('Failed to send invitation email: $e');
    }
  }

  /// Sends invitation emails to multiple recipients using SendGrid
  Future<void> sendMultipleInvitationEmails({
    required List<String> emails,
    required String role,
    String? invitedBy,
  }) async {
    // Send emails one by one (SendGrid handles rate limiting)
    for (final email in emails) {
      try {
        await sendInvitationEmail(
          email: email,
          role: role,
          invitedBy: invitedBy,
        );
      } catch (e) {
        // Log error but continue with other emails
        print('Failed to send invitation to $email: $e');
        // Continue with next email
      }
    }
  }

  /// Generates invitation link (for use in email templates)
  String generateInvitationLink(String invitationId) {
    // In production, this would be your app's deep link or web URL
    return 'https://yourapp.com/invite/$invitationId';
  }
}

