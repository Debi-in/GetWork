// ============================================================
// NOTIFICATION ITEM MODEL — GetWork App
// Supports 3-day retention, read status, and category icons
// ============================================================

import 'package:flutter/material.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final String type; // 'new_job' | 'application_status' | 'system' | 'account'
  bool isRead;
  final Map<String, dynamic>? data;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    this.isRead = false,
    this.data,
  });

  /// Check if this notification is older than 3 days
  bool get isExpired {
    final cutoff = DateTime.now().subtract(const Duration(days: 3));
    return createdAt.isBefore(cutoff);
  }

  /// Whether this belongs to the "System" tab vs "For You" tab
  bool get isSystem => type == 'system';

  /// Icon based on notification type
  IconData get icon {
    switch (type) {
      case 'new_job':
        return Icons.near_me_rounded;
      case 'application_status':
        return Icons.check_circle_rounded;
      case 'system':
        return Icons.campaign_rounded;
      case 'account':
        return Icons.shield_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  /// Icon background color based on type
  Color get iconBgColor {
    switch (type) {
      case 'new_job':
        return const Color(0xFF5B8A6F); // Primary Green
      case 'application_status':
        return const Color(0xFF4CAF50); // Success Green
      case 'system':
        return const Color(0xFF7C4DFF); // Purple
      case 'account':
        return const Color(0xFF3F64D8); // Blue
      default:
        return const Color(0xFFE89F2A); // Amber
    }
  }

  /// Relative human-readable time (e.g., "5m ago", "2h ago", "1d ago")
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return '1d ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  /// Factory constructor from Supabase row or local JSON map
  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      message: json['body']?.toString() ?? json['message']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      type: json['type']?.toString() ?? 'system',
      isRead: json['is_read'] == true || json['isRead'] == true,
      data: json['data'] is Map<String, dynamic> ? json['data'] : null,
    );
  }

  /// Convert to JSON for local persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': message,
      'created_at': createdAt.toIso8601String(),
      'type': type,
      'is_read': isRead,
      'data': data,
    };
  }
}
