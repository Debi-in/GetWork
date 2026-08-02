# GetWork — Map-First Local Hiring Platform 🇳🇵

GetWork is a map-first local hiring platform designed for Nepal that allows workers to discover nearby part-time and temporary jobs while enabling local businesses to hire trusted workers quickly.

---

## 🛠️ Tech Stack & Architecture

- **Frontend**: Flutter (Material Design 3)
- **State Management**: Riverpod 3 (`Notifier` / `NotifierProvider`)
- **Navigation**: `go_router` (Declarative Routing with SPA support)
- **Maps & GPS**: `google_maps_flutter`, `geolocator`
- **Hosting**: Vercel (Flutter Web SPA)
- **Backend & Database**: Supabase (PostgreSQL + RLS + Realtime)
- **Target Platform**: Android (API 24+) & Web

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

To connect this local repository to your GitHub account:

```bash
# 1. Create a new repository on GitHub (e.g. named "getwork")
# 2. Link your local project to GitHub:
git remote add origin https://github.com/YOUR_USERNAME/getwork.git

# 3. Rename branch to main and push initial commit:
git branch -M main
git push -u origin main
```

---

## 🌐 Deploying on Vercel

The project includes `vercel.json` pre-configured for SPA routing.

### Automatic Deployment via GitHub & Vercel Dashboard:
1. Push your code to GitHub as shown above.
2. Go to [Vercel Dashboard](https://vercel.com/dashboard) → Click **Add New...** → **Project**.
3. Import your `getwork` repository.
4. Set Build Settings:
   - **Framework Preset**: Other
   - **Build Command**: `if [ -d "flutter" ]; then cd flutter && git pull; else git clone https://github.com/flutter/flutter.git -b stable --depth 1; fi && ./flutter/bin/flutter build web --release`
   - **Output Directory**: `build/web`
5. Click **Deploy**!

---

## 🗄️ Supabase Database Setup

1. Log into your [Supabase Dashboard](https://supabase.com).
2. Open **SQL Editor** → Click **New Query**.
3. Copy all SQL from [`docs/SupabaseSchema.sql`](file:///c:/GetWork%20-%20app/docs/SupabaseSchema.sql) and paste it into the editor.
4. Click **Run** to generate tables, indexes, policies, and seed data.
5. Copy your Project URL & Anon Key into `lib/core/constants/supabase_config.dart`.

---

## 📚 Documentation Reference

- 📜 [Setup Log](file:///c:/GetWork%20-%20app/docs/SetupLog.md)
- 🔑 [API Keys Guide](file:///c:/GetWork%20-%20app/docs/ApiKeysGuide.md)
- 📦 [Packages Guide](file:///c:/GetWork%20-%20app/docs/PackagesGuide.md)
- 📁 [Folder Structure Guide](file:///c:/GetWork%20-%20app/docs/FolderStructure.md)
- 🗄️ [Supabase SQL Schema](file:///c:/GetWork%20-%20app/docs/SupabaseSchema.sql)
