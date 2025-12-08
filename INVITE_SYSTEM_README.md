# Invite User System - Implementation Guide

## ✅ Implementation Complete

This document describes the complete "Invite User" system that replaces the "Add User" button with a ClickUp-style invitation system using Brevo (SendinBlue) email service.

---

## 📁 Files Created/Modified

### Flutter Files:

1. **`lib/services/invite_service.dart`**
   - Service for handling invitation operations
   - Methods: `sendInvite()`, `verifyInviteToken()`, `acceptInvite()`

2. **`lib/views/widgets/invite_user_dialog.dart`**
   - Dialog widget for inviting users
   - Email validation and error handling

3. **`lib/views/auth/accept_invite_screen.dart`**
   - Screen for accepting invitations
   - Handles token verification and workspace joining

4. **`lib/utils/deep_link_handler.dart`**
   - Utility for handling invite links from URLs
   - Extracts token from `?token=XYZ` query parameter

5. **`lib/views/team/team_view.dart`** (Modified)
   - Replaced "Add User" button with "Invite User" button
   - Added `_showInviteUserDialog()` method

6. **`lib/app.dart`** (Modified)
   - Added route for `/invite`
   - Added deep link handling for invite tokens

7. **`pubspec.yaml`** (Modified)
   - Added `cloud_functions: ^5.6.2` dependency

### Firebase Functions Files:

1. **`functions/index.js`**
   - Cloud Function: `sendBrevoInvite`
   - Handles invitation creation and email sending

2. **`functions/package.json`**
   - Dependencies for Firebase Functions
   - Includes `@getbrevo/brevo` and `uuid`

---

## 🔧 Setup Instructions

### 1. Install Flutter Dependencies

```bash
flutter pub get
```

### 2. Setup Firebase Functions

```bash
cd functions
npm install
```

### 3. Configure Brevo API Key

The Brevo API key is already configured in `functions/index.js`:
```javascript
'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'
```

**⚠️ Important:** Update the sender email in `functions/index.js`:
```javascript
sendSmtpEmail.sender = { name: "Workforce Management", email: "noreply@yourapp.com" };
```
Replace `"noreply@yourapp.com"` with your verified Brevo sender email.

### 4. Update Invite Link URL

In `functions/index.js`, update the invite link:
```javascript
const inviteLink = `https://yourapp.com/invite?token=${token}`;
```
Replace `https://yourapp.com` with your actual app URL.

### 5. Deploy Firebase Functions

```bash
cd functions
firebase deploy --only functions:sendBrevoInvite
```

---

## 📋 Firestore Structure

### Collection: `invites/{tokenId}`

```javascript
{
  email: "user@example.com",
  workspaceId: "workspace-id",
  token: "uuid-token",
  status: "pending", // or "accepted"
  createdAt: Timestamp,
  invitedBy: "user-uid",
  acceptedAt: Timestamp, // (optional, when accepted)
  acceptedBy: "user-uid" // (optional, when accepted)
}
```

### Collection: `workspaces/{workspaceId}/members/{userId}`

```javascript
{
  userId: "user-uid",
  joinedAt: Timestamp,
  role: "member"
}
```

---

## 🎯 How It Works

### 1. Sending Invitation

1. User clicks "Invite User" button (black button with send icon)
2. `InviteUserDialog` opens
3. User enters email address
4. Dialog calls `InviteService.sendInvite(email)`
5. Service calls Firebase Cloud Function `sendBrevoInvite`
6. Cloud Function:
   - Generates secure UUID token
   - Saves invitation to Firestore
   - Sends email via Brevo with invite link
7. Success message shown: "Invitation Sent!"

### 2. Accepting Invitation

1. User clicks invite link: `https://yourapp.com/invite?token=XYZ`
2. App detects token in URL via `DeepLinkHandler`
3. Navigates to `AcceptInviteScreen`
4. Screen verifies token exists and is pending
5. If user not logged in → redirects to login
6. After login → user accepts invitation
7. `InviteService.acceptInvite()`:
   - Updates invite status to "accepted"
   - Adds user to workspace members
   - Updates user document with workspaceId
8. User redirected to dashboard

---

## 🎨 UI Changes

### Before:
- "Add User" button (primary blue)
- Opens `AddUserDialog` for direct user creation

### After:
- "Invite User" button (black background, white text, send icon)
- Border radius: 10px
- Opens `InviteUserDialog` for email invitation

**Note:** The "Add User" functionality is still available for editing existing users (when user parameter is passed).

---

## 🔒 Security Features

1. **Token Generation:** Uses UUID v4 for secure, unique tokens
2. **Authentication:** Cloud Function requires authenticated user
3. **Validation:** Email format validation on both client and server
4. **Status Check:** Only "pending" invitations can be accepted
5. **Workspace Verification:** Invite token is tied to specific workspace

---

## 🐛 Troubleshooting

### Email Not Sending
- Verify Brevo API key is correct
- Check sender email is verified in Brevo
- Check Firebase Functions logs: `firebase functions:log`

### Invite Link Not Working
- Verify deep link handler is working (check browser console)
- Ensure URL format: `?token=XYZ`
- Check Firestore for invite document

### Token Invalid/Expired
- Check if invite status is "pending"
- Verify token exists in Firestore
- Check if token was already accepted

---

## 📝 Next Steps (Optional Enhancements)

1. **Add Expiration:** Set expiration date for invitations
2. **Resend Invitation:** Allow resending expired invitations
3. **Invitation List:** Show pending invitations in admin panel
4. **Role Selection:** Allow selecting user role during invitation
5. **Mobile Deep Links:** Implement Firebase Dynamic Links for mobile apps

---

## ✅ Testing Checklist

- [ ] Invite button appears in People Directory
- [ ] Dialog opens with email input
- [ ] Email validation works
- [ ] Cloud Function deploys successfully
- [ ] Email is sent via Brevo
- [ ] Invite document created in Firestore
- [ ] Invite link works in browser
- [ ] Accept invite screen shows correctly
- [ ] User can accept invitation after login
- [ ] User added to workspace members
- [ ] User redirected to dashboard after acceptance

---

## 📞 Support

If you encounter any issues:
1. Check Firebase Functions logs
2. Check Firestore for invite documents
3. Verify Brevo API key and sender email
4. Check browser console for errors

---

**Implementation Date:** 2025-01-11
**Brevo API Key:** Configured in `functions/index.js`
**Status:** ✅ Complete and Ready for Deployment

