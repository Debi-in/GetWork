// ============================================================
// FIRESTORE USER SERVICE — GetWork App
// Reads and writes users/{uid} documents in Cloud Firestore.
// Source of truth for role locking.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreUserService {
  FirestoreUserService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  // ── Read ─────────────────────────────────────────────────────

  /// Returns the locked role for this UID, or null if not yet set.
  static Future<String?> getRole(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (!doc.exists) return null;
      final data = doc.data();
      return data?['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Returns true if the role field is already locked in Firestore.
  static Future<bool> isRoleLocked(String uid) async {
    final role = await getRole(uid);
    return role != null && role.isNotEmpty;
  }

  // ── Write ────────────────────────────────────────────────────

  /// Creates or updates the users/{uid} document.
  /// Role is only written once; subsequent calls with a different role
  /// are ignored if roleLockedAt is already set.
  static Future<void> saveUser({
    required String uid,
    required String phone,
    String name = '',
    required String role,
  }) async {
    final docRef = _users.doc(uid);
    final snap = await docRef.get();

    if (snap.exists) {
      final existing = snap.data();
      // Role already locked — do not overwrite
      if (existing?['roleLockedAt'] != null) return;
    }

    await docRef.set({
      'uid': uid,
      'phone': phone,
      'name': name,
      'role': role,
      'roleLockedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Update non-locked profile fields (name, etc.) safely.
  static Future<void> updateProfile({
    required String uid,
    String? name,
    String? avatarUrl,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
    if (data.isEmpty) return;
    await _users.doc(uid).set(data, SetOptions(merge: true));
  }
}
