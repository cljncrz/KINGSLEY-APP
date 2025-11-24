# SMS OTP Verification Implementation Guide

## Overview
This implementation uses Firebase Phone Authentication to send SMS OTP codes to users during signup. The phone number collected from the signup form is used to verify the user's identity.

## Implementation Details

### 1. **Signup Screen Changes** (`signup_screen.dart`)

#### New State Variables
```dart
String? _verificationId;        // Stores Firebase verification ID
int? _resendToken;              // Used for resending OTP
```

#### New Methods

**`_sendOTP()`**
- Validates the signup form and user agreement
- Formats the phone number with country code (+1 for US)
- Sends OTP via Firebase Phone Authentication
- Handles three scenarios:
  - **verificationCompleted**: Auto-verification (iOS)
  - **codeSent**: Navigates to OTP verification screen
  - **verificationFailed**: Shows error message

**`_signUpWithCredential(credential)`**
- Receives phone authentication credential
- Signs in user with Firebase
- Calls `_completeSignUp()` to save user data

**`_completeSignUp(userId)`**
- Saves user profile to Firestore with fields:
  - `fullName`, `email`, `phoneNumber`
  - `phoneVerified: true` (flag for verified phone)
  - `fcmToken` (for push notifications)
  - `createdAt`, `role`
- Creates a welcome notification

#### Button Change
- "Create Account" button now calls `_sendOTP()` instead of direct signup

### 2. **OTP Verification Screen Changes** (`otp_verification_screen.dart`)

#### Updated Constructor Parameters
```dart
const OtpVerificationScreen({
  required this.phoneNumber,
  required this.verificationId,      // Firebase verification ID
  this.resendToken,                  // For resending OTP
  required this.userName,             // User's full name
  required this.userEmail,            // User's email
});
```

#### New Methods

**`_verifyOTP()`**
- Gets all 6 OTP digits from input fields
- Creates `PhoneAuthCredential` using verification ID and SMS code
- Signs in user with Firebase
- Saves user data to Firestore
- Navigates to success screen
- Handles errors and shows appropriate messages

**`_completeSignUp(userId)`**
- Saves complete user profile to Firestore
- Gets FCM token for push notifications
- Creates welcome notification

**`_resendOTP()`**
- Resends OTP to the same phone number
- Uses the `forceResendingToken` to force a new code
- Resets the resend timer
- Shows success message when OTP is resent

#### Timer Logic
- Timer starts automatically on screen load
- Countdown from 30 seconds before "Resend" is enabled
- Updates every second

### 3. **Flow Diagram**

```
User enters signup details
        ↓
Clicks "Create Account"
        ↓
_sendOTP() validates form & terms
        ↓
Firebase sends SMS with 6-digit code
        ↓
User navigates to OTP screen
        ↓
User enters 6-digit OTP
        ↓
_verifyOTP() validates with Firebase
        ↓
User profile saved to Firestore
        ↓
Navigate to Success screen
```

## Firebase Configuration

### Required Firebase Settings

1. **Enable Phone Authentication**
   - Go to Firebase Console → Authentication → Sign-in method
   - Enable "Phone" as a sign-in provider
   - Add SHA-1 fingerprint for Android
   - Configure reCAPTCHA token

2. **Android Configuration** (`android/app/build.gradle.kts`)
```kotlin
android {
    compileSdk 34
    defaultConfig {
        targetSdk 34
    }
}
```

3. **Android Manifest** (`android/app/src/AndroidManifest.xml`)
```xml
<!-- Phone authentication permission -->
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### Test Phone Numbers (Optional)
- Configure test phone numbers in Firebase Console
- They receive fixed OTP codes for testing
- Remove before production deployment

## Important Notes

### Phone Number Formatting
- Phone numbers are automatically formatted with `+1` prefix (US)
- Adjust the prefix for other countries:
  - Canada: `+1`
  - UK: `+44`
  - India: `+91`

Example for multi-country support:
```dart
String formatPhoneNumber(String phone, String countryCode) {
  if (!phone.startsWith('+')) {
    return '+$countryCode$phone';
  }
  return phone;
}
```

### Error Handling
The implementation handles these common errors:
- **invalid-phone-number**: Format issue with phone number
- **too-many-requests**: User requested too many OTP codes (rate limited)
- **invalid-verification-code**: Wrong OTP code entered
- **session-expired**: Verification session timed out (>10 minutes)

### Security Considerations
1. OTP codes expire after 1 hour
2. Maximum 5 attempts to enter correct OTP
3. Automatic resend token limits repeated requests
4. Phone verification flag prevents re-verification attacks
5. User data encrypted in Firestore

## User Experience Flow

1. **Signup Page**
   - User fills: Name, Email, Phone, Password
   - Accepts terms & conditions
   - Clicks "Create Account"
   - Loading indicator shows

2. **OTP Delivery**
   - SMS sent to phone with 6-digit code
   - User receives code within 5-30 seconds
   - If no SMS: User can click "Resend" after 30 seconds

3. **OTP Entry Page**
   - 6 input fields for individual digits
   - Auto-focuses next field as user types
   - Auto-verifies when all 6 digits entered
   - Manual "Verify" button available
   - "Resend" button with countdown timer

4. **Success**
   - Account created and verified
   - User automatically logged in
   - Redirected to home screen
   - Welcome notification created

## Testing

### Test Scenarios

1. **Valid Phone & Correct OTP**
   - Expected: Account created, logged in
   - Check: User data in Firestore, phoneVerified = true

2. **Resend OTP**
   - Click resend after 30 seconds
   - Enter new code
   - Expected: Account still creates

3. **Wrong OTP**
   - Enter incorrect 6-digit code
   - Expected: Error message, retry prompt

4. **Session Expiry**
   - Wait >10 minutes, then verify
   - Expected: Session expired error, need to restart

5. **Rate Limiting**
   - Request OTP multiple times quickly
   - Expected: Rate limit error after threshold

## Troubleshooting

### OTP Not Received
1. Check phone number format (+1-234-567-8900 or similar)
2. Verify SMS permissions enabled on device
3. Check Firebase console for errors
4. Try resending after 30 seconds

### Verification Fails
1. Ensure 6-digit code is correct
2. Code hasn't expired (1 hour limit)
3. No network connection issues
4. Firebase rules allow write to users collection

### User Data Not Saving
1. Check Firestore write permissions
2. Verify Firebase rules for 'users' collection
3. Check user authentication state
4. Review browser/device console for errors

## Future Enhancements

1. **Multi-language support** for OTP messages
2. **Biometric verification** after phone verification
3. **SMS provider integration** (Twilio, AWS SNS)
4. **Custom OTP timeout** configurations
5. **Phone number validation** before sending OTP
6. **Backup verification** methods (email)

## Dependencies Used

```yaml
firebase_auth: ^6.1.1      # Phone authentication
cloud_firestore: ^6.0.3    # Store user data
firebase_messaging: ^16.0.3 # Push notifications
get: ^4.6.6                # Navigation & state management
```

## References

- [Firebase Phone Authentication Docs](https://firebase.google.com/docs/auth/flutter/phone-auth)
- [Flutter Firebase Auth](https://pub.dev/packages/firebase_auth)
- [Firestore Best Practices](https://firebase.google.com/docs/firestore)
