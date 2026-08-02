# GetWork — Folder Structure Guide
_Last Updated: 2026-08-02_

Complete explanation of the GetWork feature-first folder structure.

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
├── vercel.json                 ← Vercel deployment configuration
├── analysis_options.yaml       ← Linting rules
└── README.md
```

---

## `lib/` — Feature-First Architecture

```
lib/
├── main.dart                   ← App entry point
├── app.dart                    ← Root MaterialApp widget
├── router.dart                 ← All app routes (go_router)
│
├── core/                       ← App-wide foundational code
│   ├── constants/
│   │   ├── api_keys.dart       ← Google Maps key
│   │   ├── supabase_config.dart ← Supabase URL + key
│   │   ├── app_colors.dart     ← Full color palette
│   │   ├── app_sizes.dart      ← Spacing, radius, icon sizes
│   │   └── app_strings.dart    ← All text strings
│   ├── theme/
│   │   └── app_theme.dart      ← Material Design 3 theme
│   ├── services/
│   │   ├── location_service.dart    ← GPS + permissions
│   │   └── dummy_data_service.dart  ← Local test data
│   └── widgets/                ← Shared reusable UI components
│
├── features/                   ← Feature-first architecture
│   ├── authentication/         ← Login, Google Sign-In, Phone OTP
│   ├── map/                    ← Interactive Map, markers, location search
│   ├── jobs/                   ← Job details, bottom sheet, application flow
│   ├── business/               ← Business dashboard, post job form
│   ├── profile/                ← Worker profile, completed jobs, skills
│   ├── notifications/          ← Notification center
│   ├── search/                 ← Job search & category filtering
│   └── settings/               ← Theme, language, privacy settings
│
├── models/                     ← Data models (JobModel, UserModel, ApplicationModel)
└── providers/                  ← Global Riverpod state providers
```

---

## `docs/` — Project Documentation

```
docs/
├── ArchitectureAndStack.md ← Tech stack rationale, Option A/B, auth, phased roadmap
├── AppDevelopmentMVP.md    ← Original MVP specification
├── SupabaseSchema.sql      ← Complete PostgreSQL DDL script & seed data
├── SetupLog.md             ← Environment installation & configuration log
├── ApiKeysGuide.md         ← Key setup guide for Maps, Supabase & Firebase
├── PackagesGuide.md        ← All Flutter dependencies reference
└── FolderStructure.md      ← This document
```
