# BCA Scholar Hub App

A Flutter mobile application providing access to BCA (Bachelor of Computer Applications) study materials, courses, and a global chat feature for student communication.

&nbsp;

![a1](https://github.com/user-attachments/assets/161a9c5d-a486-43d1-83c5-13050764efc9) &nbsp;

<<<<<<< HEAD
![ad](https://github.com/user-attachments/assets/79ac64e8-e7c5-424b-9f1e-f8ad4b945165)

=======

![ad](https://github.com/user-attachments/assets/79ac64e8-e7c5-424b-9f1e-f8ad4b945165)

>>>>>>> origin/main
![ad2](https://github.com/user-attachments/assets/acd46319-4ea8-49f3-b9a3-0e8f72baef74)

![a4](https://github.com/user-attachments/assets/a3ec6790-1a35-4f28-814e-715b31e516e2) &nbsp;

![a5](https://github.com/user-attachments/assets/de5eb860-e62b-4507-b84b-43d07495b9a7) &nbsp;

![a6](https://github.com/user-attachments/assets/d7ba9046-2ea9-46e4-b3b9-b549909e944a) &nbsp;

## Features

- **Course Materials**: Access to BCA semester-wise study materials and resources
- **Extra Courses**: Additional learning resources beyond the standard curriculum
- **Favorites**: Save your favorite materials for quick access
- **Search**: Easily find specific content
- **User Authentication**: Create an account to save preferences and access personalized features
- **Global Chat**: Communicate with other students in real-time (NEW!)
- **Dark Mode**: Toggle between light and dark themes for comfortable reading
- **Multi-language Support**: Access content in different languages

## Global Chat Feature

The newest addition to the app is the Global Chat, which allows students to communicate with each other in real-time. This feature:

- Enables real-time messaging between users
- Shows user names and message timestamps
- Requires user authentication for security
- Supports both light and dark mode
- Provides a professional and intuitive UI

For more information on setting up and using the Global Chat feature, see the [Global Chat Documentation](GLOBAL_CHAT_DOCUMENTATION.md).

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Firebase account (for authentication and database)
- Android Studio or VS Code with Flutter plugins

### Installation

1. Clone this repository
2. Run `flutter pub get` to install dependencies
3. Configure Firebase using the provided `google-services.json` file
4. Run `flutter run` to launch the application

## Firebase Configuration

This application uses Firebase for:

- User Authentication
- Realtime Database (for Global Chat)
- Storage (for course materials)

Make sure to set up Firebase rules correctly for secure operation. See the [Global Chat Documentation](GLOBAL_CHAT_DOCUMENTATION.md) for specific rules for the chat feature.

## Technologies Used

- Flutter
- Firebase Authentication
- Firebase Realtime Database
- Firebase Storage
- Provider State Management
- Shared Preferences
