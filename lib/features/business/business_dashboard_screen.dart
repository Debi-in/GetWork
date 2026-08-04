// ============================================================
// BUSINESS DASHBOARD SCREEN — GetWork App
// Dedicated Business App Interface featuring:
// - Floating Island Bottom Navigation Bar
// - Separate Floating (+) Post Job Action Button (Matching Pinterest Spec)
// - Metrics Cards (Active Jobs, Pending Applicants, Hired Workers)
// - Visual Progress Bar Job Cards
// - Dual Role Switcher ("Switch to Worker App")
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../router.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() => _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  int _currentNavIndex = 0; // 0:Dashboard, 1:Messages, 2:Analytics, 3:Settings

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Main Dashboard Scrollable Content ─────────────────
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 16, bottom: 100, left: 16, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Business Header & Role Switcher ──────────────────
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.accentContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'HM',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accentDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Himalayan Mart',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                            const Text(
                              'Patan Dhoka, Lalitpur',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Role Switcher Pill Button
                      OutlinedButton.icon(
                        onPressed: () => context.go('/choose-role'),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                        label: const Text('Worker Mode'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Business Metrics Cards Grid ──────────────────────
                  const Text(
                    'Hiring Overview',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.6,
                    children: const [
                      _MetricCard(
                        title: 'Active Jobs',
                        value: '12',
                        icon: Icons.work_rounded,
                        color: AppColors.primary,
                        bgColor: AppColors.primaryContainer,
                      ),
                      _MetricCard(
                        title: 'Pending Applicants',
                        value: '18',
                        icon: Icons.people_outline_rounded,
                        color: AppColors.accent,
                        bgColor: AppColors.accentContainer,
                      ),
                      _MetricCard(
                        title: 'Workers Hired',
                        value: '7',
                        icon: Icons.check_circle_outline_rounded,
                        color: Color(0xFF2196F3),
                        bgColor: Color(0xFFE3F2FD),
                      ),
                      _MetricCard(
                        title: 'Today\'s Shift',
                        value: '4',
                        icon: Icons.access_time_rounded,
                        color: Color(0xFF7C4DFF),
                        bgColor: Color(0xFFEDE7F6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Active Job Postings List ─────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Posted Jobs',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Job Post Card 1
                  _BusinessJobCard(
                    title: 'Supermarket Cashier',
                    rate: 'Rs. 700 /day',
                    status: 'Active',
                    statusColor: AppColors.primary,
                    workersHired: 2,
                    workersNeeded: 2,
                    appliedCount: 8,
                    shiftDate: 'Today, 10:00 AM - 06:00 PM',
                  ),
                  const SizedBox(height: 12),

                  // Job Post Card 2
                  _BusinessJobCard(
                    title: 'Delivery Rider',
                    rate: 'Rs. 900 /day',
                    status: 'Urgent',
                    statusColor: AppColors.accent,
                    workersHired: 1,
                    workersNeeded: 3,
                    appliedCount: 5,
                    shiftDate: 'Today, 09:00 AM - 05:00 PM',
                  ),
                  const SizedBox(height: 12),

                  // Job Post Card 3
                  _BusinessJobCard(
                    title: 'Event Setup Staff',
                    rate: 'Rs. 1,300 /day',
                    status: 'Active',
                    statusColor: AppColors.primary,
                    workersHired: 4,
                    workersNeeded: 10,
                    appliedCount: 12,
                    shiftDate: 'Tomorrow, 07:00 AM - 05:00 PM',
                  ),
                ],
              ),
            ),

            // ── FLOATING ISLAND NAV: split-pill | FAB | split-pill ─────
            Positioned(
              bottom: 16,
              left: 14,
              right: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // ── Left pill: Dashboard + Messages ─────────────────
                  Expanded(
                    child: Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.border, width: 0.8),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadowMedium,
                            blurRadius: 20,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _NavItem(
                            icon: Icons.dashboard_rounded,
                            isSelected: _currentNavIndex == 0,
                            onTap: () => setState(() => _currentNavIndex = 0),
                          ),
                          _NavItem(
                            icon: Icons.chat_bubble_outline_rounded,
                            isSelected: _currentNavIndex == 1,
                            onTap: () => setState(() => _currentNavIndex = 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // ── CENTER: Raised Spring Speed Dial FAB ─────────────
                  Transform.translate(
                    offset: const Offset(0, -10),
                    child: _SpeedDial(
                      actions: [
                        _SpeedDialAction(
                          icon: Icons.edit_rounded,
                          color: AppColors.primary,
                          bgColor: AppColors.primaryContainer,
                          onTap: () => context.push(AppRoutes.postJob),
                        ),
                        _SpeedDialAction(
                          icon: Icons.bookmark_outline_rounded,
                          color: const Color(0xFF7C4DFF),
                          bgColor: const Color(0xFFEDE7F6),
                          onTap: () {},
                        ),
                        _SpeedDialAction(
                          icon: Icons.people_outline_rounded,
                          color: AppColors.accent,
                          bgColor: AppColors.accentContainer,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // ── Right pill: Analytics + Settings ────────────────
                  Expanded(
                    child: Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.border, width: 0.8),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadowMedium,
                            blurRadius: 20,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _NavItem(
                            icon: Icons.bar_chart_rounded,
                            isSelected: _currentNavIndex == 2,
                            onTap: () => setState(() => _currentNavIndex = 2),
                          ),
                          _NavItem(
                            icon: Icons.settings_outlined,
                            isSelected: _currentNavIndex == 3,
                            onTap: () => setState(() => _currentNavIndex = 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Metric Card Widget ─────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Job Post Card with Visual Progress Bar ─────────────────────
class _BusinessJobCard extends StatelessWidget {
  final String title;
  final String rate;
  final String status;
  final Color statusColor;
  final int workersHired;
  final int workersNeeded;
  final int appliedCount;
  final String shiftDate;

  const _BusinessJobCard({
    required this.title,
    required this.rate,
    required this.status,
    required this.statusColor,
    required this.workersHired,
    required this.workersNeeded,
    required this.appliedCount,
    required this.shiftDate,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (workersHired / workersNeeded).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title, Status & Rate Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                rate,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            shiftDate,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Visual Progress Bar (Hired / Needed)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hired: $workersHired / $workersNeeded Workers',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}% Filled',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? AppColors.primary : AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons Row (Applicants, Edit, Repost)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.people_rounded, size: 16),
                  label: Text('Applicants ($appliedCount)'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: AppColors.primaryDark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(60, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Edit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Speed Dial Action Model ────────────────────────────────────
class _SpeedDialAction {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  const _SpeedDialAction({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });
}

// ── Stateful Speed Dial FAB Widget with Spring Animation ───────
class _SpeedDial extends StatefulWidget {
  final List<_SpeedDialAction> actions;

  const _SpeedDial({required this.actions});

  @override
  State<_SpeedDial> createState() => _SpeedDialState();
}

class _SpeedDialState extends State<_SpeedDial> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  // Exact spring cubic bezier matching spec: cubic-bezier(0.34, 1.56, 0.64, 1)
  static const Curve _springCurve = Cubic(0.34, 1.56, 0.64, 1.0);

  // Exact target fan offsets: upper-left (-54, -58), top (0, -80), upper-right (54, -58)
  static const List<Offset> _fanTargets = [
    Offset(-54, -58),
    Offset(0, -80),
    Offset(54, -58),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ── 3 Mini Action Buttons Emerging from Center ────────
          ...List.generate(widget.actions.length, (i) {
            final action = widget.actions[i];
            final targetOffset = _fanTargets[i];
            final delayFraction = (i * 0.08).clamp(0.0, 0.25);

            final scaleAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Interval(delayFraction, 1.0, curve: _springCurve),
              ),
            );

            final opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Interval(delayFraction, (delayFraction + 0.4).clamp(0.0, 1.0), curve: Curves.easeOut),
              ),
            );

            final translateAnimation = Tween<Offset>(begin: Offset.zero, end: targetOffset).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Interval(delayFraction, 1.0, curve: _springCurve),
              ),
            );

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final offset = translateAnimation.value;
                final scale = scaleAnimation.value;
                final opacity = opacityAnimation.value;

                return Transform.translate(
                  offset: offset,
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: IgnorePointer(
                        ignoring: !_isOpen,
                        child: GestureDetector(
                          onTap: () {
                            _toggle();
                            action.onTap();
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: action.bgColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: action.color.withValues(alpha: 0.35),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: action.color.withValues(alpha: 0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(action.icon, color: action.color, size: 22),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // ── Central FAB Button (+) Always Emerald Green ────────
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggle,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.40),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: RotationTransition(
                  turns: _rotationAnimation,
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Floating Island Nav Item ───────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          size: 22,
        ),
      ),
    );
  }
}
