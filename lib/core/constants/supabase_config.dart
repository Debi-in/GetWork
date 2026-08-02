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
  static const String supabaseUrl = 'https://umoyvhkzsomfyjriexcn.supabase.co';

  // ── Anon/Public Key ──────────────────────────────────────────
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVtb3l2aGt6c29tZnlqcmlleGNuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU2NzAyODAsImV4cCI6MjEwMTI0NjI4MH0.vw8xTnzSlkx7adpXaWX-DxCFb1xi_bP3v5EQLLaiq-Q';

  // ── Storage Bucket Names ─────────────────────────────────────
  static const String avatarsBucket = 'avatars';
  static const String jobImagesBucket = 'job-images';
  static const String businessLogosBucket = 'business-logos';
}
