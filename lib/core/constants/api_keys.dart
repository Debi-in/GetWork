// ============================================================
// API KEYS — GetWork App
// ============================================================
// HOW TO USE:
//   1. Get your Google Maps API Key from:
//      https://console.cloud.google.com → APIs & Services → Credentials
//   2. Enable "Maps SDK for Android" in your project
//   3. Replace the placeholder below with your actual key
//   4. Also add it to AndroidManifest.xml (see docs/ApiKeysGuide.md)
//
// ⚠️  NEVER commit real API keys to Git. Add this file to .gitignore
//     or use environment variables in production.
// ============================================================

class ApiKeys {
  ApiKeys._(); // Prevent instantiation

  // ── Google Maps ──────────────────────────────────────────────
  // Replace with your actual Google Maps API Key
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';

  // ── Google Sign-In (Phase 3) ─────────────────────────────────
  // Found in google-services.json as "client_id"
  static const String googleWebClientId = 'YOUR_GOOGLE_WEB_CLIENT_ID_HERE';
}
