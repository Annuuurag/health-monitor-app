# Health Monitor App PRD and Implementation Tracker

Last updated: 2026-04-21 (post entry/dashboard polish pass)
Workspace: `D:\Anurag\b.tech\final_year_project\health_monitor_app`
Platform target: Android first
Design source: Figma file `fwah5GHCMm6di3x6wocqgQ`, page `4:2`

## 1. Product Summary

This project is a Flutter mobile application for an IoT-based health monitoring system. The app connects to a wearable health device and gives a single patient a clear, mobile-first interface for:

- monitoring real-time vitals
- reviewing trends and reports
- receiving alerts and reminders
- viewing AI-assisted insights
- managing user and device information

The app is being built in phases so the project remains demo-ready and can continue smoothly across multiple Codex sessions.

## 2. Primary Objectives

- Build a usable Android Flutter application with a strong mock-data-first foundation.
- Match the provided Figma design as closely as practical.
- Keep architecture ready for later AWS, BLE, and ML integration.
- Maintain a persistent implementation record so work can resume after context resets or rate limits.

## 3. Phase Plan

### Phase 1: Demo-Ready Product

- Dashboard
- Reports
- Care
- Insights
- Profile
- Device
- Settings
- Alerts and Notifications
- Mock repositories
- Local reminders and notification plumbing
- Local profile and settings persistence
- Android-first UI matching Figma structure

### Phase 2: Integrations and Expansion

- AWS data integration
- BLE pairing and live device state
- backend-generated insights
- richer alerts
- emergency support
- caregiver or multi-user features if needed later

## 4. Confirmed Product Scope

### User model

- Single local patient
- No full auth requirement for phase 1

### Data and intelligence model

- Mock data first
- AWS-compatible repository boundaries from the beginning
- Insights available in UI now, placeholder or rule-based in phase 1
- Cloud architecture planned as:
  - `ESP32 -> AWS IoT Core -> Lambda -> DynamoDB -> Flutter app`

### Notifications

- Local notifications for phase 1
- Push notifications deferred

### Reports

- In-app daily and weekly summaries
- No PDF export in phase 1

## 5. Figma Reference Summary

The shared Figma file already contains the major product flows and design language.

### Sections seen in the file

- Onboarding
- Sign up / Sign in
- Device Pairing
- Main app pages

### Main app pages visible from the design canvas

- Dashboard
- Reports
- Care
- Insights
- Profile
- User profile
- Device
- Settings
- Alerts and Notifications

### Visual system observed

- Dark and light variants both exist
- Teal top app bar
- Rounded cards with soft corners
- Cream-colored bottom navigation background
- 5-tab bottom navigation:
  - Dashboard
  - Reports
  - Care
  - Insights
  - Profile
- Typography appears to use `Inder`

### Figma nodes already inspected

- Full page canvas: `4:2`
- Dashboard dark screen: `2108:2502`

### Important note

Some screen-level Figma calls timed out during extraction. The dashboard screen is the most concretely extracted screen so far. The full-canvas screenshot still gives us enough visual truth to continue implementing the overall flow.

## 6. Architecture Direction

The app should be organized into:

- `lib/app`
- `lib/domain`
- `lib/data`
- `lib/presentation`
- `lib/services`

### Core entities planned

- `TelemetrySample`
- `HealthSnapshot`
- `AlertEvent`
- `InsightResult`
- `MedicationReminder`
- `UserProfile`
- `DeviceProfile`
- `ReportSummary`
- `AppSettings`

### Repository interfaces planned

- `TelemetryRepository`
- `ReportsRepository`
- `InsightsRepository`
- `AlertsRepository`
- `RemindersRepository`
- `ProfileRepository`
- `DeviceRepository`

## 7. Current Progress Status

### Completed

- Flutter project created
- Figma file received and inspected
- Main app flow confirmed from design
- Dashboard visual structure confirmed from Figma
- PRD/tracker created and added to `docs`
- App bootstrap updated in `lib/main.dart`
- Dependencies added for notifications, timezone support, and local persistence
- Domain model layer completed:
  - `AlertEvent`
  - `AppSettings`
  - `DeviceProfile`
  - `HealthSnapshot`
  - `InsightResult`
  - `MedicationReminder`
  - `ReportSummary`
  - `TelemetrySample`
  - `UserProfile`
- Repository interface layer completed
- Mock seed data and mock repositories completed
- App controller and state flow completed:
  - `lib/app/state/app_controller.dart`
- Local persistence abstraction completed:
  - `lib/data/local/local_storage.dart`
- Local notification service abstraction completed:
  - `lib/services/notification_service.dart`
- Shared UI foundation completed:
  - theme
  - app colors
  - bottom navigation
  - reusable screen scaffold
  - reusable metric card
- Phase-1 screen pass completed:
  - `Dashboard`
  - `Reports`
  - `Care`
  - `Insights`
  - `Profile`
  - `User profile`
  - `Device`
  - `Settings`
  - `Alerts & Notifications`
- Entry flow pass completed:
  - `Onboarding`
  - `Sign in / Sign up`
  - `Device Pairing`
  - app root entry gating based on persisted state
  - logout path back into auth flow
- Android notification manifest updated for local notifications
- Code formatting completed with `dart format`
- Validation completed:
  - `flutter analyze` passed
  - `flutter test` passed
- Profile-side polish pass completed:
  - `Profile` layout refined
  - `User profile` layout refined
  - `Device` layout refined
  - `Settings` layout refined
- Entry/dashboard polish pass completed:
  - `Auth` now includes a Figma-style welcome entry plus separate sign-in/sign-up states
  - `Onboarding` hero card and controls refined toward the Figma layout
  - `Device Pairing` split into a more design-faithful choose-method and choose-device flow
  - `Dashboard` summary and alerts card refined
  - `Reports` and `Care` layouts refined
  - validation re-run after polish:
    - `flutter analyze` passed
    - `flutter test` passed

### In progress

- Improving visual fidelity against Figma beyond the current functional pass

### Not started yet

- Light/dark design parity refinement for every screen
- Manual Figma-by-Figma screen matching pass
- AWS integration
- BLE integration

## 8. Implementation Order

### Milestone 1: Foundation

Status: Completed

- Finish domain models
- Add repository interfaces
- Add local storage and notification abstractions
- Add app controller and state flow
- Add mock data providers

### Milestone 2: Design System and Navigation

Status: Completed (first pass)

- Set app theme from Figma direction
- Build shared scaffolding and bottom navigation
- Build reusable cards, metric tiles, section headers, status chips

### Milestone 3: Dashboard

Status: Completed (functional first pass)

- Implement dashboard first from the extracted Figma screen
- Match top bar, summary card, vital cards, alerts card, and bottom nav

### Milestone 4: Remaining Pages

Status: Completed (functional first pass)

- Reports
- Care
- Insights
- Profile
- User profile
- Device
- Settings
- Alerts and Notifications

### Milestone 5: Validation

Status: Completed

- Run `flutter pub get`
- Run `flutter analyze`
- Run widget tests
- Fix layout or lint issues

## 9. Task Checklist

Use this section as the running progress tracker.

### Setup and architecture

- [x] Create Flutter project
- [x] Receive Figma file
- [x] Inspect Figma canvas and dashboard screen
- [x] Create PRD/tracker document
- [x] Finish all domain models
- [x] Add repository interfaces
- [x] Add mock repositories
- [x] Add app state/controller layer

### UI and navigation

- [x] Build shared app scaffold
- [x] Build bottom navigation to match Figma
- [x] Build shared cards and status components
- [x] Implement Dashboard
- [x] Implement Reports
- [x] Implement Care
- [x] Implement Insights
- [x] Implement Profile
- [x] Implement User Profile
- [x] Implement Device
- [x] Implement Settings
- [x] Implement Alerts and Notifications
- [x] Implement Onboarding
- [x] Implement Sign in / Sign up
- [x] Implement Device Pairing
- [x] Implement dynamic user-configurable reminders in Care screen
- [x] Add Add/Edit Reminder dialog
- [ ] Refine visual fidelity to Figma across all screens

### Platform and persistence

- [x] Persist settings with `SharedPreferences`
- [x] Persist profile and reminders
- [x] Configure Android notification permission and reminder flow

### Verification

- [x] `flutter pub get`
- [x] `flutter analyze`
- [x] `flutter test`
- [ ] Manual visual comparison against Figma

## 10. Decisions Log

### 2026-04-12

- Chosen framework: Flutter
- Target platform: Android first
- Product mode: single local patient
- Backend direction: simple AWS later, mock data first now
- Notifications: local notifications in phase 1
- Reports: in-app summaries only in phase 1
- Insights: placeholder or rule-based in phase 1
- Figma should drive the UI instead of building generic screens
- Dashboard should be the first major screen implemented because it has the strongest extracted design context
- First build pass should prioritize a working vertical slice over perfect pixel parity
- The current state is a functional mock-data-first phase-1 build with validation already passing
- The next pass should focus on design fidelity and the pre-auth / pairing flows missing from the current codebase

### 2026-04-21

- The app now starts with a persisted first-launch flow:
  - onboarding
  - auth
  - device pairing
  - main app shell
- `AppSettings` now stores onboarding, sign-in, and pairing completion flags
- Validation re-run after the entry flow pass:
  - `flutter analyze` passed
  - `flutter test` passed
- The next major work should shift from missing flows to Figma fidelity and visual refinement
- A first polish pass has now been applied to the profile-side screens while keeping validation green
- A second polish pass has now been applied to onboarding/auth/device pairing plus dashboard/reports/care while keeping validation green

### 2026-04-30

- Changed medication reminders from fixed/hardcoded times to a dynamic, user-configurable alarm system. This fixes timezone localization issues and improves the user experience.


## 11. Session Resume Instructions

If a future Codex session needs to continue the work, use this checklist:

1. Open this file first:
   - [HEALTH_MONITOR_PRD.md](/D:/Anurag/b.tech/final_year_project/health_monitor_app/docs/HEALTH_MONITOR_PRD.md)
2. Review current implementation files in:
   - [lib](/D:/Anurag/b.tech/final_year_project/health_monitor_app/lib)
3. Confirm the current Figma reference:
   - file key: `fwah5GHCMm6di3x6wocqgQ`
   - main canvas node: `4:2`
   - dashboard node: `2108:2502`
4. Resume from the first unchecked item in `Task Checklist`
5. Update both `Current Progress Status` and `Decisions Log` after each meaningful milestone

## 12. Immediate Next Step

The next implementation step should be:

- Do a visual refinement pass on the existing screens so spacing, colors, cards, and typography match Figma more closely
- improve light and dark parity across the full app flow
- manually compare implemented screens against the Figma file section-by-section and tighten any remaining mismatches
- after that, re-run:
  - `flutter analyze`
  - `flutter test`
