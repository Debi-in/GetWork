// ============================================================
// SUPABASE CONFIG — GetWork App
// ============================================================
// HOW TO USE:
//   1. Go to https://supabase.com and create a project
//   2. Go to Project Settings → API
//   3. Copy your Project URL and anon/public key
//   4. Replace the placeholders below
//
// ⚠️  The anon key is safe to expose in mobile apps (Row Level Security
//     protects your data), but never expose your service_role key.
// ============================================================

class SupabaseConfig {
  SupabaseConfig._(); // Prevent instantiation

  // ── Project URL ──────────────────────────────────────────────
  // Example: https://xyzabc.supabase.co
  static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';

  // ── Anon/Public Key ──────────────────────────────────────────
  // Safe to use in mobile apps with Row Level Security enabled
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';

  // ── Storage Bucket Names ─────────────────────────────────────
  static const String avatarsBucket = 'avatars';
  static const String jobImagesBucket = 'job-images';
  static const String businessLogosBucket = 'business-logos';
}
