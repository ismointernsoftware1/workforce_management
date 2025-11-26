import 'dart:convert';
import 'package:http/http.dart' as http;

/// SendGrid email service for sending invitation emails
/// 
/// To use this service:
/// 1. Get your SendGrid API key from https://app.sendgrid.com/settings/api_keys
/// 2. Set it as an environment variable or store it securely
/// 3. For production, use Firebase Remote Config or secure storage
class SendGridService {
  SendGridService({String? apiKey})
      : _apiKey = apiKey ?? _getApiKeyFromEnv();

  final String? _apiKey;
  static const String _sendGridUrl = 'https://api.sendgrid.com/v3/mail/send';

  /// Gets API key from environment or returns null
  /// In production, use Firebase Remote Config or secure storage
  static String? _getApiKeyFromEnv() {
    // TODO: Replace with your actual SendGrid API key
    // For now, you can set it as an environment variable or use secure storage
    // Example: return const String.fromEnvironment('SENDGRID_API_KEY');
    return null; // Will throw error if not set
  }

  /// Sends an invitation email via SendGrid
  Future<void> sendInvitationEmail({
    required String toEmail,
    required String role,
    required String invitationId,
    String? inviterName,
    String? inviterEmail,
  }) async {
    if (_apiKey == null || _apiKey.isEmpty) {
      throw Exception(
          'SendGrid API key not configured. Please set your API key.');
    }

    // Generate invitation link
    // For web: https://yourapp.com/invite/accept?token=INVITATION_ID
    // For mobile: yourapp://invite/accept?token=INVITATION_ID
    // TODO: Replace with your actual app URL
    final invitationLink =
        'https://yourapp.com/invite/accept?token=$invitationId';

    final emailContent = _buildEmailContent(
      role: role,
      invitationLink: invitationLink,
      inviterName: inviterName ?? 'Team',
    );

    final requestBody = {
      'personalizations': [
        {
          'to': [
            {'email': toEmail}
          ],
          'subject': 'You\'ve been invited to join the team!'
        }
      ],
      'from': {
        'email': 'ismointernsoftware1@gmail.com', // Verified SendGrid sender identity
        'name': 'Workforce Management'
      },
      'content': [
        {
          'type': 'text/html',
          'value': emailContent
        }
      ]
    };

    try {
      final response = await http.post(
        Uri.parse(_sendGridUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return; // Success
      } else {
        throw Exception(
            'SendGrid API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to send email via SendGrid: $e');
    }
  }

  /// Builds HTML email content for invitation
  String _buildEmailContent({
    required String role,
    required String invitationLink,
    required String inviterName,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
  <div style="background-color: #f8f9fa; padding: 30px; border-radius: 8px;">
    <h2 style="color: #2563eb; margin-top: 0;">You've been invited!</h2>
    <p>Hello,</p>
    <p><strong>$inviterName</strong> has invited you to join the Workforce Management workspace as a <strong>$role</strong>.</p>
    <p>Click the button below to accept the invitation and get started:</p>
    <div style="text-align: center; margin: 30px 0;">
      <a href="$invitationLink" 
         style="background-color: #2563eb; color: white; padding: 12px 30px; 
                text-decoration: none; border-radius: 6px; display: inline-block; 
                font-weight: bold;">
        Accept Invitation
      </a>
    </div>
    <p style="color: #666; font-size: 14px;">
      If the button doesn't work, copy and paste this link into your browser:<br>
      <a href="$invitationLink" style="color: #2563eb;">$invitationLink</a>
    </p>
    <p style="color: #666; font-size: 14px; margin-top: 30px;">
      This invitation will expire in 7 days.
    </p>
  </div>
</body>
</html>
''';
  }
}

