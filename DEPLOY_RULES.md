# Deploy Firestore Security Rules

## Option 1: Using Firebase Console (Easiest)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **workforce-f9e89**
3. Click on **Firestore Database** in the left menu
4. Click on the **Rules** tab
5. Copy and paste the contents from `firestore.rules` file
6. Click **Publish**

## Option 2: Using Firebase CLI (Recommended for development)

### Prerequisites:
- Install Firebase CLI: `npm install -g firebase-tools`
- Login to Firebase: `firebase login`

### Deploy:
```bash
firebase deploy --only firestore:rules
```

---

**Important:** The current rules allow all reads and writes for development purposes. For production, you should implement proper authentication and security rules.

