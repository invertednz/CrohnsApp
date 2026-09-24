# Spec: GutMD audit, Firebase + Gemini wiring, full E2E video suite, stickier onboarding

## Goal

Get the GutMD (Crohn's companion) Flutter app into a verifiably working, hosted state:
every built feature works on the web build, AI features run on Gemini, the app is
hosted on Firebase, a large Playwright suite exercises all functionality on video,
and the onboarding/home experience is redesigned to convert and retain better
(inspired by Cal AI and other viral health apps).

## Baseline findings (2026-09-24)

- `flutter build web` failed to compile (`CardTheme` vs `CardThemeData`, `signOut` on wrong object).
- `.env` / `.env.production` committed to the PUBLIC GitHub repo and bundled as a Flutter
  asset (served at `/assets/.env`). The OpenAI and Gemini keys in them are revoked (401/invalid).
- No Firebase project, no `firebase.json`, no `firebase_options.dart`; `Firebase.initializeApp()`
  without options always failed and silently fell back to mock data.
- All screens use `BackendServiceProvider` (Supabase), whose init is skipped on web, so
  sign-up / onboarding completion / chat / insights / tracking hit an uninitialised service.
- Chat AI used an OpenAI endpoint; meal photo analysis used retired `gemini-1.5-flash` and
  `dart:io File` (unsupported on web).
- Existing Playwright suite tested static HTML mockups in the repo root, not the Flutter app.

## Stories / Acceptance Criteria

- [x] US-1: Web build compiles cleanly (`flutter build web` exit 0, `flutter analyze` no errors).
- [x] US-2: No secrets ship in the app or repo: `.env*` untracked + gitignored, not a Flutter asset;
      config via `--dart-define-from-file` with public values only.
- [x] US-3: Firebase is the real backend: `firebase_options.dart` for project `gutmd-app`;
      auth (email/password + guest), tracking, insights and chat history persist in Firestore
      under `users/{uid}/...`; Firestore security rules restrict each user to their own data.
- [x] US-4: AI runs on Gemini via Firebase AI Logic (no API key in client): chat assistant
      (personalised with tracked data), meal photo analysis (web-compatible bytes), and AI insights.
      Offline/mock mode uses deterministic local responses.
- [x] US-5: Firebase Hosting configured (`firebase.json`, `.firebaserc`, SPA rewrites, caching
      headers) and the build deployed to a preview channel that loads and works.
- [x] US-6: Playwright harness for the Flutter web build (semantics-enabled), with specs covering
      every feature area: onboarding (all steps, paywall, discount, referral), auth, home dashboard,
      daily tracking, symptoms, diet + meal AI, supplements, medications, insights, chat, navigation,
      responsive/mobile. All pass in mock mode.
- [x] US-7: Full suite recorded to video (`videos/`), reviewed, and any failures fixed.
- [ ] US-8 (blocked: enable Email/Password + Anonymous in Firebase Auth and Gemini Developer API in AI Logic, then run `npx playwright test -c playwright.live.config.ts`): Real-backend smoke spec passes against the preview channel (guest sign-in, save
      tracking to Firestore, Gemini chat reply).
- [x] US-9: Onboarding redesigned for conversion (Cal AI-style: personalised quiz, progress bar,
      instant "your plan" reveal, social proof, commitment step, soft paywall with trial timeline).
- [x] US-10: Home/retention redesign for stickiness (daily check-in streak, quick-log, gut score,
      progress ring, AI insight card), with specs + video updated and passing.

## Scope

- IN: Flutter web + shared Dart code, Firebase project `gutmd-app`, Playwright E2E, docs.
- OUT: App Store / Play Store release, real payment processing (paywall stays a UI flow),
  rewriting git history to purge old keys (keys are revoked; user must rotate in consoles).

## Files Expected to Change

- pubspec.yaml, lib/main.dart, lib/core/environment.dart, lib/core/backend_service_provider.dart
- lib/core/firebase/* (replaced by lib/core/firebase_backend.dart), lib/firebase_options.dart
- lib/FlutterBackend/src/core/* (Supabase removed; mock kept)
- lib/services/ai_chat_service.dart, lib/services/meal_analysis_service.dart
- lib/screens/** (bug fixes, redesign), lib/core/theme/*
- firebase.json, .firebaserc, firestore.rules, config/*.json, .gitignore
- playwright.flutter.config.ts, tests/e2e/flutter/**

## Results (2026-09-25)

- Dart unit + widget tests: 160 passing (`flutter test`).
- Flutter web E2E (offline build): 234 tests across 17 specs; final recorded run in `videos/e2e/`
  (per-test `.webm`, `index.html`, and a stitched `walkthrough.mp4`).
- Firebase project `gutmd-app`: Firestore (australia-southeast1) + rules deployed, web and iOS
  apps registered, production build on Hosting preview channel
  https://gutmd-app--preview-7czgn8h6.web.app (live site not deployed).
- Follow-ups: Terms/Privacy documents; reminder notifications (no push/local notification
  infrastructure yet); referral crediting and real payments need a server; rotate the leaked
  OpenAI/Gemini/Supabase keys still present in git history.
