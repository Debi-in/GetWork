# GetWork — Folder Structure Guide
_Last Updated: 2026-08-02_

Complete explanation of the project folder structure and what goes where.

---

## Top-Level Structure

```
c:\GetWork - app\
├── android/                    ← Android native project
├── assets/                     ← Images, icons, animations, fonts
├── docs/                       ← All project documentation
├── lib/                        ← Flutter/Dart source code
├── test/                       ← Unit and widget tests
├── pubspec.yaml                ← Dependencies and asset declarations
├── analysis_options.yaml       ← Linting rules
└── README.md
```

---

## `lib/` — Source Code

```
lib/
├── main.dart                   ← App entry point (initialize services here)
├── app.dart                    ← Root MaterialApp widget
├── router.dart                 ← All app routes (go_router)
│
├── core/                       ← App-wide foundational code
│   ├── constants/
│   │   ├── api_keys.dart       ← Google Maps key (PLACEHOLDER)
│   │   ├── supabase_config.dart ← Supabase URL + key (PLACEHOLDER)
│   │   ├── app_colors.dart     ← Full color palette
│   │   ├── app_sizes.dart      ← Spacing, radius, icon sizes
│   │   └── app_strings.dart    ← All text strings
│   ├── theme/
│   │   └── app_theme.dart      ← Material Design 3 theme
│   ├── services/
│   │   ├── location_service.dart    ← GPS + permissions
│   │   └── dummy_data_service.dart  ← Phase 1 test data
│   └── utils/                  ← (add helpers, extensions here)
│
├── models/                     ← Data models
│   ├── job_model.dart          ← Job + JobCategory + SalaryType
│   └── user_model.dart         ← User + UserType (worker/business)
│
├── features/                   ← Feature-first architecture
│   ├── splash/
│   │   └── splash_screen.dart  ✅ Animated logo screen
│   ├── onboarding/
│   │   └── onboarding_screen.dart  ✅ 3-page swipe onboarding
│   ├── home/
│   │   └── home_screen.dart    🔧 Sprint 2: Map + job markers
│   ├── jobs/
│   │   ├── job_detail_screen.dart   🔧 Sprint 2: Job info + apply button
│   │   ├── apply_screen.dart        🔧 Sprint 2: Application form
│   │   └── apply_success_screen.dart ✅ Success confirmation
│   ├── profile/
│   │   └── profile_screen.dart  🔧 Sprint 3: Worker profile
│   ├── business/
│   │   ├── business_dashboard_screen.dart  🔧 Sprint 3: Business home
│   │   └── post_job_screen.dart            🔧 Sprint 3: Job posting form
│   ├── notifications/
│   │   └── notifications_screen.dart  🔧 Sprint 3
│   └── settings/
│       └── settings_screen.dart       🔧 Sprint 3
│
└── widgets/                    ← Shared reusable widgets
    └── (add shared widgets here as needed)
```

---

## `assets/` — Static Files

```
assets/
├── images/     ← PNG/JPG images (onboarding illustrations, placeholders)
├── icons/      ← SVG icons (custom icons not in Material Icons)
├── animations/ ← Lottie JSON animation files
└── fonts/      ← Inter font family TTF files
                  (Inter-Regular.ttf, Inter-Medium.ttf,
                   Inter-SemiBold.ttf, Inter-Bold.ttf)
```

> ⚠️ You must download Inter font manually from https://fonts.google.com/specimen/Inter

---

## `docs/` — Documentation

```
docs/
├── AppDevelopmentMVP.md    ← Original MVP specification
├── SetupLog.md             ← What was installed and configured
├── ApiKeysGuide.md         ← How to add Google Maps, Supabase, Firebase keys
├── PackagesGuide.md        ← All packages and their purpose
└── FolderStructure.md      ← This file
```

---

## Feature Architecture Pattern

Each feature follows this pattern:

```
features/
└── feature_name/
    ├── feature_screen.dart       ← Main UI screen
    ├── feature_controller.dart   ← Business logic (Riverpod provider)
    ├── feature_state.dart        ← State class (if complex)
    └── widgets/                  ← Feature-specific widgets
        └── feature_widget.dart
```

### Example: Jobs Feature (Sprint 2)
```
features/
└── jobs/
    ├── job_detail_screen.dart
    ├── apply_screen.dart
    ├── apply_success_screen.dart
    ├── jobs_controller.dart      ← Provider: fetchJobById, applyToJob
    └── widgets/
        ├── job_card.dart
        ├── salary_chip.dart
        └── requirement_tag.dart
```

---

## Status Legend
- ✅ Complete and functional
- 🔧 Stub created, full implementation in scheduled sprint
- 📋 Not yet created
