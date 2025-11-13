# Firebase Integration Setup Guide

This guide walks through setting up Firebase for the Crohn's Companion app, including how to switch between mock data and live Firebase data.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Firebase Project Setup](#firebase-project-setup)
- [Flutter Configuration](#flutter-configuration)
- [Environment Configuration](#environment-configuration)
- [Running with Mock Data vs Firebase](#running-with-mock-data-vs-firebase)
- [Firestore Data Structure](#firestore-data-structure)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)

---

## Overview

The app supports two data modes:
- **Mock Data Mode**: Uses in-memory mock data for development and testing (no Firebase required)
- **Firebase Mode**: Connects to live Firebase services for production use

The mode is controlled via environment variables in `.env` files.

---

## Prerequisites

Before starting, ensure you have:
- Flutter SDK installed (2.19.0 or higher)
- A Google account for Firebase Console access
- Node.js and npm installed (for Firebase CLI)
- Firebase CLI installed: `npm install -g firebase-tools`

---

## Firebase Project Setup

### 1. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Add Project**
3. Enter project name: `crohns-companion` (or your preferred name)
4. Enable/disable Google Analytics as desired
5. Click **Create Project**

### 2. Enable Firebase Services

#### Enable Authentication
1. In Firebase Console, navigate to **Build** → **Authentication**
2. Click **Get Started**
3. Enable **Email/Password** sign-in method
4. (Optional) Enable other providers: Google, Apple, etc.

#### Enable Firestore Database
1. Navigate to **Build** → **Firestore Database**
2. Click **Create Database**
3. Choose **Start in test mode** (for development)
   - **Important**: Update security rules before production deployment
4. Select your preferred location (e.g., `us-central1`)
5. Click **Enable**

#### Enable Storage (Optional)
1. Navigate to **Build** → **Storage**
2. Click **Get Started**
3. Start in **test mode** for development
4. Click **Done**

#### Enable Analytics (Optional)
1. Navigate to **Build** → **Analytics**
2. Follow setup wizard if not already configured

### 3. Register Your Flutter App

#### For Android:
1. In Firebase Console, click the Android icon to add an Android app
2. Enter your package name: `com.yourcompany.crohns_companion`
   - Find this in `android/app/build.gradle` under `applicationId`
3. Download `google-services.json`
4. Place it in `android/app/` directory
5. Follow the Firebase setup instructions for gradle configuration

#### For iOS:
1. In Firebase Console, click the iOS icon to add an iOS app
2. Enter your bundle ID: `com.yourcompany.crohnsCompanion`
   - Find this in Xcode project settings or `ios/Runner.xcodeproj`
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/` directory
5. Follow Firebase setup instructions for Xcode configuration

#### For Web (Optional):
1. In Firebase Console, click the Web icon to add a web app
2. Register app with nickname: `Crohn's Companion Web`
3. Copy the Firebase configuration object (you'll use this later)

---

## Flutter Configuration

### 1. Install Dependencies

Run the following command to install Firebase packages:

```bash
flutter pub get
```

This will install:
- `firebase_core` - Firebase core functionality
- `firebase_auth` - Authentication
- `cloud_firestore` - Cloud Firestore database
- `firebase_storage` - Cloud Storage
- `firebase_analytics` - Analytics

### 2. Android Configuration

Edit `android/app/build.gradle`:

```gradle
// Add this at the top of the file (if not already present)
plugins {
    id 'com.android.application'
    id 'kotlin-android'
    id 'com.google.gms.google-services'  // Add this line
}

dependencies {
    // ... existing dependencies
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
}
```

Edit `android/build.gradle`:

```gradle
buildscript {
    dependencies {
        // ... existing dependencies
        classpath 'com.google.gms:google-services:4.4.0'  // Add this line
    }
}
```

### 3. iOS Configuration

Edit `ios/Podfile`:

```ruby
# Uncomment this line to define a global platform for your project
platform :ios, '12.0'  # Firebase requires iOS 12 minimum

# Add this at the end of the file
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
```

Run pod install:
```bash
cd ios
pod install
cd ..
```

### 4. Web Configuration (Optional)

Create `web/firebase-config.js` with your Firebase web configuration:

```javascript
// Replace with your Firebase config from Firebase Console
const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abcdef123456"
};
```

---

## Environment Configuration

### 1. Configure `.env` File

Open `.env` in the project root and set Firebase mode:

**For Mock Data (Development):**
```env
# Firebase Configuration
USE_FIREBASE=false
USE_MOCK_DATA=true
```

**For Live Firebase (Production):**
```env
# Firebase Configuration
USE_FIREBASE=true
USE_MOCK_DATA=false
```

### 2. Create Production Environment

Create `.env.production` for production builds:

```env
# Supabase Configuration (if still using)
SUPABASE_URL=your_production_supabase_url
SUPABASE_ANON_KEY=your_production_key

# LLM Configuration
LLM_API_KEY=your_production_llm_key
LLM_MODEL=gpt-4
LLM_ENDPOINT=https://api.openai.com/v1/chat/completions

# Mixpanel Configuration
MIXPANEL_TOKEN=your_production_mixpanel_token
MIXPANEL_PROJECT_ID=your_production_project_id

# Firebase Configuration
USE_FIREBASE=true
USE_MOCK_DATA=false
```

### 3. Build Flavors (Optional)

To use different environments automatically:

```bash
# Development (uses .env - mock data)
flutter run

# Production (uses .env.production - live Firebase)
flutter run --dart-define=FLAVOR=production
```

---

## Running with Mock Data vs Firebase

### Mock Data Mode (Default)

**When to use:**
- Local development without internet
- Rapid prototyping
- UI/UX testing
- Writing unit tests

**Configuration:**
```env
USE_FIREBASE=false
USE_MOCK_DATA=true
```

**Features:**
- No Firebase setup required
- Instant data loading
- Seeded with sample data
- All data stored in memory (resets on app restart)
- See `lib/core/firebase/mock_data_provider.dart` for mock data

**Run the app:**
```bash
flutter run
```

### Firebase Mode

**When to use:**
- Production deployment
- Integration testing with real backend
- Multi-device data sync
- Persistent data storage

**Configuration:**
```env
USE_FIREBASE=true
USE_MOCK_DATA=false
```

**Features:**
- Real-time data synchronization
- Persistent cloud storage
- User authentication
- Secure data access

**Run the app:**
```bash
flutter run
```

### Switching Between Modes

Simply edit `.env` and restart the app:

```bash
# Stop the app (Ctrl+C in terminal)
# Edit .env and change USE_FIREBASE and USE_MOCK_DATA
flutter run
```

The app will automatically detect the mode on startup and log:
```
FirebaseService initialized successfully (using mock data)
# or
FirebaseService initialized successfully (using Firebase data)
```

---

## Firestore Data Structure

### Collections and Documents

The app uses the following Firestore structure:

```
users/
  {userId}/
    - name: string
    - email: string
    - age: number
    - diagnosedYear: number
    - createdAt: timestamp
    
    health_data/
      {entryId}/
        - date: timestamp
        - symptomSeverity: number (1-10)
        - notes: string
        - meals: array[string]
        - createdAt: timestamp
    
    settings/
      notifications/
        - morningReminder: boolean
        - morningTime: string (HH:mm)
        - eveningReminder: boolean
        - eveningTime: string (HH:mm)
        - medicationReminders: boolean
        - symptomTracking: boolean
```

### Security Rules

Update Firestore security rules in Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User data is private - only the user can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Health data subcollection
      match /health_data/{entryId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Settings subcollection
      match /settings/{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

---

## Testing

### 1. Test Mock Data Mode

```bash
# Ensure .env has mock mode enabled
USE_FIREBASE=false
USE_MOCK_DATA=true

# Run the app
flutter run

# Check console logs
# Should see: "FirebaseService initialized successfully (using mock data)"
```

### 2. Test Firebase Mode

```bash
# Ensure .env has Firebase enabled
USE_FIREBASE=true
USE_MOCK_DATA=false

# Run the app
flutter run

# Check console logs
# Should see: "FirebaseService initialized successfully (using Firebase data)"
```

### 3. Create Test User

Using Firebase Authentication:

1. Open Firebase Console → Authentication
2. Click **Add User**
3. Enter test email: `test@example.com`
4. Enter password: `testpassword123`
5. Use these credentials in the app

### 4. Verify Data Access

In the app:
1. Sign in with test credentials
2. Navigate to data entry screens
3. Add health tracking data
4. Verify data appears in Firestore Console

---

## Usage in Code

### Accessing the Data Provider

```dart
import 'package:crohns_companion/core/firebase/firebase_service.dart';

// Get the data provider (automatically switches based on .env)
final dataProvider = FirebaseService.dataProvider;

// Get user profile
final profile = await dataProvider.getUserProfile('user123');

// Save health data
await dataProvider.saveHealthData('user123', {
  'date': DateTime.now(),
  'symptomSeverity': 5,
  'notes': 'Feeling better today',
  'meals': ['Oatmeal', 'Chicken salad'],
});

// Get notification preferences
final prefs = await dataProvider.getNotificationPreferences('user123');

// Sign in
final userId = await dataProvider.signIn('email@example.com', 'password');

// Check which mode is active
if (FirebaseService.isUsingMock) {
  print('Using mock data');
} else {
  print('Using live Firebase');
}
```

---

## Troubleshooting

### Issue: "Firebase not initialized"

**Solution:**
- Ensure `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is in the correct location
- Run `flutter clean` and `flutter pub get`
- For iOS, run `cd ios && pod install && cd ..`

### Issue: App uses wrong mode (mock vs Firebase)

**Solution:**
- Check `.env` file configuration
- Restart the app completely (stop and rerun)
- Check console logs for "FirebaseService initialized successfully (using...)"
- Verify `Environment.initialize()` is called in `main.dart`

### Issue: Permission denied errors in Firestore

**Solution:**
- Verify Firestore security rules allow access
- Ensure user is authenticated before accessing data
- Check user ID matches the document path

### Issue: Android build fails with Firebase errors

**Solution:**
- Verify `com.google.gms:google-services` plugin is added to `android/build.gradle`
- Ensure `google-services.json` is in `android/app/`
- Run `flutter clean` and rebuild

### Issue: iOS build fails with Firebase errors

**Solution:**
- Verify `GoogleService-Info.plist` is in `ios/Runner/`
- Ensure iOS deployment target is 12.0 or higher
- Run `cd ios && pod install && cd ..`
- Clean build folder in Xcode

### Issue: Mock data not appearing

**Solution:**
- Check `.env` has `USE_MOCK_DATA=true`
- Verify `MockDataProvider.initialize()` seeds data correctly
- Check console for initialization logs

---

## Next Steps

1. **Run `flutter pub get`** to install Firebase dependencies
2. **Configure `.env`** to use mock mode for development
3. **Test the app** in mock mode to verify functionality
4. **Set up Firebase project** when ready for production
5. **Switch to Firebase mode** by updating `.env`
6. **Update Firestore security rules** before production deployment
7. **Create production environment** with `.env.production`

---

## Additional Resources

- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)

---

## Support

For issues or questions:
- Check the [Troubleshooting](#troubleshooting) section
- Review Firebase Console for errors
- Check console logs in the app
- Verify `.env` configuration
