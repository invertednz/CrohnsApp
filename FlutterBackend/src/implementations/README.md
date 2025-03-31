# App-Specific Implementations

This directory contains app-specific implementations of the backend services. Each app has its own subdirectory with custom service factories, models, and other app-specific code.

## Structure

Each app implementation should follow this structure:

```
app_name/
  ├── factory/
  │   └── app_service_factory.dart  # App-specific service factory
  ├── models/                       # App-specific model extensions
  ├── services/                     # App-specific service implementations
  └── README.md                     # Documentation for the app implementation
```

## Creating a New App Implementation

1. Create a new directory for your app
2. Create a service factory that implements the `ServiceFactory` interface
3. Create any app-specific service implementations by extending the base services
4. Create any app-specific models
5. Initialize the backend with your custom service factory:

```dart
final appServiceFactory = MyAppServiceFactory();
final backendService = await BackendService.initialize(
  supabaseUrl: 'YOUR_SUPABASE_URL',
  supabaseKey: 'YOUR_SUPABASE_KEY',
  serviceFactory: appServiceFactory,
);
```