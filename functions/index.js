const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Cloud Function triggered when a new invite is created in Firestore
 * Sends invitation email using Firebase Extensions "Trigger Email"
 * 
 * Note: This requires the "Trigger Email" extension to be installed
 * Install it from Firebase Console > Extensions > Trigger Email
 */
exports.onInviteCreate = functions.firestore
  .document('invites/{inviteId}')
  .onCreate(async (snap, context) => {
    const inviteData = snap.data();
    const inviteId = context.params.inviteId;

    // Only send email if invite is not already used
    if (inviteData.used === true) {
      console.log(`Invite ${inviteId} is already used, skipping email`);
      return null;
    }

    const email = inviteData.email;
    const token = inviteData.token;
    const roleId = inviteData.roleId;

    // Get role name for email
    let roleName = 'Member';
    try {
      const roleDoc = await admin.firestore().collection('roles').doc(roleId).get();
      if (roleDoc.exists) {
        roleName = roleDoc.data().roleName || roleName;
      }
    } catch (error) {
      console.error('Error fetching role:', error);
    }

    // Construct invite link
    const inviteLink = `https://workforce-f9e89.web.app/invite?token=${token}`;

    // Email content
    const emailData = {
      to: email,
      message: {
        subject: "You're invited to join the Workspace!",
        html: `
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
    <p>You have been invited to join a workspace with the role: <strong>${roleName}</strong>.</p>
    <p>Click the button below to accept your invitation:</p>
    <div style="text-align: center; margin: 30px 0;">
      <a href="${inviteLink}" 
         style="display: inline-block; background-color: #2563eb; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: bold;">
        Accept Invitation
      </a>
    </div>
    <p style="font-size: 12px; color: #666; margin-top: 30px;">
      Or copy and paste this link into your browser:<br>
      <a href="${inviteLink}" style="color: #2563eb; word-break: break-all;">${inviteLink}</a>
    </p>
    <p style="font-size: 12px; color: #666;">
      This invitation will expire in 7 days.
    </p>
    <p style="font-size: 12px; color: #666;">
      If you didn't expect this invitation, you can safely ignore this email.
    </p>
  </div>
</body>
</html>
        `,
        text: `
You're Invited!

You have been invited to join a workspace with the role: ${roleName}.

Click the link below to accept your invitation:
${inviteLink}

This invitation will expire in 7 days.

If you didn't expect this invitation, you can safely ignore this email.
        `,
      },
    };

    // Send email using Trigger Email extension
    // The extension listens to the 'mail' collection
    try {
      await admin.firestore().collection('mail').add(emailData);
      console.log(`Email queued for ${email} with invite ${inviteId}`);
      return null;
    } catch (error) {
      console.error('Error sending email:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to send invitation email',
        error.message
      );
    }
  });

/**
 * Callable function to validate an invite token
 */
exports.validateInvite = functions.https.onCall(async (data, context) => {
  const { token } = data;

  if (!token || typeof token !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Token is required'
    );
  }

  try {
    const inviteQuery = await admin.firestore()
      .collection('invites')
      .where('token', '==', token)
      .limit(1)
      .get();

    if (inviteQuery.empty) {
      return { valid: false, message: 'Invalid token' };
    }

    const inviteDoc = inviteQuery.docs[0];
    const inviteData = inviteDoc.data();

    // Check if invite is used
    if (inviteData.used === true) {
      return { valid: false, message: 'Invitation has already been used' };
    }

    // Check if invite is expired
    const expiresAt = inviteData.expiresAt?.toDate();
    if (expiresAt && expiresAt < new Date()) {
      return { valid: false, message: 'Invitation has expired' };
    }

    return {
      valid: true,
      inviteId: inviteDoc.id,
      email: inviteData.email,
      roleId: inviteData.roleId,
    };
  } catch (error) {
    console.error('Error validating invite:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to validate invite',
      error.message
    );
  }
});

/**
 * Callable function to mark an invite as used
 * Only callable by authenticated users
 */
exports.markInviteUsed = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { inviteId } = data;

  if (!inviteId || typeof inviteId !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Invite ID is required'
    );
  }

  try {
    const inviteRef = admin.firestore().collection('invites').doc(inviteId);
    const inviteDoc = await inviteRef.get();

    if (!inviteDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Invite not found'
      );
    }

    await inviteRef.update({
      used: true,
      usedAt: admin.firestore.FieldValue.serverTimestamp(),
      usedBy: context.auth.uid,
    });

    return { success: true };
  } catch (error) {
    console.error('Error marking invite as used:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to mark invite as used',
      error.message
    );
  }
});

