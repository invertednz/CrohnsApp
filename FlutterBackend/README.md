# Flutter Modular Backend Architecture

A modular, customizable backend architecture for Flutter applications using Supabase. This architecture provides a set of reusable services that can be integrated into multiple Flutter apps with similar functionality but different UI implementations.

## Features

- **Authentication Service**: Sign up and sign in with email, Google, and Apple ID
- **User Settings Service**: Manage user preferences and onboarding data
- **Profile Service**: Handle user profile information
- **Tracking Service**: Track user activities and metrics
- **Insights Service**: Generate AI-powered insights based on user data
- **Chat Service**: AI chatbot that uses user history as context
- **Notification Service**: Send notifications for insights and tracking reminders
- **Storage Service**: Handle file uploads and downloads

## Architecture

The architecture follows a modular approach with the following components:

### Core

- **SupabaseClient**: A wrapper around the Supabase client to provide a consistent interface
- **BackendService**: A centralized service manager that provides access to all services

### Services

Each service is designed to handle a specific aspect of the application:

- **AuthService**: Handles user authentication and session management
- **UserSettingsService**: Manages user settings and onboarding data
- **ProfileService**: Manages user profile information
- **TrackingService**: Tracks user activities and metrics
- **InsightsService**: Generates and retrieves AI-powered insights
- **ChatService**: Provides AI chatbot functionality
- **NotificationService**: Manages user notifications
- **StorageService**: Handles file storage operations

### Models

- **UserModel**: Represents a user in the application

## Integration

To integrate this backend into a Flutter app:

1. Copy the `src` directory into your Flutter project
2. Initialize the backend service in your app's main.dart file:

```dart
final backendService = await BackendService.initialize(
  supabaseUrl: 'YOUR_SUPABASE_URL',
  supabaseKey: 'YOUR_SUPABASE_KEY',
);
```

3. Use the backend service to access the various services:

```dart
// Access the auth service
final authService = backendService.auth;

// Sign in with Google
final user = await authService.signInWithGoogle();

// Access the tracking service
final trackingService = backendService.tracking;

// Track an event
await trackingService.trackEvent(user.id, 'mood', {'value': 'happy'});
```

## Customization

Each service can be customized for specific app requirements by extending the base service classes or modifying the implementation. The modular design allows for easy replacement of specific services while maintaining the overall architecture.

## Supabase Setup

This backend requires the following tables in your Supabase database:

- `profiles`: User profile information
- `user_settings`: User settings and preferences
- `user_tracking`: User activity tracking data
- `user_insights`: AI-generated insights for users
- `notifications`: User notifications
- `chat_conversations`: Chat conversations
- `chat_messages`: Messages within chat conversations

You'll also need to set up the following Supabase Edge Functions:

- `generate_ai_response`: Generate AI responses for the chat service
- `generate_user_insights`: Generate insights based on user tracking data
- `schedule_weekly_insights`: Schedule weekly insight generation for all users

## License

MIT