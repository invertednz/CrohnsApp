# Patterns and gotchas

## Build and run

- Offline E2E build: `npm run build:web:test` → `build/web-test` (mock backend, deterministic AI).
- Production build: `npm run build:web` → `build/web`; deploy with `npm run deploy:preview` (preview channel) — use `firebase-tools@14`; the latest release currently fails on Node 22 with `ERR_REQUIRE_ESM`.
- Never put secrets in `config/*.json` or assets: everything compiled into the app is public. `.env*` files are gitignored and no longer read.

## Backend contract

- Always go through `BackendServiceProvider.instance` (await `BackendServiceProvider.initialize()` first; splash does this).
- `tracking.trackEvent(userId, type, data)` **merges** into the entry keyed by `data['entry_id'] ?? data['date']` (`yyyy-MM-dd`). Types and shapes are documented in `backend_service_provider.dart` and read by the AI (`insightTrackingTypes`, `buildHealthContext`).
- Onboarding answers are the `profile` entry with id `onboarding` (`OnboardingProfileStore`).
- Firestore rules only allow `users/{uid}/**` for the signed-in uid; anything cross-user (e.g. crediting referrals) needs a Cloud Function.
- Guest users are Firebase anonymous accounts; sign-up and Google/Apple sign-in **link** the guest account so data is kept.

## AI

- Use `GeminiClient` only (Firebase AI Logic, Gemini Developer API). Model comes from `Environment.geminiModel`.
- Every AI feature needs an honest non-AI fallback; never show fabricated numbers or a made-up analysis to a real user. The fixed sample meal analysis is only for `USE_MOCK_DATA` builds.
- No diagnosis, no medication-change advice; keep claims about outcomes out of UI copy.

## E2E (Playwright + Flutter web)

- `main.dart` calls `SemanticsBinding.instance.ensureSemantics()` on web, so controls are DOM nodes: buttons → `role=button` named by text; single-choice pickers → `role=radio`; text fields → `<input>` with `aria-label`.
- Only on-screen widgets exist in the DOM: use `scrollUntilVisible` / `expectText` from `tests/e2e/flutter/helpers.ts`.
- Snackbar text is mirrored into `<flt-announcement-polite>`: use `onScreen(page).getByText(...)` to avoid strict-mode double matches.
- Icon-only buttons need a `tooltip:` (or `Semantics(label:)`) or tests and screen readers can't find them.
- Clicks can't hold: for the Commitment screen use `page.mouse.down()`, wait ≥1.3 s, `page.mouse.up()`.
- Run many workers with separate `--output` dirs; Playwright wipes `outputDir` on start.
