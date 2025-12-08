import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class InviteService {
  InviteService({
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();
  
  // Brevo API configuration
  static const String _brevoApiKey = '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';
  static const String _brevoApiUrl = 'https://api.brevo.com/v3/smtp/email';
  static const String _senderEmail = 'ismointernsoftware1@gmail.com';
  static const String _senderName = 'workforce';
  
  // Alternative: Use transactional email API if SMTP is not activated
  // static const String _brevoApiUrl = 'https://api.brevo.com/v3/transactionalEmails';

  /// Get current workspace ID
  /// For now, we'll use a default workspace or get it from user's team
  /// You can customize this based on your workspace structure
  Future<String> _getCurrentWorkspaceId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Try to get workspace from user's document
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data['workspaceId'] != null) {
          return data['workspaceId'] as String;
        }
      }

      // If no workspace found, use default or create one
      // For now, return a default workspace ID
      // You should implement proper workspace management
      return 'default-workspace';
    } catch (e) {
      debugPrint('Error getting workspace ID: $e');
      return 'default-workspace';
    }
  }

  /// Send invitation email directly via Brevo API (no Cloud Functions needed)
  Future<bool> sendInvite(String email) async {
    try {
      final workspaceId = await _getCurrentWorkspaceId();
      debugPrint('Sending invite to $email for workspace $workspaceId');

      // Generate secure token
      final token = _uuid.v4();
      final inviteLink = 'https://workforce-f9e89.web.app/invite?token=$token';

      // Save invitation to Firestore first
      final inviteRef = _firestore.collection('invites').doc();
      await inviteRef.set({
        'email': email.toLowerCase().trim(),
        'workspaceId': workspaceId,
        'token': token,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'invitedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });

      debugPrint('Invitation saved to Firestore with ID: ${inviteRef.id}');

      // Send email via Brevo API
      final emailBody = {
        'sender': {
          'name': _senderName,
          'email': _senderEmail,
        },
        'to': [
          {'email': email}
        ],
        'subject': "You're invited to join the Workspace!",
        'htmlContent': '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Workspace Invitation</title>
</head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
  <div style="background-color: #f8f9fa; padding: 30px; border-radius: 10px;">
    <h1 style="color: #2563eb; margin-top: 0;">You're Invited!</h1>
    <p>You have been invited to join a workspace.</p>
    <p>Click the button below to accept your invitation:</p>
    <div style="text-align: center; margin: 30px 0;">
      <a href="$inviteLink" 
         style="display: inline-block; background-color: #2563eb; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: bold;">
        Accept Invitation
      </a>
    </div>
    <p style="font-size: 12px; color: #666; margin-top: 30px;">
      Or copy and paste this link into your browser:<br>
      <a href="$inviteLink" style="color: #2563eb; word-break: break-all;">$inviteLink</a>
    </p>
    <p style="font-size: 12px; color: #666;">
      If you didn't expect this invitation, you can safely ignore this email.
    </p>
  </div>
</body>
</html>
''',
      };

      final response = await http.post(
        Uri.parse(_brevoApiUrl),
        headers: {
          'accept': 'application/json',
          'api-key': _brevoApiKey,
          'content-type': 'application/json',
        },
        body: jsonEncode(emailBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout: Email sending took too long');
        },
      );

      debugPrint('Brevo API response status: ${response.statusCode}');
      debugPrint('Brevo API response body: ${response.body}');

      if (response.statusCode == 201) {
        debugPrint('Email sent successfully via Brevo');
        return true;
      } else {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage = errorBody?['message'] ?? 'Failed to send email';
        debugPrint('Brevo API error: $errorMessage');
        throw Exception('Failed to send email: $errorMessage');
      }
    } catch (e, stackTrace) {
      debugPrint('Error sending invite: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Verify invitation token
  Future<Map<String, dynamic>?> verifyInviteToken(String token) async {
    try {
      final inviteDoc = await _firestore
          .collection('invites')
          .where('token', isEqualTo: token)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (inviteDoc.docs.isEmpty) {
        return null;
      }

      final doc = inviteDoc.docs.first;
      final data = doc.data();
      return {
        'id': doc.id,
        'email': data['email'],
        'workspaceId': data['workspaceId'],
        'token': data['token'],
        'status': data['status'],
        'createdAt': data['createdAt'],
      };
    } catch (e) {
      debugPrint('Error verifying invite token: $e');
      return null;
    }
  }

  /// Accept invitation - add user to workspace
  Future<bool> acceptInvite(String inviteId, String userId) async {
    try {
      final batch = _firestore.batch();

      // Get invite document
      final inviteRef = _firestore.collection('invites').doc(inviteId);
      final inviteDoc = await inviteRef.get();

      if (!inviteDoc.exists) {
        return false;
      }

      final inviteData = inviteDoc.data()!;
      final workspaceId = inviteData['workspaceId'] as String;

      // Update invite status
      batch.update(inviteRef, {
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
        'acceptedBy': userId,
      });

      // Add user to workspace members
      final workspaceRef = _firestore.collection('workspaces').doc(workspaceId);
      batch.set(
        workspaceRef.collection('members').doc(userId),
        {
          'userId': userId,
          'joinedAt': FieldValue.serverTimestamp(),
          'role': 'member', // Default role
        },
        SetOptions(merge: true),
      );

      // Also update user document with workspace ID
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'workspaceId': workspaceId,
      });

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error accepting invite: $e');
      return false;
    }
  }
}

