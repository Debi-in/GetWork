# GetWork — Architecture, Tech Stack & Phased Roadmap 🇳🇵
_Document Version: 1.0 | Last Updated: 2026-08-02_

This document outlines the architecture, technology stack selection rationale, anti-patterns to avoid, feature-first structure, and phased growth roadmap for GetWork.

---

## 🏗️ 1. MVP Technology Stack (Option A — Recommended for First 10,000 Users)

| Layer | Technology | Rationale |
|-------|------------|-----------|
| **Mobile App** | Flutter (Material Design 3) | Single codebase for high-performance Android & iOS apps |
| **Backend** | Supabase | Instant Auth, PostgreSQL database, Storage, and Realtime APIs |
| **Database** | PostgreSQL (Supabase) | Relational integrity, spatial queries, highly scalable |
| **Maps** | OpenStreetMap (`flutter_map`) & Google Maps | OpenSource / free tile option + Google Maps fallback |
| **Notifications** | Firebase Cloud Messaging (FCM) | Free, reliable push notifications across mobile platforms |
| **State Management** | Riverpod 3 | Clean, robust, type-safe reactive state management |
| **Routing** | GoRouter | Declarative URL-friendly modern navigation |
| **Image Storage** | Supabase Storage | Built-in file bucket storage for profiles and job photos |
| **Source Control** | GitHub | Industry standard version control |
| **Hosting** | Vercel | Instant, free static hosting for web previews & landing page |
| **Analytics** | Firebase Analytics | Track user engagement and conversion funnels |
| **Crash Reporting** | Firebase Crashlytics | Automated crash capture and diagnostic trace logs |

---

## 🚀 2. Production Ready Stack (Option B — Growth Phase)

When the app scales beyond 10,000 active users:
- **Core App**: Flutter + Supabase (PostgreSQL) + OpenStreetMap + Riverpod + GoRouter
- **Observability**: Firebase Analytics + Firebase Crashlytics
- **CI/CD**: GitHub Actions for automated builds & unit test suites
- **CDN & Security**: Cloudflare (DDoS protection, fast edge caching)
- **Containerization**: Docker (for custom backend microservices if needed)

---

## 🚫 3. Technologies Excluded for MVP

To maintain maximum velocity and avoid premature optimization, the following are **explicitly excluded**:

- ❌ **Firebase Firestore**: Supabase PostgreSQL is the primary database.
- ❌ **MongoDB**: Relational SQL fits job listings and user applications better.
- ❌ **AWS / GCP Cloud Infra**: Unnecessary infrastructure complexity for MVP.
- ❌ **Kubernetes / Microservices**: Monolithic Supabase backend is faster to build.
- ❌ **Redis**: In-memory caching isn't required until massive traffic hits.

---

## 🔑 4. Authentication Architecture

Instead of custom passwords or complex auth flows, authentication follows a streamlined path:

```
Google Login / Phone OTP
         ↓
  Supabase Auth
         ↓
 User Profile (PostgreSQL)
```

This keeps auth simple while allowing Supabase to manage secure sessions, JWTs, and Row Level Security (RLS) policies.

---

## 📁 5. Feature-First Directory Architecture

The codebase is organized by feature rather than file type to ensure high maintainability and modularity:

```
lib/
│
├── core/
│   ├── theme/          ← Material 3 themes & color tokens
│   ├── services/       ← GPS location, HTTP, Supabase clients
│   ├── constants/      ← App colors, strings, sizes, API keys
│   └── widgets/        ← Shared reusable UI components
│
├── features/
│   ├── authentication/ ← Login, Google Sign-In, Phone OTP
│   ├── map/            ← Map view, salary markers, location picker
│   ├── jobs/           ← Job details, bottom sheet, application flow
│   ├── business/       ← Business dashboard, post job form, applicant management
│   ├── profile/        ← Worker profile, completed jobs, skills
│   ├── notifications/  ← Notification center
│   ├── search/         ← Search & category filtering
│   └── settings/       ← Theme, language, privacy policy
│
├── models/             ← Data classes (JobModel, UserModel, ApplicationModel)
├── providers/          ← Global Riverpod providers
└── main.dart           ← Entry point & service initializations
```

---

## 🗓️ 6. Phased Growth Roadmap

### Phase 1: MVP (Current)
- ✅ Flutter + Riverpod 3 + GoRouter
- ✅ Interactive Map & Floating Salary Markers
- ✅ Job Detail & Direct Application Flow
- ✅ Supabase Database & Vercel Web Deployment Setup
- ✅ GitHub Repository Setup
- ⏳ OpenStreetMap (`flutter_map`) integration option
- ⏳ Firebase Cloud Messaging (FCM) setup

### Phase 2: User Growth (1,000+ Users)
- 🔑 Google Sign-In & Phone OTP Auth
- 📊 Firebase Analytics & Crashlytics
- ⚙️ GitHub Actions CI/CD Pipeline
- 🇳🇵 Dual Language Support (English / Nepali)

### Phase 3: Scale (10,000+ Users)
- 🤖 AI-powered job matching recommendations
- 💬 Real-time in-app worker-employer chat
- 💳 Integrated in-app wallet / payment gateway (eSewa / Khalti)
- 📊 Business Analytics Dashboard
- 🖥️ Full Web Admin Management Portal

---

## 🌟 Overall MVP Rating

The GetWork stack scores **9.5 / 10** for an MVP:
- **Riverpod** for state management
- **GoRouter** for navigation
- **Supabase** for backend & PostgreSQL
- **Vercel** for web hosting
- **Firebase Analytics & Crashlytics** for production stability
