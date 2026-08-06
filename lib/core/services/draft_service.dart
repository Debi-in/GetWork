// ============================================================
// DRAFT SERVICE — GetWork App
// Saves/loads job post drafts in SharedPreferences (4-day expiry)
// ============================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DraftService {
  static const _key = 'getwork_job_drafts';
  static const expiryDays = 4;

  /// Save (or update) a draft. If [draft] has an 'id', it updates; otherwise creates.
  static Future<String> saveDraft(Map<String, dynamic> draft) async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = await _loadRaw(prefs);
    final now = DateTime.now();

    // Assign an id if missing
    final id = (draft['id'] as String?)?.isNotEmpty == true
        ? draft['id'] as String
        : 'draft_${now.millisecondsSinceEpoch}';

    draft['id'] = id;
    draft['savedAt'] = now.toIso8601String();

    // Remove any existing entry with same id
    drafts.removeWhere((d) => d['id'] == id);
    drafts.add(draft);

    await prefs.setString(_key, json.encode(drafts));
    return id;
  }

  /// Load all non-expired drafts, sorted newest first.
  static Future<List<Map<String, dynamic>>> loadDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final valid = await _loadRaw(prefs);
    // Persist cleaned list (removes expired ones)
    await prefs.setString(_key, json.encode(valid));
    valid.sort((a, b) {
      final ta = DateTime.tryParse(a['savedAt'] as String? ?? '') ?? DateTime(2000);
      final tb = DateTime.tryParse(b['savedAt'] as String? ?? '') ?? DateTime(2000);
      return tb.compareTo(ta);
    });
    return valid;
  }

  /// Delete a draft by id.
  static Future<void> deleteDraft(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = await _loadRaw(prefs);
    drafts.removeWhere((d) => d['id'] == id);
    await prefs.setString(_key, json.encode(drafts));
  }

  // ── Internal ───────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> _loadRaw(
      SharedPreferences prefs) async {
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final decoded = json.decode(raw) as List<dynamic>;
      final now = DateTime.now();
      return decoded
          .cast<Map<String, dynamic>>()
          .where((d) {
            final saved =
                DateTime.tryParse(d['savedAt'] as String? ?? '');
            if (saved == null) return false;
            return now.difference(saved).inDays < expiryDays;
          })
          .toList();
    } catch (_) {
      return [];
    }
  }
}
