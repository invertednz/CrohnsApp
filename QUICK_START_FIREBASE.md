# Firebase Quick Start Guide

A quick reference for getting started with Firebase integration in Crohn's Companion.

## Current Status

The app is **currently configured to use MOCK DATA** by default. This means:
- ✅ No Firebase setup required to run the app
- ✅ Sample data is pre-loaded for testing
- ✅ All features work locally without internet
- ⚠️ Data resets when app restarts

## Running the App Right Now

```bash
# Just run - no Firebase needed!
flutter pub get
flutter run
```

The app will automatically use mock data and log:
```
FirebaseService initialized successfully (using mock data)
```

---

## Quick Mode Switching

### Use Mock Data (Current Default)
Edit `.env`:
```env
USE_FIREBASE=false
USE_MOCK_DATA=true
```

**Benefits:**
- No setup required
- Fast development
- Works offline
- Great for UI testing

### Use Live Firebase
Edit `.env`:
```env
USE_FIREBASE=true
USE_MOCK_DATA=false
```

**Requirements:**
- Firebase project created
- `google-services.json` added (Android)
- `GoogleService-Info.plist` added (iOS)
- Firebase services enabled

**See `FIREBASE_SETUP.md` for complete Firebase setup instructions.**

---

## File Structure Created

```
lib/core/firebase/
  ├── firebase_service.dart       # Main service (auto-switches modes)
  ├── data_provider.dart          # Interface for data operations
  ├── firebase_data_provider.dart # Real Firebase implementation
  ├── mock_data_provider.dart     # Mock data implementation
  └── usage_example.dart          # Code examples
```

---

## How to Use in Your Code

```dart
import 'package:crohns_companion/core/firebase/firebase_service.dart';

// The same code works for both mock and Firebase modes!
final dataProvider = FirebaseService.dataProvider;

// Get user data
final profile = await dataProvider.getUserProfile(userId);

// Save health data
await dataProvider.saveHealthData(userId, {
  'date': DateTime.now(),
  'symptomSeverity': 5,
  'notes': 'Feeling better',
});

// Check which mode is active
print('Using ${FirebaseService.isUsingMock ? "mock" : "Firebase"} data');
```

See `lib/core/firebase/usage_example.dart` for more examples.

---

## When to Switch to Firebase

Switch to Firebase when you need:
- ✅ Persistent data storage
- ✅ Real user authentication
- ✅ Multi-device sync
- ✅ Production deployment
- ✅ Cloud backups

---

## Next Steps

### For Development (Keep Mock Mode)
1. Run `flutter pub get`
2. Start coding - mock data is ready to go!

### For Production (Switch to Firebase)
1. Read `FIREBASE_SETUP.md` (comprehensive guide)
2. Follow `env_todo.md` checklist
3. Create Firebase project
4. Add config files
5. Update `.env` to enable Firebase
6. Test thoroughly before production

---

## Quick Troubleshooting

**App won't run?**
```bash
flutter clean
flutter pub get
flutter run
```

**Want to see which mode is active?**
Check the console logs when the app starts:
```
FirebaseService initialized successfully (using mock/Firebase data)
```

**Need to reset mock data?**
Just restart the app - mock data reseeds automatically.

---

## Documentation Files

- 📘 **FIREBASE_SETUP.md** - Complete Firebase setup guide (comprehensive)
- 📋 **env_todo.md** - Environment setup checklist
- 💡 **QUICK_START_FIREBASE.md** - This file (quick reference)
- 📝 **lib/core/firebase/usage_example.dart** - Code examples

---

**Remember:** The app works perfectly right now with mock data. Only switch to Firebase when you're ready for production!
