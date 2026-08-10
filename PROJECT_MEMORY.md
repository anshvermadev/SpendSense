---

# PROJECT MEMORY — SpendSense

> Last updated: 2026-07-20
> Stack: Flutter · Dart · Provider · GoRouter · SharedPreferences · Telephony

---

## 🧭 What This Project Is
SpendSense is a privacy-first, local-only personal finance application that automatically tracks expenses and income by reading the user's incoming SMS messages from banks and UPI. It operates entirely on-device without cloud syncing or bank API connections, ensuring financial data security while offering budgeting tools and interactive dashboards.

---

## 🏗️ App Architecture
- **`lib/services/`**: Core business logic and integrations. 
  - `DatabaseService` owns local storage operations via `SharedPreferences`.
  - `SmsService` configures background and foreground SMS listening.
  - `CategorizationService` extracts merchant and amount data from raw SMS bodies using regex.
  - `AppState` (managed via `provider`) bridges the services and the UI, triggering rebuilds when the database updates.
- **`lib/presentation/`**: Screen layouts grouped by feature (`home_screen`, `dashboard_screen`, `history_screen`, `profile_screen`, `onboarding_screen`). Local components live in nested `widgets/` directories.
- **`lib/widgets/`**: Reusable generic components (e.g. `CustomErrorWidget`, `CustomIconWidget`).
- **`lib/core/` & `lib/routes/` & `lib/theme/`**: Constants, `go_router` configuration, and theming setup.
- **Data Flow**: Incoming SMS → Android Broadcast Receiver → `telephony` plugin → `SmsService.backgroundMessageHandler` → `CategorizationService.parseSms` → `DatabaseService.addTransaction` → `AppState.refresh()` (on resume) → UI rebuilds via `provider`.
- **Third-Party Integrations**:
  - `telephony`: Owns the Android SMS broadcast receiver and permission requesting.
  - `shared_preferences`: Owns local disk persistence.
  - `fl_chart`: Owns data visualization on the dashboard.
- **Auth Model**: None (100% local and offline).
- **Deployment Target**: Android (primary due to SMS reading constraints).

---

## 🔄 Main User Flow
1. **Onboarding**: User launches app. `OnboardingScreen` shows value props, requests SMS permissions (`onboarding_permission_widget.dart`), and asks for basic setup details (`onboarding_setup_widget.dart`).
2. **Permissions (Crucial Branch)**: If the user denies SMS permission, the app operates in manual-entry mode. If granted, `SmsService` binds foreground/background listeners.
3. **Passive Collection**: User transacts in real life. Android routes the bank SMS to `telephony.dart`, which wakes up `SmsService.backgroundMessageHandler` to parse and persist the transaction silently.
4. **App Resumption**: User opens SpendSense. `MyApp` (via `WidgetsBindingObserver` in `main.dart`) detects `AppLifecycleState.resumed` and triggers `AppState().refresh()`.
5. **Insights / Exit**: User views the `DashboardScreen` for category breakdowns or the `HistoryScreen` for raw logs.

---

## ✅ What's Been Done / Changes Log
- [DONE] Initialized Flutter project and configured app routing/theming — `pubspec.yaml`, `main.dart`, `app_routes.dart`
- [DONE] Implemented Regex-based SMS parsing engine — `categorization_service.dart`
- [DONE] Implemented background isolate processing for SMS intercepts — `sms_service.dart`
- [DONE] Added UI State lifecycle bindings to support background-to-foreground sync — `main.dart`
- [DONE] Modified Android Gradle setup to fix namespace evaluation errors in older plugins — `android/build.gradle.kts`
- [DONE] Updated Android Manifest to register background SMS receiver — `android/app/src/main/AndroidManifest.xml`

---

## 🐛 Issues Fixed
- [FIXED] App crashing on startup due to unannotated background channel in telephony package — Root cause: Missing `@pragma('vm:entry-point')` — `pub-cache/.../telephony.dart`
- [FIXED] SMS transactions not parsing correctly due to extra words in SMS body (e.g., "debited for Rs") — Root cause: Regex rules were too strict — `categorization_service.dart`
- [FIXED] App UI failing to update when resuming after an SMS was caught in the background — Root cause: Background isolates do not trigger UI state rebuilds — `main.dart`, `app_state.dart`, `database_service.dart`
- [FIXED] UI throwing "Unsupported operation: Cannot modify an unmodifiable list" on resume — Root cause: Sorting an unmodifiable list in place — `database_service.dart:L258`
- [FIXED] Foreground SMS listener failing to attach silently — Root cause: Redundant permission request in start logic — `sms_service.dart:L64`
- [FIXED] Bottom sheets popping up underneath floating navigation bar — Root cause: Default `showModalBottomSheet` behavior pushing to nested router. Fixed via `useRootNavigator: true`.
- [FIXED] Floating navigation bar overlaying scrollable content and FABs — Root cause: `Scaffold` with `extendBody: true` does not push inner content. Fixed by adding explicit large bottom padding to scroll views and FABs.
- [FIXED] App crashing on Hot Reload (Something went wrong) — Root cause: Added new non-nullable properties (`accountNo`, `bankRefNo`) to `Transaction` which caused memory exceptions for old uninitialized instances. Handled with explicit dynamic null-checks.
- [FIXED] SMS Parser mistakenly grabbing "Rs 30.00" as Merchant and missing UPI IDs — Root cause: Overly greedy `for` branch in `_merchantPattern` and missing `UPI:` in `_refNoPattern`. Fixed by adding lookaheads and fallback regexes for specific banking formats.
- [FIXED] UI not updating when background SMS arrives — Root cause: `SharedPreferences` memory cache in the main isolate was not syncing with background isolate disk writes. Fixed by invoking `await prefs.reload()` during `AppLifecycleState.resumed`.
- [FIXED] History Screen transaction list viewport too small on smaller devices — Root cause: Month/Week calendar grids were fixed siblings of the list. Fixed by unifying the screen inside a `CustomScrollView` using `SliverToBoxAdapter` and `SliverList`.
- [FIXED] Week tab incorrectly excluding transactions due to timezone/time-of-day offsets — Root cause: Mathematical `isAfter` and `isBefore` evaluations. Fixed by implementing strict integer year/month/day comparison.
- [FIXED] Calendar state (selected day/week/month) persisting confusingly after switching tabs — Root cause: State variables were preserving past navigation. Fixed by resetting calendar states to `DateTime.now()` exclusively on `TabBar.onTap`.

## ⚠️ Known Issues / Open TODOs
- [OPEN] Replace mock/in-memory state management with Riverpod/Bloc for production — `dashboard_screen.dart`, `onboarding_permission_widget.dart`
- [OPEN] The `telephony` package relies on a local pub-cache patch to run on modern Dart VMs — `pub-cache/.../telephony.dart`

---

## 🚀 What Can Be Added Next
- [ARCH/FUTURE] Migrate Background SMS Tracking: Move away from the Dart-based `telephony` background isolate which is prone to OS kills and slow loading times. Implement **Option 3 (Stealth Native Receiver + Scheduled WorkManager Sync)** as outlined in `BACKGROUND_SMS_ARCH_OPTIONS.md` to prepare for future on-device ML classification.
- [ARCH/FUTURE] Graceful App-Open Fallback: If scheduled syncs fail, present a UI warning banner to the user (e.g., "12 unsynced expenses found! [Sync Now]") to give them control over the ML processing rather than freezing the app.
- [FEATURE] Budget Alerts: Local push notifications when a user exceeds a category budget limit.
- [FEATURE] Daily/Weekly Spending Summary Notifications: A scheduled local notification summarizing recent spend.
- [FEATURE] Scheduled Sync Notifications: Local notifications (e.g., "Sync Complete: 5 new transactions") triggered by WorkManager after a successful background sync.
- [FEATURE] Custom Regex Builder: A UI screen allowing users to define their own bank SMS formats if the default categorization engine fails to match.
- [IMPROVEMENT] Migrate away from the discontinued `telephony` package to `flutter_sms_inbox` or a custom platform channel to avoid pub-cache patching requirements.
- [IMPROVEMENT] Implement SQLite (via `sqflite`) instead of `shared_preferences` to support complex relational queries and improve parsing performance at scale.
- [IMPROVEMENT] Add unit tests for `CategorizationService`'s regex parsing to prevent regressions when adding new bank formats.

---

## 🔑 Key Files Quick Reference
| File / Folder | Purpose |
|---|---|
| `lib/main.dart` | Entry point. Configures `WidgetsBindingObserver` for background sync and injects `AppState`. |
| `lib/services/sms_service.dart` | Configures foreground/background listeners for the `telephony` package. |
| `lib/services/categorization_service.dart` | Regex engine that maps raw SMS text to structured `Transaction` models. |
| `lib/services/database_service.dart` | Core local data persistence engine wrapped around `SharedPreferences`. |
| `lib/services/app_state.dart` | The global Provider state bridging DB services with UI consumers. |
| `android/app/src/main/AndroidManifest.xml` | Configures the `IncomingSmsReceiver` required for background SMS interceptions. |

---

## 🧠 Context for AI / Debug Sessions
> "This is SpendSense. Stack: Flutter · Dart · Provider · SharedPreferences. The main user flow is: Passive tracking of bank SMS messages into local storage to provide personal finance insights without bank APIs. Current focus: Stabilizing background SMS processing and UI synchronization. Known issues: The telephony package requires a local patch to prevent Dart VM crashes, and state management currently relies on simple Provider implementations."
