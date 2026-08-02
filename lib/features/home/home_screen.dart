// ============================================================
// HOME SCREEN — GetWork App
// Interactive Map-First Local Job Discovery Interface
// Matching exact reference design with glassmorphism blur background focus,
// map pins with downward pointers, and interactive map style picker
// ============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../models/job_model.dart';
import '../jobs/jobs_provider.dart';
import 'widgets/category_filter_bar.dart';
import 'widgets/job_bottom_sheet.dart';
import 'widgets/open_street_map_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final MapController _mapController = MapController();
  int _currentNavIndex = 0; // 0: Map, 1: Jobs, 2: Messages, 3: Notifications, 4: Profile
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

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(filteredJobsProvider);
    final selectedJob = ref.watch(selectedJobProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,

      // ── Crisp Bottom Navigation Bar ───────────────────────────
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          onTap: (index) {
            setState(() {
              _currentNavIndex = index;
            });
            if (index == 3) {
              context.push('/notifications');
            } else if (index == 4) {
              context.push('/profile');
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.map_rounded),
              label: 'Map',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.work_outline_rounded),
              label: 'Jobs',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_rounded),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '2',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              label: 'Notifications',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: Stack(
          children: [
            // ── Background: Map or List View ─────────────────────
            _currentNavIndex == 1
                ? _buildListView(jobs)
                : OpenStreetMapWidget(
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

            // ── Top Glassmorphism Dark Shading Backdrop ────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 154,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.55),
                          Colors.black.withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Top Bar Header (Profile Avatar, Search Bar, Notification Bell) ──
            Positioned(
              top: 16,
              left: 14,
              right: 14,
              child: Column(
                children: [
                  Row(
                    children: [
                      // Left: Profile Avatar
                      GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
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
                      const SizedBox(width: 10),

                      // Center: Crisp Pill Search Bar
                      Expanded(
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: AppColors.border, width: 0.8),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadowLight,
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ],
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
                                onPressed: () {
                                  // Open filter
                                },
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Right: Notification Bell
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
                                blurRadius: 10,
                                offset: Offset(0, 3),
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

                  // Category Filter Bar
                  const CategoryFilterBar(),
                ],
              ),
            ),

            // ── Right Floating Map Controls (Location, Layers Selector, Filter) ──
            if (_currentNavIndex == 0 && selectedJob == null)
              Positioned(
                right: 14,
                bottom: 135,
                child: Column(
                  children: [
                    // Location Button
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowMedium,
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.my_location_rounded,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                        onPressed: () {
                          _mapController.move(const LatLng(27.7172, 85.3240), 14.5);
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Map Layer Selector Button (Opens Map Style Picker)
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowMedium,
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.layers_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        onPressed: _showMapStyleSelector,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Green Main Filter Action FAB
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowMedium,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.filter_alt_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () {
                          // Filter action
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // ── Bottom Horizontal Job Carousel ─────────────────
            if (selectedJob == null && _currentNavIndex == 0 && jobs.isNotEmpty)
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
                    separatorBuilder: (context, i) => const SizedBox(width: 10),
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
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 13,
                                    color: AppColors.primary,
                                  ),
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

            // ── GLASSMORPHISM BLUR OVERLAY (Focus mode when Job is selected) ──
            if (selectedJob != null && _currentNavIndex == 0)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    ref.read(selectedJobProvider.notifier).selectJob(null);
                  },
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),

            // ── Job Popup Bottom Sheet (Focus Layer) ────────────────────────
            if (selectedJob != null && _currentNavIndex == 0)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: JobBottomSheet(
                  job: selectedJob,
                  onClose: () {
                    ref.read(selectedJobProvider.notifier).selectJob(null);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List<JobModel> jobs) {
    if (jobs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: AppColors.textHint),
            SizedBox(height: 16),
            Text(
              'No jobs found',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try changing your filter or search terms',
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

    return ListView.separated(
      padding: const EdgeInsets.only(top: 125, bottom: 24, left: 14, right: 14),
      itemCount: jobs.length,
      separatorBuilder: (context, i) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final job = jobs[i];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      job.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      job.salaryDisplay,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  job.businessName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${job.address} (${job.distanceKm ?? 0.5} km)',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () => context.push('/job/${job.id}'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(80, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
              color: isSelected ? AppColors.primaryContainer : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
