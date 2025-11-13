# Environment Configuration To-Do

## Mixpanel Setup
- [ ] Add `MIXPANEL_TOKEN` to `.env` with the live project token (keep it private).
- [ ] Optionally set `MIXPANEL_PROJECT_ID` in `.env` if referenced in code or analytics dashboards.
- [ ] Mirror Mixpanel values into `.env.production` or other deployment env files so releases load the token.
- [ ] Configure Mixpanel environment variables in CI/CD or hosting platforms so `Environment.initialize()` can read them in non-local builds.

## Firebase Setup
- [ ] Review `FIREBASE_SETUP.md` for comprehensive Firebase integration guide.
- [ ] Decide whether to use mock data or Firebase (set `USE_FIREBASE` and `USE_MOCK_DATA` in `.env`).
- [ ] If using Firebase:
  - [ ] Create Firebase project in Firebase Console.
  - [ ] Register Android app and download `google-services.json` to `android/app/`.
  - [ ] Register iOS app and download `GoogleService-Info.plist` to `ios/Runner/`.
  - [ ] Enable Firebase Authentication (Email/Password provider).
  - [ ] Enable Firestore Database and configure security rules.
  - [ ] Update `.env` to set `USE_FIREBASE=true` and `USE_MOCK_DATA=false`.
  - [ ] Test authentication and data operations.
- [ ] If using mock data (for development):
  - [ ] Keep `USE_FIREBASE=false` and `USE_MOCK_DATA=true` in `.env`.
  - [ ] No Firebase setup required - app will use in-memory mock data.

## General
- [ ] Ensure `.env.example` stays updated with all placeholder values for teammates (already contains keys; verify before committing).
- [ ] Run `flutter pub get` after editing environment files or pubspec.yaml.
- [ ] Create `.env.production` with production values before deploying to production.
