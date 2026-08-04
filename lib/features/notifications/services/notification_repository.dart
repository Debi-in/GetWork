// ============================================================
// NOTIFICATION REPOSITORY — GetWork App
// Handles dynamic fetching, 3-day auto-purge, read status & deletion
// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_item.dart';

class NotificationRepository {
  static const String _localKey = 'getwork_local_notifications_v1';

  /// Fetch notifications for current user / device.
  /// Automatically purges items older than 3 days.
  static Future<List<NotificationItem>> fetchNotifications() async {
    final List<NotificationItem> result = [];
    final cutoff = DateTime.now().subtract(const Duration(days: 3));

    try {
      final user = Supabase.instance.client.auth.currentUser;

      // ── 1. Fetch from Supabase `notifications` table if logged in ────
      if (user != null) {
        final rows = await Supabase.instance.client
            .from('notifications')
            .select()
            .eq('receiver_id', user.id)
            .gte('created_at', cutoff.toIso8601String())
            .order('created_at', ascending: false);

        for (final row in (rows as List<dynamic>)) {
          result.add(NotificationItem.fromJson(row));
        }

        // Trigger remote purge of items > 3 days old for this user
        _purgeRemoteOldNotifications(user.id, cutoff);
      }

      // ── 2. Merge with locally cached notifications ───────────────────
      final localItems = await _loadLocalNotifications();
      for (final localItem in localItems) {
        // Exclude expired items (> 3 days)
        if (!localItem.isExpired && !result.any((r) => r.id == localItem.id)) {
          result.add(localItem);
        }
      }

      // ── 3. Sort by created_at descending (newest first) ──────────────
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Save cleaned list back to local storage
      await _saveLocalNotifications(result);

      return result;
    } catch (e) {
      if (kDebugMode) print('⚠️ [Fetch Notifications Error]: $e');
      // Fallback to local storage
      final localItems = await _loadLocalNotifications();
      return localItems.where((n) => !n.isExpired).toList();
    }
  }

  /// Mark single notification as read in UI & DB
  static Future<void> markAsRead(String id) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('notifications')
            .update({'is_read': true})
            .eq('id', id);
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ [Mark As Read Error]: $e');
    }
  }

  /// Mark all notifications as read in UI & DB
  static Future<void> markAllAsRead(List<NotificationItem> items) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final ids = items.map((e) => e.id).toList();
        if (ids.isNotEmpty) {
          await Supabase.instance.client
              .from('notifications')
              .update({'is_read': true})
              .inFilter('id', ids);
        }
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ [Mark All Read Error]: $e');
    }
  }

  /// Permanently delete a notification from Supabase DB & Local Storage
  static Future<void> deleteNotification(String id) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('notifications')
            .delete()
            .eq('id', id);
      }

      // Delete from local cache as well
      final local = await _loadLocalNotifications();
      local.removeWhere((item) => item.id == id);
      await _saveLocalNotifications(local);
    } catch (e) {
      if (kDebugMode) print('⚠️ [Delete Notification Error]: $e');
    }
  }

  /// Save a new notification locally (e.g. from FCM message foreground/background)
  static Future<void> addNotification(NotificationItem item) async {
    final list = await _loadLocalNotifications();
    list.removeWhere((existing) => existing.id == item.id);
    list.insert(0, item);
    // Keep max 50 items and purge > 3 days old
    final cleaned = list.where((n) => !n.isExpired).take(50).toList();
    await _saveLocalNotifications(cleaned);
  }

  // ── PRIVATE HELPERS ─────────────────────────────────────────────

  static Future<List<NotificationItem>> _loadLocalNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_localKey);
      if (str == null || str.isEmpty) return [];
      final List<dynamic> jsonList = jsonDecode(str);
      return jsonList
          .map((j) => NotificationItem.fromJson(j))
          .where((n) => !n.isExpired)
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> _saveLocalNotifications(List<NotificationItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final validItems = items.where((n) => !n.isExpired).toList();
      final str = jsonEncode(validItems.map((n) => n.toJson()).toList());
      await prefs.setString(_localKey, str);
    } catch (_) {}
  }

  static Future<void> _purgeRemoteOldNotifications(String userId, DateTime cutoff) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('receiver_id', userId)
          .lt('created_at', cutoff.toIso8601String());
    } catch (_) {}
  }
}
