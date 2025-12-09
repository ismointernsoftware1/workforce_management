# RBAC + Invite System - Complete Implementation Guide

## ✅ Implementation Complete

This document describes the complete RBAC (Role-Based Access Control) and Invitation System implementation.

---

## 📁 Files Created/Modified

### Model Classes (`lib/models/`):

1. **`permission_set.dart`**
   - CRUD permissions (create, read, update, delete)
   - Helper methods: `hasAnyPermission()`, `hasAllPermissions()`

2. **`permissions_model.dart`**
   - Contains PermissionSet for: teamControl, chatControl, taskControl, expenseControl
   - Helper method: `hasAnyPermission()`

3. **`role_model.dart`**
   - roleId, roleName, permissions (PermissionsModel)
   - Full serialization support

4. **`app_user.dart`**
   - uid, email, roleId
   - Links Firebase Auth users to roles

5. **`invite_model.dart`**
   - inviteId, email, roleId, token, expiresAt, used
   - Helper methods: `isExpired`, `isValid`

### Services (`lib/services/`):

1. **`role_service.dart`**
   - `createRole()`, `updateRole()`, `deleteRole()`
   - `getRoleById()`, `getAllRoles()`, `streamAllRoles()`

2. **`user_service.dart`**
   - `createAppUser()`, `getUserByUid()`, `updateUserRole()`
   - `streamUserByUid()`, `getAllUsers()`

3. **`invite_service.dart`** (Updated)
   - `createInvite(email, roleId)` - Creates invite, Cloud Function sends email
   - `validateInviteToken(token)` - Returns InviteModel if valid
   - `markInviteUsed(inviteId, userId)` - Marks invite as used
   - `getInviteById()`, `streamAllInvites()`

### UI Screens (`lib/views/`):

1. **`roles/role_list_page.dart`**
   - Displays all roles from Firestore
   - Edit/Delete buttons for each role
   - FAB to create new role

2. **`roles/role_editor_page.dart`**
   - Form for roleName
   - Four CRUD permission toggles for each resource:
     - Team Control
     - Chat Control
     - Task Control
     - Expense Control
   - Save button stores/updates role

3. **`invitation/invite_accept_signup_page.dart`**
   - Reads token from URL: `?token=XYZ`
   - Validates token via Firestore
   - Shows signup form (name, password, confirm password)
   - After signup:
     - Creates FirebaseAuth user
     - Creates AppUser document with assigned roleId
     - Marks invite.used = true
     - Navigates to login

4. **`widgets/invite_user_dialog.dart`** (Updated)
   - Input: email
   - Dropdown: role (loaded from Firestore roles collection)
   - Action: Send Invite (calls `createInvite()`)

### Firebase Cloud Functions (`functions/`):

1. **`index.js`**
   - `onInviteCreate` - Triggered when invite document is created
     - Sends email via Firebase "Trigger Email" extension
     - Email contains invite link with token
   - `validateInvite` - Callable function to validate invite token
   - `markInviteUsed` - Callable function to mark invite as used

2. **`package.json`**
   - Dependencies: firebase-admin, firebase-functions

### Security Rules (`firestore.rules`):

- Only admins can create/update/delete roles
- Only admins can send invites
- Only Cloud Functions can mark invite as used
- Users can only read their own profile
- Admins have full access

### Routing (`lib/app.dart`):

- `/invite` route handles invite links
- Automatically routes to `InviteAcceptSignupPage` if user not logged in
- Routes to `AcceptInviteScreen` if user is logged in

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

### 3. Install Firebase "Trigger Email" Extension

**Important:** The Cloud Function uses the Firebase "Trigger Email" extension to send emails.

1. Go to Firebase Console > Extensions
2. Install "Trigger Email" extension
3. Configure it with your email service (Gmail SMTP, SendGrid, etc.)

### 4. Deploy Firebase Functions

```bash
cd functions
firebase deploy --only functions
```

### 5. Deploy Firestore Security Rules

```bash
firebase deploy --only firestore:rules
```

### 6. Update Invite Link URL

In `functions/index.js`, update the invite link:
```javascript
const inviteLink = `https://your-app.web.app/invite?token=${token}`;
```

---

## 📋 Firestore Structure

### Collection: `roles/{roleId}`

```javascript
{
  roleId: "role-id",
  roleName: "Admin",
  permissions: {
    teamControl: { create: true, read: true, update: true, delete: true },
    chatControl: { create: true, read: true, update: true, delete: true },
    taskControl: { create: true, read: true, update: true, delete: true },
    expenseControl: { create: true, read: true, update: true, delete: true }
  }
}
```

### Collection: `app_users/{userId}`

```javascript
{
  uid: "user-uid",
  email: "user@example.com",
  roleId: "role-id"
}
```

### Collection: `invites/{inviteId}`

```javascript
{
  inviteId: "invite-id",
  email: "user@example.com",
  roleId: "role-id",
  token: "uuid-token",
  expiresAt: Timestamp,
  used: false,
  createdAt: Timestamp,
  invitedBy: "user-uid",
  usedAt: Timestamp, // (optional, when used)
  usedBy: "user-uid" // (optional, when used)
}
```

### Collection: `mail/{mailId}` (Managed by Trigger Email Extension)

```javascript
{
  to: "user@example.com",
  message: {
    subject: "You're invited!",
    html: "<html>...</html>",
    text: "Plain text version"
  }
}
```

---

## 🎯 How It Works

### 1. Creating a Role

1. Navigate to Role Management page (add route in your app)
2. Click "Create Role" FAB
3. Enter role name
4. Toggle permissions for each resource (Team, Chat, Task, Expense)
5. Click "Create Role"
6. Role is saved to Firestore `roles` collection

### 2. Sending an Invitation

1. Click "Invite User" button
2. `InviteUserDialog` opens
3. Enter email address
4. Select role from dropdown
5. Click "Send Invite"
6. `InviteService.createInvite()` is called:
   - Generates UUID token
   - Creates invite document in Firestore
   - Cloud Function `onInviteCreate` triggers
   - Email is sent via Trigger Email extension
7. Success message shown

### 3. Accepting an Invitation

**If user is NOT logged in:**
1. User clicks invite link: `https://app.web.app/invite?token=XYZ`
2. App routes to `InviteAcceptSignupPage`
3. Page validates token
4. User fills signup form (name, password)
5. On submit:
   - Creates FirebaseAuth user
   - Creates AppUser document with roleId from invite
   - Marks invite as used
   - Navigates to login

**If user IS logged in:**
1. User clicks invite link
2. App routes to `AcceptInviteScreen`
3. User accepts invitation
4. Invite is marked as used
5. User is added to workspace (if applicable)

---

## 🔐 Security Rules Summary

- **Roles**: Read by all authenticated users, write by admins only
- **App Users**: Read own profile or admin, write by admin/Cloud Functions
- **Invites**: Read by admin, create by admin, update `used` field by Cloud Functions only
- **Mail**: Write by Cloud Functions only

---

## 🚀 Usage Examples

### Check User Permissions

```dart
final userService = UserService();
final appUser = await userService.getUserByUid(userId);
final roleService = RoleService();
final role = await roleService.getRoleById(appUser.roleId);

// Check if user can create tasks
if (role.permissions.taskControl.create) {
  // Allow task creation
}
```

### Create Default Roles

```dart
final roleService = RoleService();

// Create Admin role
await roleService.createRole(RoleModel(
  roleId: '',
  roleName: 'Admin',
  permissions: PermissionsModel(
    teamControl: PermissionSet(create: true, read: true, update: true, delete: true),
    chatControl: PermissionSet(create: true, read: true, update: true, delete: true),
    taskControl: PermissionSet(create: true, read: true, update: true, delete: true),
    expenseControl: PermissionSet(create: true, read: true, update: true, delete: true),
  ),
));
```

---

## 📝 Notes

1. **Firebase Trigger Email Extension**: This system requires the Firebase "Trigger Email" extension to be installed. It handles the actual email sending.

2. **Role Assignment**: When a user signs up via invite, their `roleId` is automatically assigned from the invite.

3. **Token Expiration**: Invites expire after 7 days (configurable in `invite_service.dart`).

4. **Admin Role**: The security rules check for `roleId == 'admin'`. Make sure to create an admin role with this exact ID or update the rules.

5. **Navigation**: Add navigation to `RoleListPage` in your app's navigation menu for admin users.

---

## 🔄 Migration from Old System

If you're migrating from the old invite system:

1. Old invites in `invites` collection will continue to work
2. Update existing users to have `app_users` documents
3. Create default roles in Firestore
4. Assign roles to existing users

---

## ✅ Testing Checklist

- [ ] Create a role via UI
- [ ] Edit a role via UI
- [ ] Delete a role via UI
- [ ] Send an invite with role selection
- [ ] Receive email with invite link
- [ ] Accept invite (not logged in) - signup flow
- [ ] Accept invite (logged in) - accept flow
- [ ] Verify role assignment after signup
- [ ] Test invite expiration
- [ ] Test security rules (admin vs non-admin)

---

## 🐛 Troubleshooting

**Email not sending:**
- Check if Trigger Email extension is installed
- Verify email service configuration in extension
- Check Cloud Function logs: `firebase functions:log`

**Invite validation fails:**
- Check if invite document exists in Firestore
- Verify token matches
- Check if invite is expired or already used

**Security rules blocking access:**
- Verify user has `app_users` document
- Check if `roleId` matches admin role ID in rules
- Review Firestore rules in Firebase Console

---

## 📚 Next Steps

1. Add role-based UI visibility (hide/show features based on permissions)
2. Implement permission checks in controllers/services
3. Add role management to admin dashboard
4. Create default roles on app initialization
5. Add role assignment UI for existing users

