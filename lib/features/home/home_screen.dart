// ============================================================
// HOME SCREEN — GetWork App
// Interactive Map-First Local Job Discovery Interface
// ============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/expanding_label_nav_bar.dart';
import '../../models/job_model.dart';
import '../jobs/jobs_provider.dart';
import 'widgets/category_filter_bar.dart';
import 'widgets/job_bottom_sheet.dart';
import 'widgets/job_filter_modal.dart';
import 'widgets/open_street_map_widget.dart';

// ── Category color helper ─────────────────────────────────────
Color _categoryColor(JobCategory cat) {
  switch (cat) {
    case JobCategory.delivery:  return AppColors.categoryDelivery;
    case JobCategory.retail:    return AppColors.categoryRetail;
    case JobCategory.food:      return AppColors.categoryFood;
    case JobCategory.construction: return AppColors.categoryConstruction;
    case JobCategory.cleaning:  return AppColors.categoryCleaning;
    case JobCategory.tech:      return AppColors.categoryTech;
    case JobCategory.events:    return AppColors.categoryEvents;
    default:                    return AppColors.primary;
  }
}

String _categoryLabel(JobCategory cat) {
  switch (cat) {
    case JobCategory.delivery:  return 'Delivery';
    case JobCategory.retail:    return 'Retail';
    case JobCategory.food:      return 'Food';
    case JobCategory.construction: return 'Construction';
    case JobCategory.cleaning:  return 'Cleaning';
    case JobCategory.tech:      return 'Tech';
    case JobCategory.events:    return 'Events';
    default:                    return 'All';
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final MapController _mapController = MapController();
  // 0: Map, 1: Jobs, 2: Messages, 3: Profile  (Notifications removed — it's in top bell)
  int _currentNavIndex = 0;
  MapStyleType _selectedMapStyle = MapStyleType.street;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _flyToJob(JobModel job) {
    _mapController.move(LatLng(job.latitude, job.longitude), 15.0);
  }

  void _showMapStyleSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Map Style',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MapStyleOption(
                    title: 'Street',
                    icon: Icons.map_rounded,
                    isSelected: _selectedMapStyle == MapStyleType.street,
                    onTap: () {
                      setState(() => _selectedMapStyle = MapStyleType.street);
                      Navigator.pop(context);
                    },
                  ),
                  _MapStyleOption(
                    title: 'Satellite',
                    icon: Icons.satellite_alt_rounded,
                    isSelected: _selectedMapStyle == MapStyleType.satellite,
                    onTap: () {
                      setState(() => _selectedMapStyle = MapStyleType.satellite);
                      Navigator.pop(context);
                    },
                  ),
                  _MapStyleOption(
                    title: 'Muted Light',
                    icon: Icons.wb_sunny_outlined,
                    isSelected: _selectedMapStyle == MapStyleType.lightGray,
                    onTap: () {
                      setState(() => _selectedMapStyle = MapStyleType.lightGray);
                      Navigator.pop(context);
                    },
                  ),
                  _MapStyleOption(
                    title: 'Terrain',
                    icon: Icons.terrain_rounded,
                    isSelected: _selectedMapStyle == MapStyleType.terrain,
                    onTap: () {
                      setState(() => _selectedMapStyle = MapStyleType.terrain);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ── Top header height constant so other widgets can use it for padding ──
  static const double _headerHeight = 118.0;

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(filteredJobsProvider);
    final selectedJob = ref.watch(selectedJobProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,

      // ── Expanding Label Navigation Bar — Purple Theme ─────────────
      bottomNavigationBar: ExpandingLabelNavBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
          if (index == 3) {
            context.push('/profile');
          }
        },
        items: const [
          NavItemData(
            icon: Icons.map_outlined,
            selectedIcon: Icons.map_rounded,
            label: 'Map',
          ),
          NavItemData(
            icon: Icons.work_outline_rounded,
            selectedIcon: Icons.work_rounded,
            label: 'Jobs',
          ),
          NavItemData(
            icon: Icons.chat_bubble_outline_rounded,
            selectedIcon: Icons.chat_bubble_rounded,
            label: 'Messages',
          ),
          NavItemData(
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),

      body: _currentNavIndex == 0
          // ── MAP TAB: full-screen Stack with floating header ──────────────
          ? Stack(
              children: [
                // Map fills the entire screen behind the floating header
                Positioned.fill(
                  child: OpenStreetMapWidget(
                    jobs: jobs,
                    selectedJob: selectedJob,
                    mapController: _mapController,
                    mapStyle: _selectedMapStyle,
                    onMarkerTap: (job) {
                      ref.read(selectedJobProvider.notifier).selectJob(job);
                      _flyToJob(job);
                    },
                    onMapTap: () {
                      ref.read(selectedJobProvider.notifier).selectJob(null);
                    },
                  ),
                ),

                // Map Overlay Controls
                if (selectedJob == null)
                  Positioned(
                    right: 14,
                    bottom: 120,
                    child: Column(
                      children: [
                        _mapControlButton(
                          icon: Icons.my_location_rounded,
                          color: AppColors.textPrimary,
                          onTap: () =>
                              _mapController.move(const LatLng(27.7172, 85.3240), 14.5),
                        ),
                        const SizedBox(height: 10),
                        _mapControlButton(
                          icon: Icons.layers_outlined,
                          color: AppColors.primary,
                          onTap: _showMapStyleSelector,
                        ),
                        const SizedBox(height: 10),
                        _mapControlButton(
                          icon: Icons.filter_alt_rounded,
                          color: Colors.white,
                          bgColor: AppColors.primary,
                          size: 48,
                          onTap: () => JobFilterModal.show(context),
                        ),
                      ],
                    ),
                  ),

                // Bottom Horizontal Job Carousel
                if (selectedJob == null && jobs.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      height: 106,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        scrollDirection: Axis.horizontal,
                        itemCount: jobs.length,
                        separatorBuilder: (_, idx) => const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          final job = jobs[i];
                          return GestureDetector(
                            onTap: () {
                              ref.read(selectedJobProvider.notifier).selectJob(job);
                              _flyToJob(job);
                            },
                            child: Container(
                              width: 250,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.border, width: 0.8),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.shadowMedium,
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          job.title,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        job.salaryDisplay,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    job.businessName,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined,
                                          size: 13, color: AppColors.primary),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          '${job.distanceKm ?? 0.5} km • ${job.address}',
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // Blur overlay when a job is selected
                if (selectedJob != null)
                  Positioned(
                    top: topPadding + _headerHeight,
                    left: 0, right: 0, bottom: 0,
                    child: GestureDetector(
                      onTap: () =>
                          ref.read(selectedJobProvider.notifier).selectJob(null),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.30),
                        ),
                      ),
                    ),
                  ),

                // Job detail bottom sheet
                if (selectedJob != null)
                  Positioned(
                    bottom: 12, left: 0, right: 0,
                    child: JobBottomSheet(
                      job: selectedJob,
                      onClose: () =>
                          ref.read(selectedJobProvider.notifier).selectJob(null),
                    ),
                  ),

                // Floating header — drawn last, always on top
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: _buildTopHeader(topPadding),
                ),
              ],
            )
          // ── NON-MAP TABS: standard Scaffold column, NO floating header ───
          : _buildTabScaffold(topPadding, jobs),
    );
  }

  // ── Non-map tabs share this scaffold (no floating map header) ────────────
  Widget _buildTabScaffold(double topPadding, List<JobModel> jobs) {
    final titles = ['', 'Nearby Jobs', 'Messages', 'Profile'];
    return Column(
      children: [
        // Branded app bar for non-map tabs
        Container(
          padding: EdgeInsets.only(
            top: topPadding + 8,
            left: 16,
            right: 16,
            bottom: 12,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    titles[_currentNavIndex],
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (_currentNavIndex == 1)
                    GestureDetector(
                      onTap: () => context.push('/notifications'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
              if (_currentNavIndex == 1) ...[
                const SizedBox(height: 12),
                // Search bar inside Jobs Tab
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      ref.read(searchQueryProvider.notifier).setQuery(val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search jobs, category or place',
                      hintStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textHint,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.tune_rounded,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                        onPressed: () => JobFilterModal.show(context),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Expanding Category Pills Bar
                const CategoryFilterBar(),
              ],
            ],
          ),
        ),
        Expanded(
          child: _currentNavIndex == 1
              ? _buildJobsTab(jobs)
              : _currentNavIndex == 2
                  ? _buildMessagesPlaceholder()
                  : _buildProfilePlaceholder(),
        ),
      ],
    );
  }

  // ── Top Header: Profile Avatar + Search Bar + Bell + Category Pills ──────
  Widget _buildTopHeader(double topPadding) {
    return Container(
      // Fully transparent — map shows through completely
      color: Colors.transparent,
      padding: EdgeInsets.only(
        top: topPadding + 10,
        left: 14,
        right: 14,
        bottom: 10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row: Avatar | Search | Bell
          Row(
            children: [
              // Left: App Logo / Profile Avatar
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 0.8),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowLight,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.primary,
                        child: const Center(
                          child: Text(
                            'DR',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Center: Pill Search Bar
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.border, width: 0.8),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowLight,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      ref
                          .read(searchQueryProvider.notifier)
                          .setQuery(val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search jobs, category or place',
                      hintStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textHint,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.tune_rounded,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                        onPressed: () => JobFilterModal.show(context),
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Right: Notification Bell (replaces removed bottom tab)
              GestureDetector(
                onTap: () => context.push('/notifications'),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 0.8),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowLight,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                      Positioned(
                        top: 9,
                        right: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Horizontally Scrollable Category Filter Pills
          const CategoryFilterBar(),
        ],
      ),
    );
  }

  Widget _mapControlButton({
    required IconData icon,
    required Color color,
    Color bgColor = Colors.white,
    double size = 42,
    required VoidCallback onTap,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }

  // ── Premium Jobs Tab ──────────────────────────────────────────────────────
  Widget _buildJobsTab(List<JobModel> jobs) {
    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.work_off_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Jobs Found',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your filters or search',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: jobs.length + 1,
      itemBuilder: (context, i) {
        // ── Header row: results count + sort ──
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Text(
                  '${jobs.length} results found',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border, width: 1),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowLight,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: const [
                        Text(
                          'RELEVANCE',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.4,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            size: 16, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final job = jobs[i - 1];
        final catColor = _categoryColor(job.category);
        final catLabel = _categoryLabel(job.category);

        return _AnimatedJobCard(
          index: i - 1,
          child: GestureDetector(
            onTap: () => context.push('/job/${job.id}'),
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Left: Square Business Avatar ──
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: catColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: job.businessLogoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              job.businessLogoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, e, st) => _avatarFallback(
                                  job.businessName, catColor),
                            ),
                          )
                        : _avatarFallback(job.businessName, catColor),
                  ),
                  const SizedBox(width: 14),

                  // ── Right: All Content ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top: Title + Chevron
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                job.title,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 13,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Business • Location
                        Text(
                          '${job.businessName} • ${job.address}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // Rating + Distance row
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 14, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 3),
                            const Text(
                              '4.8',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              ' (128)',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: AppColors.textHint,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.location_on_rounded,
                                size: 13, color: AppColors.primary),
                            const SizedBox(width: 2),
                            Text(
                              '${job.distanceKm ?? 0.5} km',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (job.isToday) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.successLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Today',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Bottom: Salary pill + Tags
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            // Green salary pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                job.salaryDisplay,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ),
                            // Category tag
                            _tagPill(catLabel, catColor),
                            // Shift time tag
                            _tagPill(
                              '${job.shiftStartTime}–${job.shiftEndTime}',
                              AppColors.textHint,
                            ),
                            // Urgent tag
                            if (job.isUrgent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accentContainer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  '🔥 Urgent',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                  ),
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
      },
    );
  }

  // ── Avatar fallback widget ───────────────────────────────────────────────
  Widget _avatarFallback(String name, Color color) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'B',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  // ── Small tag pill ───────────────────────────────────────────────────────
  Widget _tagPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  Widget _buildMessagesPlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 64, color: AppColors.textHint),
          SizedBox(height: 16),
          Text(
            'Messages',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your conversations will appear here',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline_rounded,
              size: 64, color: AppColors.textHint),
          SizedBox(height: 16),
          Text(
            'Profile',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Manage your profile & settings',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated Job Card — staggered slide-up + fade entrance ───────────────────
class _AnimatedJobCard extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedJobCard({required this.index, required this.child});

  @override
  State<_AnimatedJobCard> createState() => _AnimatedJobCardState();
}

class _AnimatedJobCardState extends State<_AnimatedJobCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    // Stagger each card by 60ms
    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ── Map Style Option Pill ─────────────────────────────────────
class _MapStyleOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MapStyleOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryContainer
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color:
                  isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w500,
              color:
                  isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
