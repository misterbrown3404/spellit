# SpellIt Production Readiness Audit and Refactor Plan

Last updated: 2026-07-13 19:20 Africa/Lagos

## Executive Summary

SpellIt has a playable feature set and already includes several production-minded pieces such as Firebase Auth, Firestore, Analytics observer support, offline Firestore persistence, Riverpod, Material 3 themes, tests, and an initial network retry utility. The app is not yet production-ready for a 20,000-user launch because the current architecture mixes UI, Firebase access, business rules, navigation, and error handling across screens and services.

The safest path is a phased hardening refactor:

1. Stabilize foundation: error handling, logging, dependency injection, routing, network status, and Firebase wrappers.
2. Reduce Firebase cost and risk: pagination, transaction correctness, rules coverage, indexes, batched writes, and no client-side trust for privileged actions.
3. Improve UI resilience: responsive layouts, loading/empty/error states, accessibility, and keyboard safety.
4. Improve testability: repository interfaces, meaningful unit tests, widget tests for critical flows, and integration tests for launch paths.
5. Add production capabilities: Crashlytics, Performance Monitoring, Remote Config, App Check, feature flags, force update, maintenance mode, deep links, privacy/legal support, and release checks.

## Current Scores

These scores reflect the current repository state from the first audit pass, not the target state.

| Area | Score | Notes |
| --- | ---: | --- |
| Architecture | 4/10 | Feature folders exist, but clean architecture boundaries are missing. Widgets and services directly use Firebase singletons. |
| UI/UX | 5/10 | Strong visual identity exists, but many large screens contain hardcoded sizing, direct strings, inconsistent loading/error states, and likely overflow risks. |
| Performance | 4/10 | Large stateful screens, direct stream usage, broad rebuilds, and no systematic provider selection. |
| Firebase implementation | 4/10 | Auth/Firestore are present, offline persistence is enabled, but rules are incomplete for used collections, errors are swallowed, queries need indexing/pagination review. |
| Security | 3/10 | Firestore rules do not cover all active collections; token logging exists; privileged game state is client-controlled. |
| Accessibility | 4/10 | Material widgets help, but semantic labels, text scaling, focus traversal, and touch target audits are needed. |
| Scalability | 4/10 | Some limits exist, but chat/leaderboard/public room streams and user document writes need cost controls. |
| Code quality | 4/10 | Duplicate/dead services, large files, commented-out modules, direct Firebase usage, and weak analyzer enforcement. |
| Maintainability | 4/10 | Business logic is spread across UI and services; missing repository/domain boundaries make changes risky. |
| Overall launch readiness | 40/100 | Not ready for public launch without additional hardening. |

## What Is Good

- Flutter project supports multiple platforms: Android, iOS, macOS, Windows, Linux, and Web.
- Material 3 is enabled in `lib/core/theme.dart`.
- App already uses Riverpod and GoRouter dependencies.
- Firebase Auth, Firestore, Analytics, Messaging, and generated Firebase options are present.
- Firestore offline persistence is enabled in `lib/main.dart`.
- Initial network retry/timeout helper exists in `lib/core/network_utils.dart`.
- Initial connectivity overlay exists in `lib/core/network_status.dart`.
- Several tests exist under `test/`, including network, lobby, notification, and model tests.
- Firestore security rules and indexes files exist in the repository.

## Dangerous / Launch-Blocking Issues

### 1. Router Is Defined But Not Used — RESOLVED

- `lib/core/router.dart` defines `GoRouter`.
- `lib/main.dart` previously used `MaterialApp(home: ...)` instead of `MaterialApp.router`.
- Result: auth redirects, unknown route handling, deep linking, and navigation consistency were not production-grade.

Fix applied (2026-07-13):

- `lib/main.dart` now boots with `MaterialApp.router` using `routerProvider`.
- Router exposes `/splash`, `/login`, `/tutorial`, `/`, and all feature routes.
- Added `errorBuilder` -> `RouteNotFoundScreen` for unknown/deep-link routes.
- Added a `refreshListenable` (`_RouterNotifier`) so redirect re-runs on auth,
  bootstrap, and tutorial state changes without rebuilding the router.
- Redirect waits on `appInitializedProvider` and the first auth emission before
  routing, then gates login -> tutorial -> main.
- `FirebaseAnalyticsObserver` is attached to the GoRouter navigator.

### 2. Firebase Access Is Coupled To UI And Services

Examples:

- `FirebaseFirestore.instance` is used directly in screens and services.
- `FirebaseAuth.instance` is used directly in providers and app boot.
- Services create their own Firebase instances instead of receiving dependencies.

Risk:

- Hard to test.
- Hard to mock.
- Inconsistent timeout/retry/error behavior.
- Higher chance of duplicate reads and silent failures.

Planned fix:

- Add provider-based dependency injection for FirebaseAuth, FirebaseFirestore, FirebaseMessaging, Analytics, and future Crashlytics/Remote Config.
- Introduce repository interfaces for auth, profile, rooms, notifications, leaderboard, rewards, and chat.

### 3. Error Handling Is Inconsistent

Examples:

- Multiple `catch (e)` blocks only `debugPrint` and continue.
- Some errors are rethrown as generic `Exception`, losing typed context.
- Initialization failure still marks app initialized and proceeds without clear user recovery.
- Firebase token fetch/save failures are silently skipped.

Planned fix:

- Add a centralized `AppError`, `ErrorClassifier`, and `AppLogger`.
- Use safe user-facing messages and developer-facing structured logs.
- Route unhandled Flutter/platform errors to the logger and Crashlytics when added.

### 4. Sensitive Token Logging

Example:

- `lib/core/notification_service.dart` logs `FCM Token: $fcmToken`.

Risk:

- FCM tokens are sensitive identifiers and should not be logged in production.

Planned fix:

- Remove token value logging.
- Use sanitized logging only.
- Add production log level gating.

### 5. Duplicate / Dead Notification Services — RESOLVED

Examples:

- `lib/core/notification_service.dart` contains Firebase Messaging logic.
- `lib/services/notification_service.dart` previously contained a singleton stub with the same class name.

Fix applied (2026-07-13):

- Deleted `lib/services/notification_service.dart` (and the now-empty
  `lib/services/` directory) after confirming it had zero references in `lib`
  and `test`.
- `lib/core/notification_service.dart` is the single production service.

### 6. Chat Service Is Commented Out

Example:

- `lib/features/chat/chat_service.dart` is entirely commented out.

Risk:

- Chat screens may compile only because code paths are also commented or unused.
- Dead code hides missing Firestore rules and index requirements.

Planned fix:

- Either restore chat behind a feature flag with rules/tests or remove it from production navigation.

### 7. Shop Service Is Empty

Example:

- `lib/features/shop/shop_service.dart` has no implementation.

Risk:

- Purchase/shop rules may live entirely in UI or be missing.
- In-app economy can be tampered with if client-controlled.

Planned fix:

- Create a repository/service contract for inventory, purchases, and balance changes.
- Move reward/purchase mutations into transaction-backed logic.

### 8. Firestore Rules Do Not Cover All Used Collections — RESOLVED

Rules now cover:

- `users/{userId}` (+ create/update field validation, immutable email/odid)
- `users/{userId}/achievements/{achievementId}`
- `rooms/{roomId}` (membership + join constraints + immutable field guards)
- `notifications/{notificationId}` (self-addressed only, shape validation)
- `global_chats/{messageId}` (read for signed-in, owner+length validated create, immutable)
- `private_chats/{chatId}` and its `messages` subcollection (participants-only)

Fix applied (2026-07-13):

- Rewrote `firestore.rules` to add chat collections and add shape/ownership
  validation (required fields, max string lengths, membership checks, immutable
  ownership fields, room join limits).
- Existing composite indexes already cover the room and notification list
  queries; chat queries use single-field / `arrayContains` filters that are
  auto-indexed.

Remaining (medium term): move authoritative scoring, end-game writes, and
cross-user notifications to Cloud Functions.

### 9. Client-Trusted Game State

Examples:

- Clients can update room scores, words found, active effects, status, and winners.

Risk:

- Cheating, griefing, score tampering, and billing abuse.

Planned fix:

- Short term: tighten Firestore rules around room membership, valid fields, and state transitions.
- Medium term: move authoritative score validation and end-game writes to Cloud Functions or a trusted backend.

### 10. Forced Portrait Orientation — RESOLVED

Example:

- `lib/main.dart` previously locked orientation to portrait for all platforms.

Fix applied (2026-07-13):

- `_applyPreferredOrientations()` now locks portrait only on handheld phones
  (`shortestSide < 600dp` on Android/iOS). Tablets, foldables, desktop, and web
  keep all orientations so responsive layouts can adapt.
- Added `lib/core/widgets/adaptive_content.dart` with responsive breakpoints,
  a `sizeClass` helper, and `AdaptiveContentWidth` for constraining forms/menus
  on wide viewports.

## Technical Debt Inventory

- Large screen files:
  - `lib/features/game/screens/multiplayer_game_screen.dart` ~1086 lines.
  - `lib/features/game/screens/solo_game_screen.dart` ~810 lines.
  - `lib/features/profile/screens/profile_screen.dart` ~783 lines.
  - `lib/main_menu_screen.dart` ~712 lines.
  - `lib/features/shop/screens/shop_screen.dart` ~599 lines.
- `waiting_room_screenn.dart` filename has a typo and should be migrated safely.
- Many hardcoded strings; localization is not implemented.
- Direct Firestore access in screens makes UI tests difficult.
- Large stateful widgets indicate mixed presentation and business logic.
- Analyzer rules are minimal.
- `flutter analyze` timed out during the first audit run and needs rerun after smaller refactors.
- `node_modules`, build logs, certificates, and keystore-like files are present in the workspace; repository tracking should be reviewed before launch.

## Refactor Strategy

### Phase 0: Baseline and Safety

Status: Completed for initial pass

- Completed project structure inventory.
- Captured git dirty state before edits.
- Created this living audit document.
- Attempted analyzer/tests and recorded tool timeouts.
- Preserved existing user/worktree changes.

### Phase 1: Foundation

Status: Completed

- Added `core/di/firebase_providers.dart`.
- Added `core/errors/app_error.dart`.
- Added `core/errors/error_classifier.dart`.
- Added `core/logging/app_logger.dart`.
- Updated network helper to use jittered exponential backoff and structured errors.
- Removed sensitive FCM token value logging from notification initialization.
- Wired Flutter framework errors and platform dispatcher errors to the central logger.
- Converted AuthService and NotificationService constructors to Riverpod-provided Firebase dependencies.
- Added bounded notification queries and batched mark-all-read / clear operations.
- Replaced direct `dart:io` usage in shared network/error code with a conditional platform helper for Flutter Web compatibility.
- Kept a persistent notification token-refresh listener instead of canceling it immediately after init.
- Converted route bootstrapping to a single navigation system (`MaterialApp.router` + GoRouter with redirect, refresh listenable, and unknown-route handling).

### Phase 2: Firebase and Data Layer

Status: In progress

- Introduce repository contracts:
  - Auth repository.
  - Profile repository.
  - Room repository.
  - Notification repository.
  - Leaderboard repository.
  - Daily reward repository.
  - Shop repository.
- Move direct Firestore/Auth usage out of screens.
- Add typed result models and exceptions.
- Review every query for `limit`, indexes, pagination, and billing cost.
- Replace multi-document loops with batched writes where appropriate.

Progress (2026-07-13):

- `RoomService` now receives `FirebaseFirestore` via
  `firebaseFirestoreProvider` instead of constructing the singleton internally.
- `ShopService` uses injected Firestore and a transaction-backed purchase flow
  with typed `ShopException` results.
- Notification bulk operations use batched writes; all list queries are capped.

### Phase 3: UI/UX System

Status: In progress

- Add reusable states:
  - `AppLoadingView` — added in `lib/core/widgets/app_state_views.dart`.
  - `AppErrorView` — added (normalizes any error via `ErrorClassifier`).
  - `AppEmptyView` — added.
  - `ResponsiveScaffold` — pending.
  - `AdaptiveContentWidth` — added in `lib/core/widgets/adaptive_content.dart`.
- Normalize spacing, typography, button hierarchy, and card radii.
- Add skeleton loading where data screens currently show blank loaders.
- Add pull-to-refresh where list streams are used.
- Audit text scale and touch targets.

### Phase 4: Feature Hardening

Status: Pending

- Auth: validation, autofill, focus traversal, safe password reset, session handling.
- Lobby/rooms: transaction correctness, stale room cleanup, pagination, deep links.
- Game: separate controller/domain rules from UI, reduce rebuild scope, protect score writes.
- Profile: repository extraction, optimistic updates, offline state, clear errors.
- Daily rewards/shop: transaction safety and server trust strategy.
- Notifications: token refresh, permission state, foreground display, no token logging.
- Chat: either restore with rules/moderation/pagination or remove from production.

### Phase 5: Production Integrations

Status: Pending

- Crashlytics.
- Firebase Performance Monitoring.
- Firebase Remote Config.
- Firebase App Check.
- Feature flags.
- Maintenance mode.
- Force update/app version checks.
- In-app review/rating prompt.
- Privacy policy, terms, about, contact support, licenses.
- Deep linking.
- Share support.
- Permission handling.

### Phase 6: Testing and Release

Status: Pending

- Unit tests for error classification, retry strategy, repositories, and domain rules.
- Widget tests for auth, lobby, profile, empty/error/loading states.
- Integration smoke tests for launch-critical flows.
- Firebase emulator rules tests.
- CI build/analyze/test workflow.
- Release checklist for Android/iOS/Web.

## Initial Firestore Cost Optimization Suggestions

- Use `.limit()` on every list query; already present in some room/chat queries.
- Add pagination for leaderboard, chat, notifications, public rooms, and achievements.
- Avoid listening to broad streams when a one-time fetch is enough.
- Cache static shop catalog and remote config locally.
- Batch notification mark-all-read operations.
- Avoid per-player document reads in waiting room lists; denormalize safe display fields in room membership or fetch user summaries in a capped batched approach.
- Add composite indexes for status/isPublic/createdAt, unread notifications by user, and leaderboard sort fields.

## Security Hardening Plan

- Remove sensitive log output.
- Validate Firestore writes by collection:
  - required fields,
  - allowed fields,
  - max string lengths,
  - membership checks,
  - immutable ownership fields,
  - valid enum values,
  - monotonic counters where possible.
- Move privileged scoring/rewards to trusted backend logic before serious competitive launch.
- Do not store secrets in client assets or source.
- Audit `key.properties`, keystores, certificates, and generated service files before publishing repository or CI logs.

## Responsive Design Plan

- Stop relying on global portrait lock as a substitute for responsive layout.
- Add adaptive max widths for forms and menus.
- Replace fixed heights in game/profile/shop/lobby where content can scale.
- Use `LayoutBuilder`, `Sliver` layouts, `Wrap`, `Flexible`, `Expanded`, `AspectRatio`, and scroll-safe keyboard behavior.
- Test representative viewport classes:
  - 360x640 small phone.
  - 412x915 large phone.
  - 768x1024 tablet.
  - 1024x600 Chromebook/foldable landscape.
  - 1366x768 desktop/web.

## Before vs After Log

This section will be updated as refactors are implemented.

### Baseline

Before:

- App boot uses `MaterialApp(home: ...)` while `GoRouter` exists separately.
- Firebase dependencies are accessed directly through global singletons.
- Several services swallow errors or print debug-only messages.
- Notification token value is logged.
- Duplicate notification service exists.

After:

- Added typed application error categories for auth, Firebase, network, permission, parsing, validation, platform, and unknown failures.
- Added a central logger that sanitizes contextual values before printing.
- Added Firebase dependency providers for Auth, Firestore, Messaging, and Analytics.
- `AuthService` now receives Auth, Firestore, and Messaging from Riverpod providers instead of constructing singletons internally.
- `NotificationService` now receives Messaging and Firestore from Riverpod providers instead of constructing singletons internally.
- Notification token values are no longer printed; logs only record whether a token exists.
- Shared core error/network code is safer for Flutter Web because `dart:io` is isolated behind a conditional import.
- Token refresh events remain observed after notification initialization.
- Notification list queries are capped.
- Bulk notification updates now use Firestore batched writes instead of sequential per-document writes.
- App boot now captures uncaught framework, platform, and zone errors with the central logger.
- Added `test/error_classifier_test.dart` to verify retryability and safe user messages for core error categories.

### Second hardening pass (2026-07-13 19:49)

Before:

- App boot used `MaterialApp(home: ...)`; GoRouter was defined but unused.
- A duplicate stub notification service shadowed the production one.
- Firestore rules omitted chat collections and lacked write shape validation.
- Orientation was force-locked to portrait on all platforms.
- `RoomService` constructed `FirebaseFirestore.instance` directly.
- `analyticsProvider` was referenced by the game screens but never defined,
  which broke the build (`flutter analyze` reported 5 errors).

After:

- `MaterialApp.router` is wired to `routerProvider`. Routing gates
  splash -> login -> tutorial -> main via a `refreshListenable`, and unknown
  routes fall back to `RouteNotFoundScreen`.
- Removed `lib/services/notification_service.dart` and the empty directory.
- Rewrote `firestore.rules` with chat collections and ownership/shape/length/
  membership validation, plus room join/immutability guards.
- Portrait lock now applies only to phones (`shortestSide < 600dp` on
  Android/iOS); tablets, desktop, and web stay unlocked.
- `RoomService` and `ShopService` receive Firestore through DI providers.
- Defined `analyticsProvider` (delegating to `firebaseAnalyticsProvider`) so the
  game screens build.
- Added reusable `AppLoadingView`, `AppErrorView`, `AppEmptyView`, and
  `AdaptiveContentWidth`/responsive breakpoint helpers.
- Removed a dead `if (false)` branch in the shop screen and two unnecessary
  imports.
- `flutter analyze` is now green (0 issues) and `flutter test` passes (12/12).

## Verification Log

- 2026-07-13: `flutter analyze` attempted and timed out after 120 seconds. Needs rerun after initial cleanup.
- 2026-07-13: File inventory completed for `lib`, `test`, Firebase config, and core services.
- 2026-07-13: `dart format` attempted on touched Dart files and timed out after 120 seconds.
- 2026-07-13: `dart analyze` attempted on touched Dart files and timed out after 120 seconds.
- 2026-07-13: `flutter test test/network_utils_test.dart --no-pub` attempted and timed out after 120 seconds.
- 2026-07-13: Checked for lingering `dart`/`flutter` processes after timeouts; none were reported.
- 2026-07-13 19:49: `flutter analyze` completed cleanly in ~10s: **No issues found**
  (previously 5 errors + warnings). Build breaker `analyticsProvider` fixed.
- 2026-07-13 19:49: `flutter test` completed: **All tests passed (12/12)**,
  covering achievements, error classifier, lobby, and waiting-room widgets.

## Code Review Fixes (2026-07-13 — uncommitted review, scope "fix all findings")

A `/review` pass surfaced launch blockers beyond the original audit. All were
fixed and re-verified.

- CRITICAL — Leaderboard: the screen read the entire `users` collection while
  `firestore.rules` only allows owner-read (would `PERMISSION_DENIED`), and the
  time-window filter used an un-indexed, invalid `lastPlayedAt` query. Added a
  denormalized public `leaderboard` collection with `allow read: if signedIn();
  allow write: if signedIn() && request.auth.uid == userId` plus shape
  validation; rewrote `LeaderboardService.watchRanked` to query it (valid
  `orderBy` + `where(updatedAt)` for windows); and sync entries from
  `AuthService` (all sign-in paths) and `MultiplayerGameScreen` post-game.
- CRITICAL — Secrets: added `assets/adi-registration.properties`, `*.der`,
  `*.pem`, and `build_log.txt` to `.gitignore` (credential token was untracked).
- WARNING — Orientation: `main._applyPreferredOrientations` now locks mobile to
  portrait when display size is unknown (`shortestSide <= 0`) instead of
  silently leaving phones unlocked.
- WARNING — Economy: `firestore.rules` now validate `coins`/`gems` are
  non-negative ints on user updates (still client-writable; full trust belongs
  in Cloud Functions).
- WARNING — Waiting room: memoized per-player lookups so room snapshot updates
  no longer re-issue N+1 Firestore reads.
- WARNING — Navigation: lobby → waiting and waiting → game now use
  `context.push` / `context.pushReplacement` (GoRouter) so `matchedLocation`
  and the back stack stay consistent with the router redirect gate.
- SUGGESTION — Settings "View Tutorial" no longer resets the persisted
  completion flag up front, so backing out no longer re-gates `/tutorial` on
  next launch. `TutorialScreen.onComplete` is now nullable to support replays.
- SUGGESTION — `global_chats` rule no longer trusts client `senderName`.
- Re-verified: `flutter analyze` **No issues found**, `flutter test`
  **12/12 passing**.

## Remaining Risks Before Launch

- App is not yet safe against competitive cheating.
- Rules do not yet validate all active write shapes.
- Crashlytics, Performance Monitoring, Remote Config, and App Check are not confirmed wired.
- Deep links and unknown routes are not confirmed.
- Localization is not implemented.
- Accessibility and responsive behavior are not yet verified on target viewport classes.
- Analyzer/test baseline is not yet green.

## Go / No-Go Recommendation

Current recommendation: **No-go for production launch**.

Reason: the app needs foundational reliability, routing, Firebase security, error handling, and scalability work before it should be exposed to a large public launch.
