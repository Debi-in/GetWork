// ============================================================
// NOTIFICATIONS SCREEN — GetWork App
// Redesigned with category icon badges, tabs, and unread dots
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String timeAgo;
  final IconData icon;
  final Color iconBgColor;
  bool isRead;
  final bool isSystem; // true = System tab, false = For You tab

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.icon,
    required this.iconBgColor,
    this.isRead = false,
    this.isSystem = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedTab = 0; // 0: For You, 1: System

  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: '3 New Jobs Nearby',
      message: 'We found 3 new shifts within 5 km of your location! Check them out now.',
      timeAgo: '10m ago',
      icon: Icons.near_me_rounded,
      iconBgColor: const Color(0xFF5B8A6F),
      isRead: false,
      isSystem: false,
    ),
    NotificationItem(
      id: '2',
      title: 'Application Accepted! 🎉',
      message: 'Daraz Nepal accepted your application for Delivery Rider shift!',
      timeAgo: '1h ago',
      icon: Icons.check_circle_rounded,
      iconBgColor: const Color(0xFF4CAF50),
      isRead: false,
      isSystem: false,
    ),
    NotificationItem(
      id: '3',
      title: 'System Maintenance Update',
      message: 'GetWork platform updates scheduled tonight at 12:00 AM. Services will remain active.',
      timeAgo: '3h ago',
      icon: Icons.campaign_rounded,
      iconBgColor: const Color(0xFF7C4DFF),
      isRead: true,
      isSystem: true,
    ),
    NotificationItem(
      id: '4',
      title: 'Account Security Alert',
      message: 'Your login security preferences were successfully updated.',
      timeAgo: '1d ago',
      icon: Icons.shield_rounded,
      iconBgColor: const Color(0xFF3F64D8),
      isRead: true,
      isSystem: false,
    ),
    NotificationItem(
      id: '5',
      title: 'Welcome to GetWork Xaie!',
      message: 'Complete your profile details to increase your chances of getting hired by 80%.',
      timeAgo: '2d ago',
      icon: Icons.info_rounded,
      iconBgColor: const Color(0xFFE89F2A),
      isRead: true,
      isSystem: true,
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      for (var item in _notifications) {
        item.isRead = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
            child: filteredNotifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.notifications_off_outlined,
                            size: 56, color: AppColors.textHint),
                        SizedBox(height: 14),
                        Text(
                          'No notifications here',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredNotifications.length,
                    itemBuilder: (context, i) {
                      final item = filteredNotifications[i];
                      return _buildNotificationCard(item);
                    },
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

  Widget _buildNotificationCard(NotificationItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (!item.isRead)
                      Container(
                        width: 8,
                        height: 8,
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
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.timeAgo,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
