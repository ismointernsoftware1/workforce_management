import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../models/invite_model.dart';

/// InviteService - handles invitation operations with role assignment
class InviteService {
  InviteService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();
  static const String _collection = 'invites';

  /// Create an invitation with role assignment
  /// Email will be sent automatically via Cloud Function trigger
  Future<String> createInvite(String email, String roleId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Generate secure token
      final token = _uuid.v4();
      
      // Create invite document - Cloud Function will trigger and send email
      final inviteRef = _firestore.collection(_collection).doc();
      final invite = InviteModel(
        inviteId: inviteRef.id,
        email: email.toLowerCase().trim(),
        roleId: roleId,
        token: token,
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        used: false,
        createdAt: DateTime.now(),
        invitedBy: user.uid,
      );

      await inviteRef.set(invite.toMap());
      debugPrint('Invitation created: ${inviteRef.id} for email: $email with role: $roleId');
      
      return inviteRef.id;
    } catch (e, stackTrace) {
      debugPrint('Error creating invite: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Validate invite token - returns invite data if valid
  Future<InviteModel?> validateInviteToken(String token) async {
    try {
      final inviteDoc = await _firestore
          .collection(_collection)
          .where('token', isEqualTo: token)
          .limit(1)
          .get();

      if (inviteDoc.docs.isEmpty) {
        debugPrint('No invite found with token: $token');
        return null;
      }

      final doc = inviteDoc.docs.first;
      final invite = InviteModel.fromMap(doc.data(), id: doc.id);
      
      // Check if invite is valid (not used and not expired)
      if (!invite.isValid) {
        debugPrint('Invite is invalid: used=${invite.used}, expired=${invite.isExpired}');
        return null;
      }

      return invite;
    } catch (e) {
      debugPrint('Error validating invite token: $e');
      return null;
    }
  }

  /// Mark invite as used
  Future<bool> markInviteUsed(String inviteId, String userId) async {
    try {
      await _firestore.collection(_collection).doc(inviteId).update({
        'used': true,
        'usedAt': FieldValue.serverTimestamp(),
        'usedBy': userId,
      });
      debugPrint('Invite marked as used: $inviteId by user: $userId');
      return true;
    } catch (e) {
      debugPrint('Error marking invite as used: $e');
      return false;
    }
  }

  /// Get invite by ID
  Future<InviteModel?> getInviteById(String inviteId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(inviteId).get();
      if (!doc.exists) {
        return null;
      }
      return InviteModel.fromMap(doc.data()!, id: doc.id);
    } catch (e) {
      debugPrint('Error getting invite: $e');
      return null;
    }
  }

  /// Stream all invites (for admin view)
  Stream<List<InviteModel>> streamAllInvites() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => InviteModel.fromMap(doc.data(), id: doc.id))
          .toList();
    });
  }
}
