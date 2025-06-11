# Global Chat Feature Documentation

## Overview
The Global Chat feature allows users of the BCA Library app to communicate with each other in real-time. It's a shared space where users can send messages that will be visible to all other users who have logged in to the app.

## Features
- Real-time messaging
- User authentication required
- Messages include user names and timestamps
- Professionally designed UI that matches the app's theme
- Dark mode support

## Firebase Setup Requirements

To make the Global Chat feature work, you need to configure Firebase Realtime Database rules:

1. Log in to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to "Realtime Database" in the left menu
4. Click on the "Rules" tab
5. Replace the existing rules with the following:

```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null",
    "global_chat": {
      ".read": "auth != null",
      ".write": "auth != null",
      "$message_id": {
        ".validate": "newData.hasChildren(['userId', 'userName', 'text', 'timestamp'])",
        "userId": {
          ".validate": "newData.isString() && newData.val() === auth.uid"
        },
        "userName": {
          ".validate": "newData.isString()"
        },
        "text": {
          ".validate": "newData.isString() && newData.val().length <= 500"
        },
        "timestamp": {
          ".validate": "newData.isNumber() && newData.val() <= now"
        },
        "userPhotoUrl": {
          ".validate": "newData.isString() || newData.val() == null"
        },
        "$other": {
          ".validate": false
        }
      }
    }
  }
}
```

6. Click "Publish" to save the rules

## How It Works

### Technical Implementation
- The Global Chat uses Firebase Realtime Database to store and retrieve messages
- Messages are stored in the `global_chat` node in the database
- Each message contains:
  - userId: The Firebase Auth UID of the user who sent the message
  - userName: The display name of the user
  - text: The content of the message
  - timestamp: The time when the message was sent
  - userPhotoUrl (optional): The URL to the user's profile photo

### User Flow
1. User navigates to the Global Chat from the app's drawer menu
2. If not logged in, they see a login required screen
3. Once logged in, they can see messages from other users
4. They can type and send their own messages
5. New messages appear in real-time for all users

## Security
- Only authenticated users can read and write messages
- Users can only send messages with their own userId
- Messages are validated to ensure they contain all required fields
- Message text is limited to 500 characters
- Timestamps are validated to prevent future-dated messages

## Limitations
- Currently, there's no ability to delete messages
- No support for message editing
- No support for multimedia messages (images, videos, etc.)
- No user blocking functionality

## Future Improvements
- Add message deletion for user's own messages
- Add support for image sharing
- Add message reactions
- Add user profile view on tap of username
- Add message search functionality 