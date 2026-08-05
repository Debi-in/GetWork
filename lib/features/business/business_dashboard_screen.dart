// ============================================================
// BUSINESS DASHBOARD SCREEN — GetWork App
// Dedicated Business App Interface featuring:
// - Floating Island Bottom Navigation Bar
// - Separate Floating (+) Post Job Action Button (Matching Pinterest Spec)
// - LIVE Metrics Cards (Active Jobs, Pending Applicants, Hired Workers)
// - LIVE Posted Jobs from Supabase via allJobsProvider
// - Dual Role Switcher ("Switch to Worker App")
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../router.dart';
import '../jobs/jobs_provider.dart';
import '../../models/job_model.dart';
import '../../core/constants/supabase_config.dart';

class BusinessDashboardScreen extends ConsumerStatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  ConsumerState<BusinessDashboardScreen> createState() =>
      _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState
    extends ConsumerState<BusinessDashboardScreen> {
  int _currentNavIndex = 0; // 0:Dashboard, 1:Messages, 2:Analytics, 3:Settings

  @override
  Widget build(BuildContext context) {
    // ── Watch live jobs from Supabase ─────────────────────────
    final jobsAsync = ref.watch(allJobsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Tab Content via IndexedStack ───────────────────────
            IndexedStack(
              index: _currentNavIndex,
              children: [
                // ── Tab 0: Dashboard ────────────────────────────────
                SingleChildScrollView(
                  padding: const EdgeInsets.only(
                      top: 16, bottom: 100, left: 16, right: 16),
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
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10),
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

                  // Live metrics derived from Supabase data
                  jobsAsync.when(
                    loading: () => GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.6,
                      children: const [
                        _MetricCard(title: 'Active Jobs', value: '—', icon: Icons.work_rounded, color: AppColors.primary, bgColor: AppColors.primaryContainer),
                        _MetricCard(title: 'Total Applied', value: '—', icon: Icons.people_outline_rounded, color: AppColors.accent, bgColor: AppColors.accentContainer),
                        _MetricCard(title: 'Workers Hired', value: '—', icon: Icons.check_circle_outline_rounded, color: Color(0xFF2196F3), bgColor: Color(0xFFE3F2FD)),
                        _MetricCard(title: 'Today\'s Shifts', value: '—', icon: Icons.access_time_rounded, color: Color(0xFF7C4DFF), bgColor: Color(0xFFEDE7F6)),
                      ],
                    ),
                    error: (e, _) => GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.6,
                      children: const [
                        _MetricCard(title: 'Active Jobs', value: '0', icon: Icons.work_rounded, color: AppColors.primary, bgColor: AppColors.primaryContainer),
                        _MetricCard(title: 'Total Applied', value: '0', icon: Icons.people_outline_rounded, color: AppColors.accent, bgColor: AppColors.accentContainer),
                        _MetricCard(title: 'Workers Hired', value: '0', icon: Icons.check_circle_outline_rounded, color: Color(0xFF2196F3), bgColor: Color(0xFFE3F2FD)),
                        _MetricCard(title: 'Today\'s Shifts', value: '0', icon: Icons.access_time_rounded, color: Color(0xFF7C4DFF), bgColor: Color(0xFFEDE7F6)),
                      ],
                    ),
                    data: (jobs) {
                      final activeJobs =
                          jobs.where((j) => j.status == JobStatus.active).length;
                      final totalApplied = jobs.fold<int>(
                          0, (sum, j) => sum + j.workersApplied);
                      final totalHired = jobs.fold<int>(
                          0, (sum, j) => sum + j.workersNeeded.clamp(0, j.workersApplied));
                      final todayShifts =
                          jobs.where((j) => j.isToday && j.status == JobStatus.active).length;

                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.6,
                        children: [
                          _MetricCard(title: 'Active Jobs', value: '$activeJobs', icon: Icons.work_rounded, color: AppColors.primary, bgColor: AppColors.primaryContainer),
                          _MetricCard(title: 'Total Applied', value: '$totalApplied', icon: Icons.people_outline_rounded, color: AppColors.accent, bgColor: AppColors.accentContainer),
                          _MetricCard(title: 'Workers Hired', value: '$totalHired', icon: Icons.check_circle_outline_rounded, color: const Color(0xFF2196F3), bgColor: const Color(0xFFE3F2FD)),
                          _MetricCard(title: 'Today\'s Shifts', value: '$todayShifts', icon: Icons.access_time_rounded, color: const Color(0xFF7C4DFF), bgColor: const Color(0xFFEDE7F6)),
                        ],
                      );
                    },
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
                        onPressed: () {
                          ref.read(allJobsProvider.notifier).refresh();
                        },
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── Live Job Cards from Supabase ─────────────────────
                  jobsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => _LiveJobsFallback(),
                    data: (jobs) {
                      if (jobs.isEmpty) return _LiveJobsFallback();
                      return Column(
                        children: jobs
                            .take(10)
                            .map((job) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 12),
                                  child: _BusinessJobCard(
                                    jobId: job.id,
                                    title: job.title,
                                    rate: job.salaryDisplay,
                                    status: job.isUrgent ? 'Urgent' : job.status.name,
                                    statusColor: job.isUrgent
                                        ? AppColors.accent
                                        : AppColors.primary,
                                    workersHired: job.workersApplied
                                        .clamp(0, job.workersNeeded),
                                    workersNeeded: job.workersNeeded,
                                    appliedCount: job.workersApplied,
                                    shiftDate:
                                        '${_formatDate(job.shiftDate)}, ${job.shiftStartTime} - ${job.shiftEndTime}',
                                  ),
                                ))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),

                // ── Tab 1: Messages ─────────────────────────────────
                _MessagesTab(),

                // ── Tab 2: Analytics ────────────────────────────────
                _AnalyticsTab(jobsAsync: ref.watch(allJobsProvider)),

                // ── Tab 3: Settings ─────────────────────────────────
                _SettingsTab(),
              ],
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
                        border:
                            Border.all(color: AppColors.border, width: 0.8),
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
                            onTap: () =>
                                setState(() => _currentNavIndex = 0),
                          ),
                          _NavItem(
                            icon: Icons.chat_bubble_outline_rounded,
                            isSelected: _currentNavIndex == 1,
                            onTap: () =>
                                setState(() => _currentNavIndex = 1),
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
                        border:
                            Border.all(color: AppColors.border, width: 0.8),
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
                            onTap: () =>
                                setState(() => _currentNavIndex = 2),
                          ),
                          _NavItem(
                            icon: Icons.settings_outlined,
                            isSelected: _currentNavIndex == 3,
                            onTap: () =>
                                setState(() => _currentNavIndex = 3),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
    if (isToday) return 'Today';
    if (isTomorrow) return 'Tomorrow';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ── Fallback when Supabase has no jobs yet ─────────────────────
class _LiveJobsFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
  final String jobId;
  final String title;
  final String rate;
  final String status;
  final Color statusColor;
  final int workersHired;
  final int workersNeeded;
  final int appliedCount;
  final String shiftDate;

  const _BusinessJobCard({
    this.jobId = '',
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
    final progress = workersNeeded > 0
        ? (workersHired / workersNeeded).clamp(0.0, 1.0)
        : 0.0;

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
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
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
              ),
              const SizedBox(width: 8),
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
                  onPressed: () {
                    if (jobId.isNotEmpty) {
                      context.push('/business/job/$jobId/applicants');
                    }
                  },
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

class _SpeedDialState extends State<_SpeedDial>
    with SingleTickerProviderStateMixin {
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

            final opacityAnimation =
                Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Interval(delayFraction,
                    (delayFraction + 0.4).clamp(0.0, 1.0),
                    curve: Curves.easeOut),
              ),
            );

            final translateAnimation =
                Tween<Offset>(begin: Offset.zero, end: targetOffset).animate(
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
                            child:
                                Icon(action.icon, color: action.color, size: 22),
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

// ╔══════════════════════════════════════════════════════════════╗
// ║  TAB 1 — MESSAGES                                           ║
// ╚══════════════════════════════════════════════════════════════╝
class _MessagesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Placeholder chats — replace with Supabase realtime in Phase 2
    final chats = [
      _ChatPreview(name: 'Ramesh Tamang', snippet: 'Can you start Monday morning?', time: '2m ago', unread: 2, avatarColor: AppColors.primary),
      _ChatPreview(name: 'Sita Rai', snippet: 'I have experience in retail.', time: '18m ago', unread: 0, avatarColor: AppColors.accent),
      _ChatPreview(name: 'Bikash KC', snippet: 'Thank you for accepting me!', time: '1h ago', unread: 1, avatarColor: const Color(0xFF7C4DFF)),
      _ChatPreview(name: 'Anita Shrestha', snippet: 'What time should I arrive?', time: '3h ago', unread: 0, avatarColor: const Color(0xFFFF5722)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Messages',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  '3 unread',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Search box
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                SizedBox(width: 12),
                Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Search conversations…',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Chat list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 68),
            itemBuilder: (context, i) {
              final c = chats[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: c.avatarColor.withValues(alpha: 0.15),
                  child: Text(
                    c.name.substring(0, 1),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w800,
                      color: c.avatarColor,
                      fontSize: 16,
                    ),
                  ),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      c.name,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: c.unread > 0 ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      c.time,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: c.unread > 0 ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: c.unread > 0 ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        c.snippet,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: c.unread > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                          fontWeight: c.unread > 0 ? FontWeight.w600 : FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (c.unread > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${c.unread}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                onTap: () {
                  // Phase 2: Navigate to ChatScreen(workerId)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('💬 Chat with ${c.name} — coming in Phase 2!'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChatPreview {
  final String name, snippet, time;
  final int unread;
  final Color avatarColor;
  const _ChatPreview({
    required this.name,
    required this.snippet,
    required this.time,
    required this.unread,
    required this.avatarColor,
  });
}

// ╔══════════════════════════════════════════════════════════════╗
// ║  TAB 2 — ANALYTICS                                          ║
// ╚══════════════════════════════════════════════════════════════╝
class _AnalyticsTab extends StatelessWidget {
  final AsyncValue<List<JobModel>> jobsAsync;
  const _AnalyticsTab({required this.jobsAsync});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: jobsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _analyticsContent(context, [], 0, 0, 0, 0),
        data: (jobs) {
          final active = jobs.where((j) => j.status == JobStatus.active).length;
          final applied = jobs.fold<int>(0, (s, j) => s + j.workersApplied);
          final hired = jobs.fold<int>(0, (s, j) => s + j.workersApplied.clamp(0, j.workersNeeded));
          final today = jobs.where((j) => j.isToday && j.status == JobStatus.active).length;
          return _analyticsContent(context, jobs, active, applied, hired, today);
        },
      ),
    );
  }

  Widget _analyticsContent(BuildContext context, List<JobModel> jobs,
      int active, int applied, int hired, int today) {
    final fillRate = applied > 0 ? (hired / applied * 100).toInt() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Analytics',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Real-time hiring performance',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // Big fill rate dial
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Text(
                'Hiring Fill Rate',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$fillRate%',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: fillRate / 100,
                  minHeight: 10,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF52B788)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$hired hired of $applied applicants',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Stats row
        Row(
          children: [
            _StatTile(label: 'Active Jobs', value: '$active', icon: Icons.work_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            _StatTile(label: 'Today\'s Shifts', value: '$today', icon: Icons.today_rounded, color: const Color(0xFF7C4DFF)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatTile(label: 'Total Applied', value: '$applied', icon: Icons.people_rounded, color: AppColors.accent),
            const SizedBox(width: 12),
            _StatTile(label: 'Workers Hired', value: '$hired', icon: Icons.check_circle_rounded, color: const Color(0xFF2196F3)),
          ],
        ),

        const SizedBox(height: 24),

        // Category breakdown
        if (jobs.isNotEmpty) ...[
          const Text(
            'Jobs by Category',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ..._buildCategoryBars(jobs),
        ],
      ],
    );
  }

  List<Widget> _buildCategoryBars(List<JobModel> jobs) {
    final catMap = <String, int>{};
    for (final j in jobs) {
      final cat = j.category.name;
      catMap[cat] = (catMap[cat] ?? 0) + 1;
    }
    final sorted = catMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final max = sorted.isEmpty ? 1 : sorted.first.value;

    return sorted.take(5).map((e) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  e.key[0].toUpperCase() + e.key.substring(1),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${e.value} job${e.value == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: e.value / max,
                minHeight: 8,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ╔══════════════════════════════════════════════════════════════╗
// ║  TAB 3 — SETTINGS                                           ║
// ╚══════════════════════════════════════════════════════════════╝
class _SettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // Business Profile Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryContainer),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.accentContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'HM',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Himalayan Mart',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Patan Dhoka, Lalitpur',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Notifications
          _SettingsSection(
            title: 'Notifications',
            tiles: [
              _SettingsTile(
                icon: Icons.notifications_active_rounded,
                label: 'Push Notifications',
                color: AppColors.primary,
                trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                  activeColor: AppColors.primary,
                ),
              ),
              _SettingsTile(
                icon: Icons.person_add_rounded,
                label: 'New Applicant Alerts',
                color: const Color(0xFF7C4DFF),
                trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                  activeColor: AppColors.primary,
                ),
              ),
              _SettingsTile(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Message Notifications',
                color: AppColors.accent,
                trailing: Switch(
                  value: false,
                  onChanged: (_) {},
                  activeColor: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Section: Account
          _SettingsSection(
            title: 'Account',
            tiles: [
              _SettingsTile(
                icon: Icons.swap_horiz_rounded,
                label: 'Switch to Worker Mode',
                color: AppColors.accent,
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                onTap: () => context.go('/choose-role'),
              ),
              _SettingsTile(
                icon: Icons.admin_panel_settings_outlined,
                label: 'Admin Panel',
                color: const Color(0xFF2196F3),
                trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.textSecondary),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Admin panel available at /admin'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                color: const Color(0xFFFF9800),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 20),

          // App info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'App Version',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Text(
                        'v1.0.0 • Phase 1',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Supabase Project',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary),
                    ),
                    Text(
                      SupabaseConfig.supabaseUrl.replaceAll('https://', '').split('.').first,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sign out
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/choose-role'),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                'Sign Out / Change Business',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsTile> tiles;

  const _SettingsSection({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: tiles.indexed.map((entry) {
              final (i, tile) = entry;
              return Column(
                children: [
                  tile,
                  if (i < tiles.length - 1)
                    const Divider(height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    );
  }
}
