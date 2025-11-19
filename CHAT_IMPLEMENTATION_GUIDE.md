# Real-Time Chat Implementation Guide

## 📋 Overview

This guide covers the complete implementation of a real-time chat system with Firebase Firestore, including FCM notifications when admin sends messages.

---

## 🏗️ Firestore Structure

### Collections & Documents

```
chat_rooms (collection)
├── {chatRoomId} (document)
│   ├── userId: string
│   ├── userName: string
│   ├── userEmail: string
│   ├── lastMessage: string
│   ├── lastMessageSenderId: string
│   ├── lastMessageSenderRole: string ('user' or 'admin')
│   ├── lastMessageTime: timestamp
│   ├── unreadCount: number
│   ├── createdAt: timestamp
│   │
│   └── messages (subcollection)
│       ├── {messageId} (document)
│       │   ├── chatRoomId: string
│       │   ├── senderId: string
│       │   ├── senderName: string
│       │   ├── senderRole: string ('user' or 'admin')
│       │   ├── text: string
│       │   ├── createdAt: timestamp
│       │   └── isRead: boolean
```

---

## 🔐 Firestore Security Rules

Add these rules to your Firebase Console → Firestore → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isSignedIn() {
      return request.auth != null;
    }
    
    // Helper function to check if user is admin
    function isAdmin() {
      return isSignedIn() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Chat rooms rules
    match /chat_rooms/{chatRoomId} {
      // Users can read their own chat rooms
      // Admins can read all chat rooms
      allow read: if isSignedIn() && 
                     (resource.data.userId == request.auth.uid || isAdmin());
      
      // Users can create their own chat rooms
      allow create: if isSignedIn() && 
                       request.resource.data.userId == request.auth.uid;
      
      // Users can update their own chat rooms
      // Admins can update any chat room
      allow update: if isSignedIn() && 
                       (resource.data.userId == request.auth.uid || isAdmin());
      
      // Messages subcollection
      match /messages/{messageId} {
        // Users can read messages in their chat rooms
        // Admins can read all messages
        allow read: if isSignedIn() && 
                       (get(/databases/$(database)/documents/chat_rooms/$(chatRoomId)).data.userId == request.auth.uid || 
                        isAdmin());
        
        // Users can create messages in their chat rooms
        // Admins can create messages in any chat room
        allow create: if isSignedIn() && 
                         (get(/databases/$(database)/documents/chat_rooms/$(chatRoomId)).data.userId == request.auth.uid || 
                          isAdmin());
        
        // Allow updating messages (for marking as read)
        allow update: if isSignedIn();
      }
    }
  }
}
```

---

## 📱 FCM Notifications Setup

### Cloud Function for Admin Message Notifications

Create a Firebase Cloud Function to send FCM notifications when an admin sends a message:

**Prerequisites:**
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login: `firebase login`
3. Initialize functions: `firebase init functions` (choose JavaScript or TypeScript)

**functions/index.js:**

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * Sends FCM notification when admin sends a message
 * Triggers on new message creation in any chat room
 */
exports.sendChatNotification = functions.firestore
  .document('chat_rooms/{chatRoomId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    try {
      const message = snap.data();
      const chatRoomId = context.params.chatRoomId;

      // Only send notification if message is from admin
      if (message.senderRole !== 'admin') {
        console.log('Message is from user, skipping notification');
        return null;
      }

      // Get chat room data to find the user
      const chatRoomDoc = await admin.firestore()
        .collection('chat_rooms')
        .doc(chatRoomId)
        .get();

      if (!chatRoomDoc.exists) {
        console.log('Chat room not found');
        return null;
      }

      const chatRoom = chatRoomDoc.data();
      const userId = chatRoom.userId;

      // Get user's FCM token
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(userId)
        .get();

      if (!userDoc.exists) {
        console.log('User not found');
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        console.log('User has no FCM token');
        return null;
      }

      // Increment unread count
      await admin.firestore()
        .collection('chat_rooms')
        .doc(chatRoomId)
        .update({
          unreadCount: admin.firestore.FieldValue.increment(1)
        });

      // Send FCM notification
      const payload = {
        notification: {
          title: message.senderName || 'Kingsley Carwash',
          body: message.text.length > 100 
            ? message.text.substring(0, 100) + '...' 
            : message.text,
          icon: 'notification_icon',
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
        data: {
          type: 'chat_message',
          chatRoomId: chatRoomId,
          messageId: snap.id,
          senderId: message.senderId,
          senderRole: message.senderRole,
        },
        token: fcmToken,
      };

      const response = await admin.messaging().send(payload);
      console.log('Notification sent successfully:', response);

      return response;
    } catch (error) {
      console.error('Error sending notification:', error);
      return null;
    }
  });

/**
 * Creates a welcome message when a new chat room is created
 */
exports.sendWelcomeMessage = functions.firestore
  .document('chat_rooms/{chatRoomId}')
  .onCreate(async (snap, context) => {
    try {
      const chatRoomId = context.params.chatRoomId;
      const chatRoom = snap.data();

      // Create welcome message from admin
      await admin.firestore()
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
          chatRoomId: chatRoomId,
          senderId: 'admin',
          senderName: 'Kingsley Carwash',
          senderRole: 'admin',
          text: `Hello ${chatRoom.userName}! 👋 Welcome to Kingsley Carwash support. How can we help you today?`,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          isRead: false,
        });

      console.log('Welcome message sent to chat room:', chatRoomId);
      return null;
    } catch (error) {
      console.error('Error sending welcome message:', error);
      return null;
    }
  });
```

**Deploy the function:**
```bash
firebase deploy --only functions
```

---

## 🔧 Firestore Indexes

Create these composite indexes in Firebase Console → Firestore → Indexes:

### Index 1: Chat Rooms by User
- Collection: `chat_rooms`
- Fields:
  - `userId` (Ascending)
  - `lastMessageTime` (Descending)

### Index 2: Messages by Chat Room
- Collection: `chat_rooms/{chatRoomId}/messages`
- Fields:
  - `createdAt` (Ascending)

### Index 3: Unread Messages
- Collection: `chat_rooms/{chatRoomId}/messages`
- Fields:
  - `isRead` (Ascending)
  - `senderRole` (Ascending)
  - `createdAt` (Ascending)

**Or use this command after running the app:**
When you get an index error in the console, Firebase will provide a link to auto-create the index. Click that link!

---

## 🔔 Handle Chat Notifications in Flutter

### Update FCM Service

Add chat notification handling to `lib/services/fcm-service.dart`:

```dart
// Inside initNotifications() method, in FirebaseMessaging.onMessage.listen
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print('Got a message whilst in the foreground!');
  
  // Check if it's a chat message
  if (message.data['type'] == 'chat_message') {
    // Show local notification
    showLocalNotification(message);
    
    // You can also update UI or show in-app banner
    // Get.snackbar(
    //   message.notification?.title ?? 'New Message',
    //   message.notification?.body ?? '',
    //   backgroundColor: Colors.blue,
    //   colorText: Colors.white,
    //   duration: Duration(seconds: 3),
    // );
  } else {
    // Handle other notification types
    showLocalNotification(message);
  }
});

// Handle notification tap when app is in background
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  print('A new onMessageOpenedApp event was published!');
  
  // Navigate to chat screen if it's a chat message
  if (message.data['type'] == 'chat_message') {
    final chatRoomId = message.data['chatRoomId'];
    if (chatRoomId != null) {
      Get.to(() => ChatDetailScreen(chatRoomId: chatRoomId));
    }
  }
});
```

---

## 🎯 Testing the Chat System

### Test as User:

1. **Sign up/Login** as a regular user
2. **Open Chat Screen** and tap "Start Chat" button
3. **Send a message** to admin
4. **Wait for admin response** (you'll need to test this in Firebase Console or build an admin panel)

### Test Admin Messages (Manual via Firebase Console):

1. Go to **Firebase Console → Firestore**
2. Find the `chat_rooms` collection
3. Select a chat room document
4. Go to `messages` subcollection
5. Click **"Add document"**
6. Add fields:
   ```
   chatRoomId: (same as parent doc ID)
   senderId: "admin"
   senderName: "Kingsley Carwash"
   senderRole: "admin"
   text: "Hello! How can I help you?"
   createdAt: (current timestamp)
   isRead: false
   ```
7. The user should receive an FCM notification!

---

## 🚀 Next Steps: Admin Panel

To complete the chat system, you'll need to build an admin web panel:

### Recommended Tech Stack:
- **React** or **Vue.js** for the frontend
- **Firebase Admin SDK** for backend operations
- **Firebase Hosting** for deployment

### Admin Panel Features:
1. **Dashboard** - View all chat rooms
2. **Chat List** - See all active conversations with unread indicators
3. **Chat Interface** - Real-time messaging with users
4. **User Info** - Display user details and booking history
5. **Quick Replies** - Pre-defined responses for common questions
6. **Search** - Find specific conversations
7. **Status Indicators** - Online/offline status for users

### Quick Admin Web Setup:

```bash
# Create React app
npx create-react-app kingsley-admin
cd kingsley-admin

# Install Firebase
npm install firebase

# Initialize Firebase in your app
# Use the same Firebase project
```

---

## 📊 Monitoring & Analytics

### Firebase Console Monitoring:
1. **Firestore Usage** → Check read/write operations
2. **Functions Logs** → Monitor Cloud Function execution
3. **Cloud Messaging** → Track notification delivery
4. **Performance** → Monitor app performance

### Add Analytics Events:

```dart
// In ChatController
await FirebaseAnalytics.instance.logEvent(
  name: 'chat_message_sent',
  parameters: {
    'user_id': user.uid,
    'chat_room_id': chatRoomId,
  },
);
```

---

## 🐛 Troubleshooting

### Messages not appearing?
- Check Firestore security rules
- Verify indexes are created
- Check for errors in debug console

### Notifications not working?
- Verify FCM token is saved in user document
- Check Cloud Function logs in Firebase Console
- Ensure FCM service is properly initialized
- Test with Firebase Console → Cloud Messaging → Send test message

### Unread count not updating?
- Ensure `markMessagesAsRead()` is called when opening chat
- Check Cloud Function is incrementing unread count
- Verify Firestore rules allow updates

---

## 📝 Summary

You now have:
- ✅ Real-time chat with Firestore
- ✅ Message sending and receiving
- ✅ Unread message indicators
- ✅ FCM notifications for admin messages
- ✅ Proper security rules
- ✅ Scalable architecture

**What's implemented:**
- User can start conversations
- Real-time message sync
- Message history
- Read receipts
- Notification system

**What you need to build:**
- Admin web panel for staff to respond
- (Optional) Image/file sharing in chat
- (Optional) Chat archiving
- (Optional) Typing indicators

---

## 🔗 Useful Links

- [Firebase Cloud Functions Docs](https://firebase.google.com/docs/functions)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [FCM for Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/client)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)

---

**Need help? Check the Firebase Console logs and Flutter debug console for detailed error messages!**
