# PageWatcher Mobile: Plan and Status

## Context
PageWatcher is a website-change monitoring SaaS:
- Web repo: `github.com/YavuzKacar/changeradar`, usually cloned next to this repo as `../pagewatcher`.
- React/Vite SPA frontend.
- FastAPI + Postgres + Celery backend at `https://api.pagewatcher.app/api/v1`.

All scraping, diffing, AI filtering and notifications run on the server. This app is a **thin native client of the existing REST API**, plus **push notifications**, which are new.

Decisions (confirmed by the owner):
- Flutter for Android + iOS.
- **No in-app purchases in v1.** The app shows the plan and limits and links to the website for upgrades.
- **FCM push in v1.** This needs backend work.
- Sign-in with email, Google and Apple.
- Scope: AI chat, monitors and changes, settings. **Admin pages stay web-only.**

## Status (as of 2026-09-28)
| # | Milestone | State |
|---|---|---|
| 0 | Setup: Flutter SDK, `flutter create .`, platform config, Firebase project | **Pending.** android/ and ios/ are not generated yet |
| 1 | Foundation: theme, router, dio + auth refresh, secure storage, env, i18n | Code written, **never compiled** |
| 2 | Auth: email, Google, Apple, onboarding, trial screen, forgot/reset, basic settings | Code written, **never compiled** |
| 3 | Monitors: list, detail (history + diff + HTML view), create/edit sheet, classify badge, check-now polling | Next |
| 4 | Changes feed | |
| 5 | Chat: SSE client, conversation drawer, streaming UI, markdown, tool cards | |
| 6 | Settings: profile, password, channels, language, plan, delete/export, feedback | |
| 7 | Push: backend + client | |
| 8 | Deep links, icons/splash, store metadata, release signing | |

Milestones 1–2 were written on a machine without Flutter. Expect some compile errors on the first `flutter analyze`, especially in third-party APIs: google_sign_in v7, sign_in_with_apple, Riverpod 3, and `RadioGroup` (Flutter 3.35+).

Deviations from the original design:
- JSON models are hand-written instead of generated with freezed.
- Icons are Material icons, not lucide.
- Register logs in automatically.
- The Apple button is shown on iOS only.

## Tech stack
| Area | Choice |
|---|---|
| State | `flutter_riverpod` 3, manual providers (no codegen) |
| Routing | `go_router` with an auth redirect and `StatefulShellRoute` bottom tabs |
| HTTP | `dio` + `AuthInterceptor` (single-flight refresh, a port of the web `frontend/src/services/api.ts`) |
| Token storage | `flutter_secure_storage` |
| Chat SSE | manual `\n\n` frame parser over a dio `ResponseType.stream` POST (port of `frontend/src/hooks/useChatStream.ts`) |
| Diff | `diff_match_patch` (word-level, replacing jsdiff) |
| HTML snapshot | `webview_flutter` `loadHtmlString`, with JS disabled |
| Social auth | `google_sign_in` v7 (`serverClientId` = web client ID) and `sign_in_with_apple` |
| Push | `firebase_core`, `firebase_messaging`, `flutter_local_notifications` |
| Deep links | `app_links` |
| i18n | `flutter gen-l10n`; ARB files generated from the web locales by `tool/convert_i18n.mjs` |

Theme: light only. Primary `#1642F2`, brand gradient from primary-600 to purple-600, gray-50 background. Accents: orange for changed, green for active, violet for AI. Cards have 16px radius. See `lib/core/theme/`.

## Screens → API (`/api/v1`, Bearer JWT)
- **Monitors list:**
  - `GET /monitors/`.
  - Pause/resume with `PATCH /monitors/{id}` `{is_active}`.
  - Run now with `POST /monitors/{id}/check`. It returns 202; 429 means a 60s cooldown.
  - `DELETE /monitors/{id}`.
- **Monitor detail:**
  - `GET /monitors/{id}`, `GET /snapshots/monitor/{id}?limit=`, `GET /snapshots/monitor/{id}/changes`.
  - The diff is computed client-side between consecutive snapshots' `content_text`.
  - After "Check now", poll snapshots for about 60s.
  - A snapshot with `metadata.error` is a failed check.
- **Monitor form** (port of `frontend/src/components/AddMonitorModal.tsx`):
  - url, name, check_interval from `[5, 15, 20, 30, 60, 180, 360, 720, 1440]` filtered by the plan minimum (free 60, individual 20, pro 5).
  - notify_on `first_change|every_change`, use_javascript (Pro only), ai_prompt (max 500 characters), ai_sensitivity `strict|balanced|lenient`.
  - notification_channels, webhook_url.
  - "Test AI prompt": `POST /monitors/{id}/test-ai-prompt`.
  - Debounced `POST /classify {url, max_probe_level, probe_timeout_ms}` for the difficulty badge.
- **Changes feed:** `GET /monitors/recent-changes?limit=`.
- **Chat:**
  - Conversations: `GET/POST /chat/conversations`, `PATCH/DELETE /chat/conversations/{id}`, `GET .../messages`.
  - Sending: `POST .../messages {content, language}` streams SSE events `token`, `tool_start`, `tool_result`, `title`, `done`, `error`.
- **Settings:**
  - Account: `PATCH /auth/me`, `POST /auth/change-password`, `DELETE /auth/me {password}`, `GET /auth/me/export`.
  - `/notification-channels/` CRUD, and `POST /feedback/`.
- Plan limits: hardcode them in one `plan_limits.dart`, as the web does.

The TypeScript types in the web repo's `frontend/src/services/api.ts` are the reference for Dart models.

## Backend changes needed (web repo, **deployed on the owner's Windows server**)
Don't change the backend without asking the owner. It had uncommitted work in progress in `auth.py` and `config.py`.
1. **Apple audience:** accept the iOS bundle ID as well as the Services ID.
   - Add `APPLE_CLIENT_IDS` (comma-separated) to `backend/app/config.py`.
   - In `_verify_apple_id_token` (`backend/app/api/routes/auth.py`), decode with `verify_aud=False`, then check that `aud` is in the allowed set.
2. **Device tokens:**
   - Model `device_tokens` (id, user_id, token unique, platform, app_version, last_seen_at, created_at) and Alembic migration `032`.
   - `POST /devices` (upsert) and `DELETE /devices/{token}`.
3. **Push channel:** add `"push"` to `VALID_CHANNEL_TYPES` in `backend/app/schemas/notification_channel.py`.
4. **Sender:**
   - `services/push_service.py` with `firebase-admin`.
   - Called from `send_change_notification` in `backend/app/workers/tasks.py`, with data `{monitor_id, snapshot_id}`.
   - Prune tokens that FCM reports as unregistered.
5. **Deep links:** serve `.well-known/apple-app-site-association` and `assetlinks.json` from the web frontend's `public/` folder.

## Prerequisites from the owner
- A Firebase project.
- An Apple Developer account (APNs key, Sign in with Apple, bundle ID).
- Google OAuth client IDs: Android (SHA-1) and iOS.
- A Mac or CI (e.g. Codemagic) for iOS builds.

## Verification
- `flutter analyze` and `flutter test`.
- Unit tests: the SSE parser (frames split across chunks), the interceptor, and model round-trips.
- Run on the Android emulator with `flutter run --dart-define-from-file=env/dev.json` (the backend at `10.0.2.2:8000`).
- Push end to end: a change on a test monitor produces a notification, and tapping it opens the monitor.
