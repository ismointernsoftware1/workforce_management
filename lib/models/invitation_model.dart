import 'package:cloud_firestore/cloud_firestore.dart';

class Invitation {
  const Invitation({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    required this.invitedAt,
    this.invitedBy,
    this.inviterEmail,
    this.inviterName,
    this.emailSent,
    this.emailSentAt,
  });

  final String id;
  final String email;
  final String role;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime invitedAt;
  final String? invitedBy;
  final String? inviterEmail;
  final String? inviterName;
  final bool? emailSent;
  final DateTime? emailSentAt;

  factory Invitation.fromMap(Map<String, dynamic> data, {String? id}) {
    return Invitation(
      id: id ?? (data['id'] as String? ?? ''),
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'Member',
      status: data['status'] as String? ?? 'pending',
      invitedAt: (data['invitedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      invitedBy: data['invitedBy'] as String?,
      inviterEmail: data['inviterEmail'] as String?,
      inviterName: data['inviterName'] as String?,
      emailSent: data['emailSent'] as bool? ?? false,
      emailSentAt: (data['emailSentAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'role': role,
        'status': status,
        'invitedAt': Timestamp.fromDate(invitedAt),
        'invitedBy': invitedBy,
        'inviterEmail': inviterEmail,
        'inviterName': inviterName,
        'emailSent': emailSent ?? false,
        if (emailSentAt != null) 'emailSentAt': Timestamp.fromDate(emailSentAt!),
      };
}

