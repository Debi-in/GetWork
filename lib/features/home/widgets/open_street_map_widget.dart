// ============================================================
// OPEN STREET MAP WIDGET — GetWork App
// Renders Kathmandu map via flutter_map + multi-style tiles
// Features smooth staggered entrance animations on job markers
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../core/constants/app_colors.dart';
import '../../../models/job_model.dart';

enum MapStyleType { street, satellite, lightGray }

// ── Animated single marker wrapper ───────────────────────────
class _AnimatedMarkerWidget extends StatefulWidget {
  final JobModel job;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;

  const _AnimatedMarkerWidget({
    super.key,
    required this.job,
    required this.isSelected,
    required this.onTap,
    required this.index,
  });

  @override
  State<_AnimatedMarkerWidget> createState() => _AnimatedMarkerWidgetState();
}

class _AnimatedMarkerWidgetState extends State<_AnimatedMarkerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  // Track already animated job IDs so panning/zooming map doesn't re-play animation
  static final Set<String> _animatedJobIds = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // If marker already animated, set to 1.0 instantly so dragging map doesn't re-trigger
    if (_animatedJobIds.contains(widget.job.id)) {
      _controller.value = 1.0;
    } else {
      _animatedJobIds.add(widget.job.id);
      Future.delayed(Duration(milliseconds: widget.index * 60), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: widget.onTap,
          child: _MarkerCalloutPin(
            job: widget.job,
            isSelected: widget.isSelected,
          ),
        ),
      ),
    );
  }
}

// ── Main Map Widget ───────────────────────────────────────────
class OpenStreetMapWidget extends StatelessWidget {
  final List<JobModel> jobs;
  final JobModel? selectedJob;
  final MapController? mapController;
  final MapStyleType mapStyle;
  final LatLng? userLocation;
  final double filterDistanceKm;
  final void Function(JobModel job) onMarkerTap;
  final VoidCallback onMapTap;
  final void Function(bool isInteracting)? onMapInteractionChanged;

  const OpenStreetMapWidget({
    super.key,
    required this.jobs,
    required this.selectedJob,
    this.mapController,
    this.mapStyle = MapStyleType.street,
    this.userLocation,
    this.filterDistanceKm = 25.0,
    required this.onMarkerTap,
    required this.onMapTap,
    this.onMapInteractionChanged,
  });

  // Kathmandu default centre
  static const LatLng kathmanduCenter = LatLng(27.7172, 85.3240);

  String get _tileUrl {
    switch (mapStyle) {
      case MapStyleType.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapStyleType.lightGray:
        return 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
      case MapStyleType.street:
        return 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
    }
  }

  /// Calculates offsets for markers that share the same or very close coordinates
  List<Marker> _buildSpiderfiedMarkers() {
    final Map<String, List<int>> locationClusters = {};

    // Group jobs by location key (rounded to ~30 meters precision)
    for (int i = 0; i < jobs.length; i++) {
      final job = jobs[i];
      final key = '${(job.latitude * 1000).round()},${(job.longitude * 1000).round()}';
      locationClusters.putIfAbsent(key, () => []).add(i);
    }

    final List<Marker> markers = [];

    // Render User Location Pin first if active
    if (userLocation != null) {
      markers.add(
        Marker(
          point: userLocation!,
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0x332563EB),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2563EB), width: 2),
            ),
            child: Center(
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Build job markers with fan-out spiderfy offset for overlapping markers
    for (int i = 0; i < jobs.length; i++) {
      final job = jobs[i];
      final key = '${(job.latitude * 1000).round()},${(job.longitude * 1000).round()}';
      final cluster = locationClusters[key] ?? [i];

      double lat = job.latitude;
      double lng = job.longitude;

      if (cluster.length > 1) {
        final indexInCluster = cluster.indexOf(i);
        final angle = (2 * math.pi * indexInCluster) / cluster.length;
        const radius = 0.0008; // ~90m spread for clear visual separation
        lat += radius * math.sin(angle);
        lng += radius * math.cos(angle);
      }

      final isSelected = selectedJob?.id == job.id;
      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 140,
          height: 72,
          alignment: Alignment.topCenter,
          child: _AnimatedMarkerWidget(
            key: ValueKey(job.id),
            job: job,
            isSelected: isSelected,
            onTap: () => onMarkerTap(job),
            index: i,
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: userLocation ?? kathmanduCenter,
        initialZoom: 13.5,
        minZoom: 10,
        maxZoom: 18,
        onTap: (_, _) => onMapTap(),
        onPositionChanged: (position, hasGesture) {
          if (hasGesture && onMapInteractionChanged != null) {
            onMapInteractionChanged!(true);
          }
        },
      ),
      children: [
        // ── Map Tile Layer ────────────────────────────────────
        TileLayer(
          urlTemplate: _tileUrl,
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.getwork.app',
          maxZoom: 19,
        ),

        // ── Dynamic Location Filter Distance Range Circle ────
        if (userLocation != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: userLocation!,
                radius: filterDistanceKm * 1000, // radius in meters
                useRadiusInMeter: true,
                color: AppColors.primary.withValues(alpha: 0.08),
                borderColor: AppColors.primary.withValues(alpha: 0.35),
                borderStrokeWidth: 1.5,
              ),
            ],
          ),

        // ── Job Markers & User Location Marker ───────────────
        MarkerLayer(
          markers: _buildSpiderfiedMarkers(),
        ),
      ],
    );
  }
}


// ── Callout Pin Bubble with Downward Arrow Tip ────────────────
class _MarkerCalloutPin extends StatelessWidget {
  final JobModel job;
  final bool isSelected;

  const _MarkerCalloutPin({
    required this.job,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected
        ? AppColors.accent
        : job.isUrgent
            ? AppColors.accent
            : AppColors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bubble Body
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white,
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: bgColor.withValues(alpha: 0.45),
                blurRadius: isSelected ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                job.salaryDisplay,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                job.title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Downward Triangle Arrow Pointer Tip
        CustomPaint(
          size: const Size(12, 7),
          painter: _TrianglePointerPainter(color: bgColor),
        ),
      ],
    );
  }
}

// ── Triangle Pointer Painter for Pin Tip ─────────────────────
class _TrianglePointerPainter extends CustomPainter {
  final Color color;

  _TrianglePointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final borderPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePointerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
