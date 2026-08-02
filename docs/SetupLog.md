# GetWork — Setup Log
_Last Updated: 2026-08-02_

This document records everything that was installed, fixed, and configured for the GetWork Flutter app development environment.

---

## ✅ Environment Setup

### Flutter & Dart
| Item | Version | Status |
|------|---------|--------|
| Flutter SDK | 3.44.8 (stable) | ✅ Installed |
| Dart SDK | 3.12.2 | ✅ Installed |
| DevTools | 2.57.0 | ✅ Installed |
| Flutter location | `C:\flutter` | ✅ |

### Android
| Item | Details | Status |
|------|---------|--------|
| Android SDK | v34.0.0 at `C:\PCSX2\ether\sdk` | ✅ |
| Android SDK Platform | android-36 | ✅ |
| Build Tools | 34.0.0 | ✅ |
| Android Licenses | Accepted (2 of 7 were missing) | ✅ Fixed |
| Java | JDK 17.0.12 | ✅ |

### Known Issues (Non-blocking)
| Issue | Impact | Fix |
|-------|--------|-----|
| Visual Studio missing C++ components | Cannot build Windows desktop app | Not needed for Android MVP |
| `googlecloudtools.datacloud` extension error | IDE warning only | Not related to Flutter dev |

---

## ✅ Project Created

| Item | Value |
|------|-------|
| Project name | `getwork` |
| Organization | `com.getwork` |
| Package name | `com.getwork.getwork` |
| Platform | Android (MVP) |
| Min SDK | API 24 (Android 7.0) |
| Target SDK | API 36 (Android 15+) |
| Location | `c:\GetWork - app\` |

---

## ✅ Files Created

### Core Config
- `lib/core/constants/api_keys.dart` — Google Maps key placeholder
- `lib/core/constants/supabase_config.dart` — Supabase URL + key placeholder
- `lib/core/constants/app_colors.dart` — Full color palette
- `lib/core/constants/app_sizes.dart` — Spacing and sizing constants
- `lib/core/constants/app_strings.dart` — All app strings

### Theme
- `lib/core/theme/app_theme.dart` — Full Material Design 3 theme

### Services
- `lib/core/services/location_service.dart` — GPS + permission handling
- `lib/core/services/dummy_data_service.dart` — Phase 1 test data (6 Kathmandu jobs)

### Models
- `lib/models/job_model.dart` — Job data model
- `lib/models/user_model.dart` — User/Business data model with dummy data

### Navigation
- `lib/router.dart` — go_router with all routes defined
- `lib/app.dart` — Root app widget
- `lib/main.dart` — Entry point with Phase 2/3 stubs commented

### Feature Screens (Stubs — to be built per sprint)
- `lib/features/splash/splash_screen.dart` ✅ Animated
- `lib/features/onboarding/onboarding_screen.dart` ✅ 3-page swipe
- `lib/features/home/home_screen.dart` — Sprint 2: Map
- `lib/features/jobs/job_detail_screen.dart` — Sprint 2
- `lib/features/jobs/apply_screen.dart` — Sprint 2
- `lib/features/jobs/apply_success_screen.dart` ✅ Done
- `lib/features/profile/profile_screen.dart` — Sprint 3
- `lib/features/business/business_dashboard_screen.dart` — Sprint 3
- `lib/features/business/post_job_screen.dart` — Sprint 3
- `lib/features/notifications/notifications_screen.dart` — Sprint 3
- `lib/features/settings/settings_screen.dart` — Sprint 3

### Android
- `android/app/src/main/AndroidManifest.xml` — Updated with Maps key, all permissions

### Assets
- `assets/images/` — For local images
- `assets/icons/` — SVG icons
- `assets/animations/` — Lottie JSON files
- `assets/fonts/` — Inter font family (need to download, see below)

---

## ⬇️ Still Needed (Manual Actions)

### 1. Download Inter Font
Download from https://fonts.google.com/specimen/Inter
Place these files in `assets/fonts/`:
- `Inter-Regular.ttf`
- `Inter-Medium.ttf`
- `Inter-SemiBold.ttf`
- `Inter-Bold.ttf`

### 2. Google Maps API Key
See `docs/ApiKeysGuide.md` for full steps.

### 3. Supabase Credentials
See `docs/ApiKeysGuide.md` for full steps. Required for Phase 2.

### 4. Firebase Config
See `docs/ApiKeysGuide.md` for full steps. Required for Phase 3.

---

## ✅ MCP Tools Available

| Tool | Use During Development |
|------|----------------------|
| `pub` | `flutter pub get/add/upgrade` |
| `hot_reload` | Live code changes without restart |
| `hot_restart` | Full app restart |
| `analyze_files` | Static analysis / lint checks |
| `widget_inspector` | Debug widget tree visually |
| `get_runtime_errors` | Catch crashes |
| `pub_dev_search` | Find new packages |
| `lsp` | Code intelligence |
| `flutter_driver_command` | Integration tests |
