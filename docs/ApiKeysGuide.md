# GetWork — API Keys Guide
_Last Updated: 2026-08-02_

This guide explains exactly where and how to add each API key when you're ready.

---

## 1. 🗺️ Google Maps API Key

### When to add: Before Sprint 2 (Map screen)

### Steps:
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing
3. Go to **APIs & Services → Library**
4. Enable **Maps SDK for Android**
5. Go to **APIs & Services → Credentials → Create Credentials → API Key**
6. Copy your API key

### Where to add:

**File 1:** `lib/core/constants/api_keys.dart`
```dart
static const String googleMapsApiKey = 'YOUR_KEY_HERE';
```

**File 2:** `android/app/src/main/AndroidManifest.xml`
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_KEY_HERE" />
```

### Security (Restrict your key):
- In Google Cloud Console → Credentials → Edit your API Key
- Under "Application restrictions" → Android apps
- Add: Package name `com.getwork.getwork`, get SHA-1 via:
  ```
  keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android
  ```

---

## 2. 🟢 Supabase URL + Anon Key

### When to add: Phase 2 (Backend integration)

### Steps:
1. Go to [supabase.com](https://supabase.com) → Sign up / Login
2. Create a new project (choose region closest to Nepal: Singapore)
3. Wait for project to initialize (~2 minutes)
4. Go to **Project Settings → API**
5. Copy:
   - **Project URL** (e.g., `https://abcxyz.supabase.co`)
   - **anon / public key** (the long JWT token)

### Where to add:

**File:** `lib/core/constants/supabase_config.dart`
```dart
static const String supabaseUrl = 'https://YOUR-PROJECT.supabase.co';
static const String supabaseAnonKey = 'YOUR_ANON_KEY_HERE';
```

**Then uncomment in `lib/main.dart`:**
```dart
await Supabase.initialize(
  url: SupabaseConfig.supabaseUrl,
  anonKey: SupabaseConfig.supabaseAnonKey,
);
```

---

## 3. 🔥 Firebase Config (`google-services.json`)

### When to add: Phase 3 (Push notifications + Auth)

### Steps:
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create new project → name it "GetWork"
3. Add Android app:
   - Package name: `com.getwork.getwork`
   - App nickname: GetWork Android
   - Download `google-services.json`
4. Place `google-services.json` in: `android/app/google-services.json`
5. Enable services you need:
   - **Authentication** → Google Sign-In + Phone
   - **Cloud Messaging** → For push notifications

### Update `android/app/build.gradle.kts`:
```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

### Update `android/build.gradle.kts`:
```kotlin
dependencies {
    classpath("com.google.gms:google-services:4.4.2")
}
```

**Then uncomment in `lib/main.dart`:**
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

---

## ⚠️ Security Reminders

| Rule | Details |
|------|---------|
| Never commit real keys to Git | Add `lib/core/constants/api_keys.dart` to `.gitignore` if it has real keys |
| Supabase anon key is safe | It works with Row Level Security (RLS) |
| Restrict Maps key | Bind it to your Android app's package + SHA-1 |
| Never use service_role key | Only use on server-side, never in mobile app |
