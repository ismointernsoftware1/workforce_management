# SendGrid Setup Guide

This guide will help you set up SendGrid to send invitation emails.

## Step 1: Create a SendGrid Account

1. Go to [https://sendgrid.com](https://sendgrid.com)
2. Sign up for a free account (allows 100 emails/day)

## Step 2: Get Your API Key

1. Log in to your SendGrid dashboard
2. Navigate to **Settings** → **API Keys**
3. Click **Create API Key**
4. Give it a name (e.g., "Workforce Management App")
5. Select **Full Access** or **Restricted Access** with Mail Send permissions
6. Click **Create & View**
7. **Copy the API key immediately** (you won't be able to see it again)

## Step 3: Verify Your Sender Email

1. Go to **Settings** → **Sender Authentication**
2. Click **Verify a Single Sender**
3. Fill in your details and verify your email
4. This email will be used as the "from" address in invitation emails

## Step 4: Configure the API Key in Your App

You have several options:

### Option A: Environment Variable (Recommended for Development)

1. Create a `.env` file in your project root (add it to `.gitignore`)
2. Add: `SENDGRID_API_KEY=your_api_key_here`
3. Update `lib/services/sendgrid_service.dart` to read from environment:

```dart
static String? _getApiKeyFromEnv() {
  // Use flutter_dotenv package or similar
  // return dotenv.env['SENDGRID_API_KEY'];
  return null;
}
```

### Option B: Firebase Remote Config (Recommended for Production)

1. Store the API key in Firebase Remote Config
2. Fetch it when the app initializes
3. Pass it to `SendGridService` constructor

### Option C: Secure Storage (For Mobile Apps)

1. Use `flutter_secure_storage` package
2. Store the API key securely on the device
3. Retrieve it when needed

### Option D: Direct Configuration (For Testing Only)

⚠️ **Never commit API keys to version control!**

For quick testing, you can temporarily hardcode it in `sendgrid_service.dart`:

```dart
static String? _getApiKeyFromEnv() {
  return 'your_api_key_here'; // REMOVE BEFORE COMMITTING!
}
```

## Step 5: Update Email Settings

In `lib/services/sendgrid_service.dart`, update:

1. **Sender Email**: Replace `'noreply@yourapp.com'` with your verified sender email
2. **App URL**: Replace `'https://yourapp.com'` with your actual app URL for invitation links

```dart
'from': {
  'email': 'your-verified-email@yourdomain.com', // Your verified sender
  'name': 'Workforce Management'
},
```

And update the invitation link:

```dart
final invitationLink = 'https://yourdomain.com/invite/accept?token=$invitationId';
// Or for mobile apps: 'yourapp://invite/accept?token=$invitationId'
```

## Step 6: Test the Integration

1. Run your app
2. Navigate to Team → All People
3. Click "Invite"
4. Enter a test email address
5. Click "Send invite"
6. Check the recipient's inbox for the invitation email

## Troubleshooting

### Error: "SendGrid API key not configured"
- Make sure you've set the API key using one of the methods above
- Check that the API key is correct and has Mail Send permissions

### Error: "403 Forbidden"
- Verify your API key has the correct permissions
- Check that your SendGrid account is active

### Error: "401 Unauthorized"
- Your API key is invalid or expired
- Generate a new API key and update your configuration

### Emails not being received
- Check your SendGrid Activity Feed to see if emails were sent
- Verify the recipient email address is correct
- Check spam/junk folders
- Ensure your sender email is verified

## Production Considerations

1. **Rate Limits**: SendGrid free tier allows 100 emails/day
2. **Email Templates**: Consider using SendGrid's Dynamic Templates for better email design
3. **Webhooks**: Set up webhooks to track email delivery status
4. **Domain Authentication**: For production, authenticate your domain instead of single sender
5. **Error Handling**: Implement retry logic for failed email sends
6. **Monitoring**: Monitor your SendGrid usage and set up alerts

## Security Best Practices

1. ✅ Never commit API keys to version control
2. ✅ Use environment variables or secure storage
3. ✅ Rotate API keys regularly
4. ✅ Use restricted API keys with minimal permissions
5. ✅ Monitor API key usage in SendGrid dashboard

