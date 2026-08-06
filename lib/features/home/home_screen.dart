// ============================================================
// HOME SCREEN — GetWork App
// Interactive Map-First Local Job Discovery Interface
// ============================================================

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/expanding_label_nav_bar.dart';
import '../../models/job_model.dart';
import '../authentication/choose_role_screen.dart';
import '../jobs/jobs_provider.dart';
import 'widgets/category_filter_bar.dart';
import 'widgets/job_bottom_sheet.dart';
import 'widgets/job_filter_modal.dart';
import 'widgets/open_street_map_widget.dart';
import '../business/chat_provider.dart';
import '../business/chat_screen.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final MapController _mapController = MapController();
  // 0: Map, 1: Jobs, 2: Messages, 3: Profile
  int _currentNavIndex = 0;
  MapStyleType _selectedMapStyle = MapStyleType.street;
  final TextEditingController _searchController = TextEditingController();

  DateTime? _lastBackPressTime;
  LatLng? _currentUserLocation;
  bool _isLoadingLocation = false;
  bool _locationServiceDisabled = false; // drives top inline banner

  bool _isMapInteracting = false;
  Timer? _mapInteractionTimer;

  void _onMapInteractionChanged(bool isInteracting) {
    if (!_isMapInteracting) {
      setState(() => _isMapInteracting = true);
    }
    _mapInteractionTimer?.cancel();
    _mapInteractionTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _isMapInteracting = false);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _requestAndMoveToUserLocation(moveMap: false);
  }

  @override
  void dispose() {
    _mapInteractionTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _requestAndMoveToUserLocation({bool moveMap = true}) async {
    if (_isLoadingLocation) return;
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationServiceDisabled = true;
            _isLoadingLocation = false;
          });
        }
        return;
      }
      // Location is now enabled — clear banner if shown
      if (mounted) setState(() => _locationServiceDisabled = false);

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied.')),
            );
          }
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permissions are permanently denied. Please enable in Settings.'),
              action: SnackBarAction(
                label: 'SETTINGS',
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final userPos = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _currentUserLocation = userPos;
          _isLoadingLocation = false;
        });

        if (moveMap) {
          _mapController.move(userPos, 15.0);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
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
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showHelpDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxHeight: 440),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Help & Support',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w800),
                ),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.email_outlined, color: AppColors.primary),
              title: const Text('Email Support', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
              subtitle: const Text('support@getwork.com.np'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email: support@getwork.com.np'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined, color: AppColors.primary),
              title: const Text('Support Hotline', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
              subtitle: const Text('+977 1-4200000'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(filteredJobsProvider);
    ref.watch(allJobsProvider); // keep provider alive for applied-jobs tab
    final selectedJob = ref.watch(selectedJobProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // 1. Unfocus keyboard if active
        if (FocusScope.of(context).hasFocus) {
          FocusScope.of(context).unfocus();
        }

        // 2. Clear selected job details if open
        if (ref.read(selectedJobProvider) != null) {
          ref.read(selectedJobProvider.notifier).selectJob(null);
          return;
        }

        // 3. Switch back to Map tab if on another tab
        if (_currentNavIndex != 0) {
          setState(() => _currentNavIndex = 0);
          return;
        }

        // 4. Double press back button within 2 seconds to quit app
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit GetWork'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: false,
        drawer: _buildProfileDrawer(context),

        // No bottomNavigationBar — nav is floating inside the Stack

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
                      userLocation: _currentUserLocation,
                      filterDistanceKm: ref.watch(jobFilterProvider).maxDistanceKm,
                      onMapInteractionChanged: _onMapInteractionChanged,
                      onMarkerTap: (job) {
                        FocusScope.of(context).unfocus();
                        ref.read(selectedJobProvider.notifier).selectJob(job);
                        _flyToJob(job);
                      },
                      onMapTap: () {
                        FocusScope.of(context).unfocus();
                        ref.read(selectedJobProvider.notifier).selectJob(null);
                      },
                    ),
                  ),

                  // Bottom Horizontal Job Carousel (Fades out when panning/rotating map)
                  if (selectedJob == null && jobs.isNotEmpty)
                    Positioned(
                      bottom: 104, // raised above floating nav bar
                      left: 0,
                      right: 0,
                      child: AnimatedOpacity(
                        opacity: _isMapInteracting ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: IgnorePointer(
                          ignoring: _isMapInteracting,
                          child: Stack(
                            children: [
                              SizedBox(
                                height: 114,
                                child: ListView.separated(
                                  padding: const EdgeInsets.only(
                                      left: 14, right: 48), // extra right for peek
                                  scrollDirection: Axis.horizontal,
                                  itemCount: jobs.length,
                                  separatorBuilder: (_, idx) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (context, i) {
                                    final job = jobs[i];
                                    return GestureDetector(
                                      onTap: () {
                                        FocusScope.of(context).unfocus();
                                        ref
                                            .read(selectedJobProvider.notifier)
                                            .selectJob(job);
                                        _flyToJob(job);
                                      },
                                      child: Container(
                                        width: 250.w,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12.w, vertical: 8.h),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white,
                                              AppColors.background,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(18.r),
                                          border: Border.all(
                                              color: AppColors.border, width: 0.8),
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
                                                const SizedBox(width: 6),
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
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 5),
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
                          // Right-edge gradient scroll hint
                          Positioned(
                                top: 0,
                                bottom: 0,
                                right: 0,
                                child: IgnorePointer(
                                  child: Container(
                                    width: 40,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.07),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Map Overlay Controls (Positioned above job carousel to avoid overlap)
                  if (selectedJob == null)
                    Positioned(
                      right: 14,
                      bottom: 232, // placed above job carousel (104 + 114 + 14 = 232)
                      child: AnimatedOpacity(
                        opacity: _isMapInteracting ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: IgnorePointer(
                          ignoring: _isMapInteracting,
                          child: Column(
                            children: [
                              _mapControlButton(
                                icon: _isLoadingLocation
                                    ? Icons.sync_rounded
                                    : Icons.my_location_rounded,
                                color: _currentUserLocation != null
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                onTap: () =>
                                    _requestAndMoveToUserLocation(moveMap: true),
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
                      ),
                    ),

                  // ── Blur overlay (Fast animated fade, crash-free) ──────────
                  Positioned.fill(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
                      opacity: selectedJob != null ? 1.0 : 0.0,
                      child: IgnorePointer(
                        ignoring: selectedJob == null,
                        child: GestureDetector(
                          onTap: () => ref
                              .read(selectedJobProvider.notifier)
                              .selectJob(null),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Job detail sheet (Smooth slide-up & slide-down animation) ─────
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      offset: selectedJob != null ? Offset.zero : const Offset(0, 1.3),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: selectedJob != null ? 1.0 : 0.0,
                        child: IgnorePointer(
                          ignoring: selectedJob == null,
                          child: selectedJob != null
                              ? JobBottomSheet(
                                  job: selectedJob,
                                  onClose: () => ref
                                      .read(selectedJobProvider.notifier)
                                      .selectJob(null),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),

                  // Floating header — fast fade when panning map
                  // Floating header — hidden when map is panning OR a job sheet is open
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: AnimatedOpacity(
                      opacity: (_isMapInteracting || selectedJob != null) ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 120),
                      child: IgnorePointer(
                        ignoring: _isMapInteracting || selectedJob != null,
                        child: _buildTopHeader(topPadding),
                      ),
                    ),
                  ),

                  // ── Location Services Disabled — Top Inline Banner ───────
                  if (_locationServiceDisabled && selectedJob == null)
                    Positioned(
                      top: topPadding + 130, // below header
                      left: 14,
                      right: 14,
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3CD),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFCA28), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_off_rounded,
                                  color: Color(0xFFE65100), size: 20),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Location services are disabled on your phone.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF5D4037),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () async {
                                  await Geolocator.openLocationSettings();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'SETTINGS',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // ── Floating Pill Navigation Bar ─────────────────
                  if (selectedJob == null)
                    Positioned(
                      bottom: 16,
                      left: 20,
                      right: 20,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOutCubic,
                        offset: _isMapInteracting
                            ? const Offset(0, 1.6)
                            : Offset.zero,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 120),
                          opacity: _isMapInteracting ? 0.0 : 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 24,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                              border: Border.all(
                                color: AppColors.border,
                                width: 0.8,
                              ),
                            ),
                            child: ExpandingLabelNavBar(
                              currentIndex: _currentNavIndex,
                              onTap: (index) {
                                FocusScope.of(context).unfocus();
                                setState(() => _currentNavIndex = index);
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
                                  icon: Icons.assignment_outlined,
                                  selectedIcon: Icons.assignment_rounded,
                                  label: 'Applied',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              )
          // ── NON-MAP TABS: standard Scaffold column, NO floating header ───
          : _buildTabScaffold(topPadding, jobs),
      ),
    );
  }

  // ── Non-map tabs share this scaffold (no floating map header) ────────────
  Widget _buildTabScaffold(double topPadding, List<JobModel> jobs) {
    final titles = ['', 'Nearby Jobs', 'Messages', 'Applied'];
    return Stack(
      children: [
        Column(
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
                        decoration: const InputDecoration(
                          hintText: 'Search jobs, category or place',
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppColors.textHint,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const CategoryFilterBar(),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80), // space for floating nav
                child: _currentNavIndex == 1
                    ? _buildJobsTab(jobs)
                    : _currentNavIndex == 2
                        ? _buildMessagesTab()
                        : _buildProfilePlaceholder(),
              ),
            ),
          ],
        ),

        // ── Floating Pill Nav for non-map tabs ───────────────
        Positioned(
          bottom: 16,
          left: 20,
          right: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: ExpandingLabelNavBar(
              currentIndex: _currentNavIndex,
              onTap: (index) {
                FocusScope.of(context).unfocus();
                setState(() => _currentNavIndex = index);
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
                  icon: Icons.assignment_outlined,
                  selectedIcon: Icons.assignment_rounded,
                  label: 'Applied',
                ),
              ],
            ),
          ),
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
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
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
                    decoration: const InputDecoration(
                      hintText: 'Search jobs, category or place',
                      hintStyle: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textHint,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 11),
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

  // ── Role Switch Dialog ─────────────────────────────────
  void _showRoleSwitchDialog(BuildContext context, UserRole targetRole) {
    final isWorkerTarget = targetRole == UserRole.worker;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isWorkerTarget ? Icons.handyman_rounded : Icons.storefront_rounded,
              color: isWorkerTarget ? AppColors.primary : AppColors.accent,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              isWorkerTarget ? 'Switch to Worker Mode' : 'Switch to Business Mode',
              style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          isWorkerTarget
              ? 'Worker Mode lets you browse the job map, discover shifts near you, and apply with one tap. Your applications and chat history stay separate from business activity.'
              : 'Business Mode lets you post jobs, view applicants, and manage your hiring. Switch back to Worker Mode any time to look for shifts yourself.',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Inter')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pop(); // close drawer
              ref.read(userRoleProvider.notifier).setRole(targetRole);
              if (targetRole == UserRole.business) {
                context.go('/business');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isWorkerTarget ? AppColors.primary : AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              isWorkerTarget ? 'Switch to Worker' : 'Switch to Business',
              style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ── Side Profile Drawer ────────────────────────────────────────────
  Widget _buildProfileDrawer(BuildContext context) {
    final role = ref.watch(userRoleProvider);
    final isWorker = role != UserRole.business;
    final appliedCount = ref.watch(appliedJobsProvider).length;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.78,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header with Rich 3-Stop Gradient ────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F5132),
                    Color(0xFF0D9488),
                    Color(0xFF14B8A6),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar circle with app logo
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, st) => const Icon(
                          Icons.person_rounded,
                          size: 36,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'GetWork User',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'user@getwork.app',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Role badge gradient pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isWorker
                            ? [const Color(0xFF2563EB), const Color(0xFF1D4ED8)]
                            : [const Color(0xFFF97316), const Color(0xFFEA580C)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isWorker ? Icons.handyman_rounded : Icons.storefront_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isWorker ? 'Worker Mode' : 'Business Mode',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Stats Row with Vector Icons & Glassmorphic Gradient ──
                  Row(
                    children: [
                      _statBadge(Icons.work_history_rounded, '$appliedCount', 'Applied'),
                      const SizedBox(width: 10),
                      _statBadge(Icons.star_rounded, '4.8', 'Rating'),
                      const SizedBox(width: 10),
                      _statBadge(Icons.verified_user_rounded, '0', 'Hired'),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.border),

            // ── Menu Items ─────────────────────────────
            _drawerItem(Icons.person_outline_rounded, 'My Profile', () {
              Navigator.of(context).pop();
              context.push('/profile');
            }),
            _drawerItem(Icons.assignment_outlined, 'My Applications', () {
              Navigator.of(context).pop();
              setState(() => _currentNavIndex = 3);
            }),
            // Switch Mode — intentional, with explanation
            if (isWorker)
              _drawerItem(Icons.storefront_rounded, 'Switch to Business Mode', () {
                _showRoleSwitchDialog(context, UserRole.business);
              }, color: AppColors.accent)
            else
              _drawerItem(Icons.handyman_rounded, 'Switch to Worker Mode', () {
                _showRoleSwitchDialog(context, UserRole.worker);
              }, color: AppColors.primary),
            _drawerItem(Icons.settings_outlined, 'Settings', () {
              Navigator.of(context).pop();
              context.push('/settings');
            }),
            _drawerItem(Icons.help_outline_rounded, 'Help & Support', () {
              Navigator.of(context).pop();
              _showHelpDialog();
            }),

            const Spacer(),

            const Divider(height: 1, color: AppColors.border),
            _drawerItem(Icons.logout_rounded, 'Sign Out', () {
              Navigator.of(context).pop();
              context.go('/');
            }, color: Colors.red),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ── Stats badge with vector icons & glassmorphic gradient backdrop ──
  Widget _statBadge(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.22),
              Colors.white.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.0),
      duration: const Duration(milliseconds: 120),
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: child,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: (color ?? AppColors.primary).withValues(alpha: 0.08),
          highlightColor: (color ?? AppColors.primary).withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (color ?? AppColors.primary).withValues(alpha: 0.12),
                        (color ?? AppColors.primary).withValues(alpha: 0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: color ?? AppColors.textPrimary),
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color ?? AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: (color ?? AppColors.textHint).withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
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
                            // Urgent tag with gradient
                            if (job.isUrgent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF6B35), Color(0xFFE53935)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.local_fire_department_rounded,
                                        size: 12, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'Urgent',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
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

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Just now';
  }

  Widget _buildMessagesTab() {
    final convsAsync = ref.watch(conversationsProvider);

    return convsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppColors.textSecondary, size: 40),
            const SizedBox(height: 12),
            Text(
              'Could not load messages: $e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.read(conversationsProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (convs) {
        if (convs.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 64, color: AppColors.textHint),
                  SizedBox(height: 16),
                  Text(
                    'No Messages Yet',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Chat with employers by tapping "Chat" on any job listing!',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(conversationsProvider.notifier).refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: convs.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 68),
            itemBuilder: (context, i) {
              final c = convs[i];
              final isSystem = c.isSystem;
              final avatarColor = isSystem
                  ? AppColors.primary
                  : [
                      AppColors.accent,
                      const Color(0xFF7C4DFF),
                      const Color(0xFFFF5722),
                      const Color(0xFF2196F3)
                    ][i % 4];

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: avatarColor.withValues(alpha: 0.15),
                      child: Text(
                        isSystem
                            ? 'G'
                            : (c.businessName.isNotEmpty
                                ? c.businessName.substring(0, 1).toUpperCase()
                                : 'B'),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w800,
                          color: avatarColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (isSystem)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded,
                              size: 9, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        isSystem ? 'GetWork System' : c.businessName,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: c.unreadCount > 0
                              ? FontWeight.w800
                              : FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatTimeAgo(c.lastMessageAt),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: c.unreadCount > 0
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: c.unreadCount > 0
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: c.unreadCount > 0
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: c.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (c.unreadCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            '${c.unreadCount}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        conversationId: c.id,
                        workerName: isSystem ? 'GetWork' : c.businessName,
                        workerPhone: c.workerPhone,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProfilePlaceholder() {
    final appliedJobIds = ref.watch(appliedJobsProvider);
    final autoAppliedJobIds = ref.watch(autoAppliedJobsProvider);
    final allJobs = ref.watch(allJobsProvider).asData?.value ?? [];

    // Filter jobs the user has applied to
    final appliedJobs = allJobs
        .where((j) => appliedJobIds.contains(j.id))
        .toList();

    return Column(
      children: [
        // ── Sub-header ────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${appliedJobs.length} / 6 Applied',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'Auto-cancels rest when 1 hired',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 0.8, color: AppColors.divider),

        // ── Body ──────────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // ── Auto-Apply Form / Engine Card ────────────────────────
              _buildAutoApplyFormCard(allJobs, appliedJobIds.length),

              const SizedBox(height: 16),

              if (appliedJobs.isNotEmpty) ...[
                Row(
                  children: [
                    const Text(
                      'Active Applications',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        ref.read(appliedJobsProvider.notifier).clearAll();
                        ref.read(autoAppliedJobsProvider.notifier).clearAll();
                      },
                      child: const Text(
                        'Clear All',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...appliedJobs.map((job) {
                  final isAuto = autoAppliedJobIds.contains(job.id);
                  return _buildAppliedJobCard(job, isAuto);
                }),
              ] else
                _buildEmptyApplied(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Smart Apply Card ──────────────────────────────────────────────
  Widget _buildAutoApplyFormCard(List<JobModel> allJobs, int currentAppliedCount) {
    final remainingSlots = 6 - currentAppliedCount;
    final topJobs = allJobs
        .where((j) => !ref.read(appliedJobsProvider).contains(j.id))
        .take(6)
        .toList();
    final canSmartApply = remainingSlots > 0 && topJobs.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.amber,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Apply',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Review top matches and choose which to apply.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$remainingSlots left',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),

          // Info note
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline_rounded, color: Colors.white70, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You pick which jobs to apply to. Each application is your explicit choice — employers can then reach you via chat.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // CTA Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: canSmartApply
                  ? () => _showSmartApplySheet(topJobs)
                  : null,
              icon: const Icon(Icons.checklist_rounded, size: 18),
              label: Text(
                remainingSlots <= 0
                    ? '6 Applications Active (Limit Reached)'
                    : topJobs.isEmpty
                        ? 'No New Jobs Available'
                        : 'Review & Apply to Jobs →',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1E3A5F),
                disabledBackgroundColor: Colors.white38,
                disabledForegroundColor: Colors.white70,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Smart Apply Bottom Sheet ──────────────────────────────────────
  void _showSmartApplySheet(List<JobModel> topJobs) {
    final selected = <String>{};
    for (final j in topJobs) {
      selected.add(j.id); // all pre-selected by default
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.82,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
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
                  const SizedBox(height: 20),
                  // Header
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose Jobs to Apply',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Review each job below and uncheck any you don\'t want.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  // Job List
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: topJobs.length,
                      itemBuilder: (_, i) {
                        final job = topJobs[i];
                        final isChecked = selected.contains(job.id);
                        return CheckboxListTile(
                          value: isChecked,
                          activeColor: AppColors.primary,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 4),
                          title: Text(
                            job.title,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            '${job.businessName} • ${job.salaryDisplay} • ${job.address}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          onChanged: (val) {
                            setSheetState(() {
                              if (val == true) {
                                selected.add(job.id);
                              } else {
                                selected.remove(job.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: selected.isEmpty
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              for (final id in selected) {
                                ref
                                    .read(appliedJobsProvider.notifier)
                                    .applyToJob(id);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.primaryDark,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  content: Text(
                                    '✅ Applied to ${selected.length} job${selected.length == 1 ? '' : 's'}! Employers will contact you via chat.',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        selected.isEmpty
                            ? 'Select at least one job'
                            : 'Apply to ${selected.length} Selected Job${selected.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyApplied() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Active Applications',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap "Auto-Apply to 6 Jobs Now" above to apply automatically!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppliedJobCard(JobModel job, bool isAutoApplied) {
    return _AnimatedJobCard(
      index: 0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAutoApplied
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.border,
            width: isAutoApplied ? 1.2 : 0.8,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Job Info Row ────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        job.businessName.isNotEmpty
                            ? job.businessName[0].toUpperCase()
                            : 'B',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
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
                            Expanded(
                              child: Text(
                                job.title,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isAutoApplied)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accentContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.bolt_rounded,
                                        size: 11, color: AppColors.accent),
                                    SizedBox(width: 2),
                                    Text(
                                      'Auto',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ],
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
                            // Salary pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                job.salaryDisplay,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Status pill — pending
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '⏳ Pending',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFD97706),
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

            // ── Divider + Action Row ─────────────────────────
            const Divider(
                height: 1,
                thickness: 0.8,
                indent: 14,
                endIndent: 14,
                color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  // View job button
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => context.push('/job/${job.id}'),
                      icon: const Icon(Icons.open_in_new_rounded, size: 15),
                      label: const Text('View'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        textStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Got the Job button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _onGotTheJob(job.id, job.title),
                      icon: const Icon(Icons.celebration_rounded, size: 15),
                      label: const Text('Got the Job!'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
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

  void _onGotTheJob(String jobId, String jobTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Congratulations!',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'You got the job at $jobTitle! Your other pending applications will be automatically removed.',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(appliedJobsProvider.notifier).gotTheJob(jobId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Awesome! Other applications removed.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Confirm'),
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
