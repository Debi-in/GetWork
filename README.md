# GetWork — Map-First Local Hiring Platform 🇳🇵

GetWork is a map-first local hiring platform designed for Nepal that allows workers to discover nearby part-time and temporary jobs while enabling local businesses to hire trusted workers quickly.

---

## 🛠️ Tech Stack & Architecture (Option A MVP Stack)

- **Frontend**: Flutter (Material Design 3)
- **State Management**: Riverpod 3 (`Notifier` / `NotifierProvider`)
- **Navigation**: `go_router` (Declarative Routing with SPA support)
- **Maps & GPS**: OpenStreetMap (`flutter_map`) & Google Maps (`google_maps_flutter`)
- **Backend & Database**: Supabase (PostgreSQL + RLS + Storage)
- **Notifications**: Firebase Cloud Messaging (FCM)
- **Hosting**: Vercel (Flutter Web SPA)
- **Source Control**: GitHub

👉 See [Architecture & Stack Guide](file:///c:/GetWork%20-%20app/docs/ArchitectureAndStack.md) for complete rationale, excluded tools, and phased roadmap.

---

## 📁 Feature-First Architecture

```
lib/
├── core/         ← Theme, constants, shared services & widgets
├── features/     ← Modular features (map, jobs, business, profile, auth, settings)
├── models/       ← JobModel, UserModel, ApplicationModel
└── providers/    ← Global Riverpod providers
```

---

## 🚀 Quick Start (Local Run)

### Prerequisites
- Flutter SDK (v3.44.8 or higher)
- Google Chrome browser (for web preview)

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run on Web
```bash
flutter run -d chrome --web-port=8080
```

### 3. Run on Android Emulator/Device
```bash
flutter run -d android
```

---

## 🐙 Connecting GitHub Repository

```bash
git remote add origin https://github.com/YOUR_USERNAME/getwork.git
git branch -M main
git push -u origin main
```

---

## 🌐 Deploying on Vercel

Build settings for Vercel Dashboard:
- **Build Command**: `if [ -d "flutter" ]; then cd flutter && git pull; else git clone https://github.com/flutter/flutter.git -b stable --depth 1; fi && ./flutter/bin/flutter build web --release`
- **Output Directory**: `build/web`

---

## 🗄️ Supabase Database Setup

1. Copy SQL from [`docs/SupabaseSchema.sql`](file:///c:/GetWork%20-%20app/docs/SupabaseSchema.sql).
2. Paste into **Supabase SQL Editor** and click **Run**.
3. Copy credentials into `lib/core/constants/supabase_config.dart`.

---

## 📚 Documentation Reference

- 🏗️ [Architecture & Stack](file:///c:/GetWork%20-%20app/docs/ArchitectureAndStack.md)
- 🗄️ [Supabase SQL Schema](file:///c:/GetWork%20-%20app/docs/SupabaseSchema.sql)
- 📁 [Folder Structure Guide](file:///c:/GetWork%20-%20app/docs/FolderStructure.md)
- 🔑 [API Keys Guide](file:///c:/GetWork%20-%20app/docs/ApiKeysGuide.md)
- 📦 [Packages Guide](file:///c:/GetWork%20-%20app/docs/PackagesGuide.md)
- 📜 [Setup Log](file:///c:/GetWork%20-%20app/docs/SetupLog.md)
