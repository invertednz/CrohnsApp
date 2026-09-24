# GutMD codebase map

Flutter app (web + iOS) for people with Crohn's, ulcerative colitis, IBS and related
conditions. Backend: Firebase project `gutmd-app` (Auth, Firestore, Hosting, Firebase AI
Logic for Gemini). Offline/E2E builds use an in-memory mock backend.

## Entry and core

| File                                     | Purpose                                                                                   |
| ---------------------------------------- | ----------------------------------------------------------------------------------------- |
| `lib/main.dart`                          | App entry; enables the web semantics tree; starts backend init                            |
| `lib/core/environment.dart`              | Build-time config via `--dart-define-from-file=config/<env>.json` (public values only)    |
| `lib/firebase_options.dart`              | Firebase web + iOS options for `gutmd-app`                                                |
| `lib/core/backend_service_provider.dart` | `AppUser`, backend interfaces (auth/tracking/insights/chat), AI context helpers, provider |
| `lib/core/firebase_backend.dart`         | Firebase implementation (Auth incl. guest linking, Firestore `users/{uid}/...`)           |
| `lib/core/mock_backend.dart`             | In-memory implementation for `USE_MOCK_DATA=true` and Firebase fallback                   |
| `lib/core/app_state.dart`                | Shared selected date + restored onboarding answers                                        |

## AI (Gemini via Firebase AI Logic, no client API key)

| File                                      | Purpose                                                                   |
| ----------------------------------------- | ------------------------------------------------------------------------- |
| `lib/services/gemini_client.dart`         | `GeminiClient.chat` / `GeminiClient.json` (schema-constrained), timeouts  |
| `lib/services/ai_chat_service.dart`       | Chat assistant + `UserHealthContext` summary; data-aware offline fallback |
| `lib/services/insights_generator.dart`    | Insights (Gemini, grounded by on-device stats) + `localInsights`          |
| `lib/services/meal_analysis_service.dart` | Meal photo analysis (Gemini vision)                                       |
| `lib/services/daily_log_service.dart`     | Free-text diary entry analysis                                            |
| `lib/services/gut_plan_service.dart`      | Personalised 14-day plan at the end of onboarding                         |

## Screens

- `lib/screens/splash_screen.dart`: routes signed-in users to Home (restores onboarding answers), others to onboarding
- `lib/screens/onboarding/`: quiz flow (`onboarding_flow.dart`, `onboarding_controller.dart` incl. `OnboardingProfileStore`), steps in `screens/`: welcome, condition, goal, expected results, tracking journey, app tour, reminders, diet, supplements, lifestyle, medications, symptoms, thank you, **plan building → plan reveal → commitment**, trial offer, timeline, compare plans, payment, discount, referral
- `lib/screens/auth/`: sign in (+ forgot password), sign up (+ continue as guest)
- `lib/screens/home/home_screen.dart`: dashboard (check-in, counters, wellbeing ring, plan, milestones, diary, meal photo) + bottom tabs
- `lib/screens/{symptoms,supplements,medications,chat}/`: tabs
- `lib/screens/{tracking,diet,insights}/`: detail screens opened from Home
- `lib/widgets/`: `calendar_bar`, `gut_score_ring`, `milestone_badges`, `referral_rewards_card`

## Infra and tests

| Path                                              | Purpose                                                                          |
| ------------------------------------------------- | -------------------------------------------------------------------------------- |
| `firebase.json`, `.firebaserc`, `firestore.rules` | Hosting (SPA rewrite, headers) and per-user Firestore rules                      |
| `config/prod.json`, `config/test.json`            | Build configs (test = offline mock build)                                        |
| `test/`                                           | Dart unit + widget tests (`flutter test`)                                        |
| `tests/e2e/flutter/`                              | Playwright E2E suite against the Flutter web build (`npm run test:flutter`)      |
| `playwright.flutter.config.ts`                    | E2E config (serves `build/web-test` on :3400; `VIDEO=1` records every test)      |
| `tests/e2e/*.spec.ts`, root `*.html`              | Legacy static HTML mockups and their tests (`npm run test:mockups`), not the app |
| `docs/specs/`                                     | Task specs                                                                       |
