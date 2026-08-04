// ============================================================
// NOTIFICATIONS SCREEN — GetWork App
// Dynamic real-time data, 3-day retention auto-purge,
// Swipe-left delete with 3-second UNDO countdown & mark as read
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import 'models/notification_item.dart';
import 'services/notification_repository.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedTab = 0; // 0: For You, 1: System
  bool _isLoading = true;
  List<NotificationItem> _notifications = [];

  // Track pending deletions for 3-second UNDO countdown
  final Map<String, _PendingDeletion> _pendingDeletions = {};

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    // Execute any remaining pending deletions immediately on screen exit
    for (final deletion in _pendingDeletions.values) {
      deletion.timer.cancel();
      NotificationRepository.deleteNotification(deletion.item.id);
    }
    _pendingDeletions.clear();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final items = await NotificationRepository.fetchNotifications();
    if (mounted) {
      setState(() {
        _notifications = items;
        _isLoading = false;
      });
    }
  }

  void _markAllAsRead() async {
    final currentTabItems = _selectedTab == 0
        ? _notifications.where((n) => !n.isSystem).toList()
        : _notifications.where((n) => n.isSystem).toList();

    if (currentTabItems.isEmpty) return;

    setState(() {
      for (var item in currentTabItems) {
        item.isRead = true;
      }
    });

    await NotificationRepository.markAllAsRead(currentTabItems);
  }

  void _markItemAsRead(NotificationItem item) async {
    if (item.isRead) return;
    setState(() {
      item.isRead = true;
    });
    await NotificationRepository.markAsRead(item.id);
  }

  /// Swipe left to delete with 3-second UNDO countdown
  void _onSwipeToDelete(NotificationItem item, int originalIndex) {
    // 1. Remove from UI list immediately
    setState(() {
      _notifications.removeWhere((n) => n.id == item.id);
    });

    // 2. Start 3-second timer before permanent deletion
    final timer = Timer(const Duration(seconds: 3), () async {
      _pendingDeletions.remove(item.id);
      await NotificationRepository.deleteNotification(item.id);
    });

    _pendingDeletions[item.id] = _PendingDeletion(
      item: item,
      originalIndex: originalIndex,
      timer: timer,
    );

    // 3. Show SnackBar with UNDO button & 3s timer countdown
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xFF1E2235),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: const [
            Icon(Icons.delete_outline_rounded, color: Colors.white70, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Notification deleted',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: const Color(0xFFFFB74D), // Soft Amber
          onPressed: () => _undoDeletion(item.id),
        ),
      ),
    );
  }

  /// Undo a pending deletion if tapped within 3 seconds
  void _undoDeletion(String id) {
    final pending = _pendingDeletions.remove(id);
    if (pending != null) {
      pending.timer.cancel();
      setState(() {
        final insertIdx = pending.originalIndex.clamp(0, _notifications.length);
        _notifications.insert(insertIdx, pending.item);
      });
      ScaffoldMessenger.of(context).clearSnackBars();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter active items for current tab
    final filteredNotifications = _selectedTab == 0
        ? _notifications.where((n) => !n.isSystem).toList()
        : _notifications.where((n) => n.isSystem).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Title & Tabs ────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '3-day auto-purge',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Tab 0: For You
                    _buildTabButton(0, 'For You'),
                    const SizedBox(width: 20),
                    // Tab 1: System
                    _buildTabButton(1, 'System'),
                    const Spacer(),

                    // Mark all as read button
                    GestureDetector(
                      onTap: _markAllAsRead,
                      child: const Text(
                        'Mark all as read',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),

          // ── Notification List ──────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    color: AppColors.primary,
                    child: filteredNotifications.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 120),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.notifications_off_outlined,
                                      size: 56,
                                      color: AppColors.textHint,
                                    ),
                                    SizedBox(height: 14),
                                    Text(
                                      'No notifications yet',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'New job alerts and updates will appear here.\nNotifications are automatically kept for 3 days.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredNotifications.length,
                            itemBuilder: (context, index) {
                              final item = filteredNotifications[index];
                              return _buildDismissibleCard(item, index);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: isSelected ? 36 : 0,
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  /// Dismissible wrapper for swipe-left-to-delete with red background
  Widget _buildDismissibleCard(NotificationItem item, int index) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart, // Swipe Left
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFE53935), // Red
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: const [
            Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_forever_rounded, color: Colors.white, size: 24),
          ],
        ),
      ),
      onDismissed: (_) => _onSwipeToDelete(item, index),
      child: GestureDetector(
        onTap: () => _markItemAsRead(item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: item.isRead
                ? Border.all(color: Colors.transparent)
                : Border.all(color: AppColors.navPurple.withValues(alpha: 0.3), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circular Category Icon Badge
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: item.iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Title, Message & Timestamp
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: AppColors.navPurple,
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                            color: AppColors.textHint,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: item.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.timeAgo,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textHint,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Text(
                          'Swipe to delete ←',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: AppColors.textHint,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingDeletion {
  final NotificationItem item;
  final int originalIndex;
  final Timer timer;

  _PendingDeletion({
    required this.item,
    required this.originalIndex,
    required this.timer,
  });
}
