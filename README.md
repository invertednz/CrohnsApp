# Crohn's Companion

A comprehensive health tracking application for individuals with Crohn's disease. This app enables users to track symptoms, diet, bowel movements, medications/supplements, and receive AI-powered insights to help manage their condition more effectively.

## Features

- **User Authentication**: Sign up and sign in with email, Google, or Apple ID
- **Daily Tracking**: Log daily symptoms, bowel movements, pain levels, and energy levels
- **Symptom Management**: Track and monitor Crohn's-specific symptoms over time
- **Diet Tracking**: Record meals and identify food triggers and safe foods
- **Supplement Tracking**: Manage supplement intake and schedules
- **Insights**: Receive AI-generated insights based on tracked data
- **Chat Assistant**: Interact with an AI assistant for personalized advice

## Technical Stack

- **Frontend**: Flutter for cross-platform (iOS and Android) compatibility
- **Backend**: Supabase for authentication, database, storage, and edge functions
- **State Management**: Provider pattern for app-wide state management

## Project Structure

```
lib/
  ├── core/            # Core functionality and services
  ├── models/          # Data models
  ├── screens/         # UI screens
  ├── widgets/         # Reusable UI components
  ├── services/        # Service classes for API communication
  └── main.dart        # Entry point of the application
```

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio or VS Code with Flutter plugins
- Supabase account and project

### Setup

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure your Supabase credentials in the app
4. Run the app using `flutter run`

## Backend Integration

This app uses a modular backend architecture located in the `FlutterBackend` directory. The backend provides services for authentication, user settings, profile management, tracking, insights, chat, notifications, and storage.

## License

This project is licensed under the MIT License - see the LICENSE file for details.