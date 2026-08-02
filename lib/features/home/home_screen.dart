// ============================================================
// HOME SCREEN — GetWork App
// Interactive Map-First Local Job Discovery Interface
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../models/job_model.dart';
import '../jobs/jobs_provider.dart';
import 'widgets/category_filter_bar.dart';
import 'widgets/job_bottom_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GoogleMapController? _mapController;
  bool _isListView = false;
  final TextEditingController _searchController = TextEditingController();

  // Kathmandu default location
  static const LatLng _kathmanduCenter = LatLng(27.7172, 85.3240);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers(List<JobModel> jobs) {
    final selectedJob = ref.watch(selectedJobProvider);

    return jobs.map((job) {
      final isSelected = selectedJob?.id == job.id;

      return Marker(
        markerId: MarkerId(job.id),
        position: LatLng(job.latitude, job.longitude),
        icon: isSelected
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: job.title,
          snippet: '${job.salaryDisplay} • ${job.businessName}',
        ),
        onTap: () {
          ref.read(selectedJobProvider.notifier).selectJob(job);
        },
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(filteredJobsProvider);
    final selectedJob = ref.watch(selectedJobProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Background: Map or List View ─────────────────────
            _isListView
                ? _buildListView(jobs)
                : _buildMapView(jobs),

            // ── Top Header & Filter Controls ──────────────────────
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  // Top bar with Search & View Toggle
                  Row(
                    children: [
                      // Search Bar
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadowLight,
                                blurRadius: 12,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              ref.read(searchQueryProvider.notifier).setQuery(val);
                            },
                            decoration: InputDecoration(
                              hintText: 'Search jobs, locations...',
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: AppColors.primary,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref.read(searchQueryProvider.notifier).setQuery('');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Map / List Toggle Button
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadowLight,
                              blurRadius: 12,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isListView ? Icons.map_rounded : Icons.format_list_bulleted_rounded,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            setState(() {
                              _isListView = !_isListView;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Category Filter Bar
                  const CategoryFilterBar(),
                ],
              ),
            ),

            // ── Floating Action Buttons (Profile & Business) ──────
            Positioned(
              top: 130,
              right: 16,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'profileBtn',
                    onPressed: () => context.push('/profile'),
                    backgroundColor: AppColors.surface,
                    child: const Icon(Icons.person_outline_rounded, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'businessBtn',
                    onPressed: () => context.push('/business'),
                    backgroundColor: AppColors.accent,
                    child: const Icon(Icons.business_center_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),

            // ── Bottom Sheet for Selected Job ────────────────────
            if (selectedJob != null)
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

            // ── Bottom Job Quick Cards Horizontal Carousel (When no single job selected & Map Mode) ──
            if (selectedJob == null && !_isListView && jobs.isNotEmpty)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 110,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: jobs.length,
                    separatorBuilder: (context, i) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final job = jobs[i];
                      return GestureDetector(
                        onTap: () {
                          ref.read(selectedJobProvider.notifier).selectJob(job);
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLngZoom(
                              LatLng(job.latitude, job.longitude),
                              15,
                            ),
                          );
                        },
                        child: Container(
                          width: 260,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadowMedium,
                                blurRadius: 16,
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
                              const SizedBox(height: 4),
                              Text(
                                job.businessName,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 12,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${job.distanceKm ?? 0.5} km • ${job.address}',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
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
          ],
        ),
      ),
    );
  }

  Widget _buildMapView(List<JobModel> jobs) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: _kathmanduCenter,
        zoom: 13.5,
      ),
      markers: _buildMarkers(jobs),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
      },
      onTap: (_) {
        ref.read(selectedJobProvider.notifier).selectJob(null);
      },
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
      padding: const EdgeInsets.only(top: 130, bottom: 24, left: 16, right: 16),
      itemCount: jobs.length,
      separatorBuilder: (context, i) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final job = jobs[i];
        return Card(
          margin: EdgeInsets.zero,
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
