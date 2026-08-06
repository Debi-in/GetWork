// ============================================================
// OPEN STREET MAP WIDGET — GetWork App
// Renders Kathmandu map via flutter_map + multi-style tiles
// Features zoom-aware clustering:
//   • Zoom < 14  → cluster bubbles showing job count
//   • Zoom ≥ 14  → individual pins (with spiderfy for exact overlaps)
// Color semantics: Orange/accent = Urgent, Primary = Standard
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../core/constants/app_colors.dart';
import '../../../models/job_model.dart';

export 'open_street_map_widget.dart' show MapStyleType;

enum MapStyleType { street, satellite, lightGray }

// ── Cluster data model ────────────────────────────────────────
class _JobCluster {
  final List<JobModel> jobs;
  final double lat;
  final double lng;

  _JobCluster({required this.jobs, required this.lat, required this.lng});

  LatLng get center => LatLng(lat, lng);
  int get count => jobs.length;
  bool get isSingle => jobs.length == 1;
  // Cluster is "urgent" if any job in it is urgent
  bool get hasUrgent => jobs.any((j) => j.isUrgent);
}

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

// ── Animated cluster bubble widget ───────────────────────────
class _ClusterBubble extends StatefulWidget {
  final _JobCluster cluster;
  final VoidCallback onTap;

  const _ClusterBubble({
    super.key,
    required this.cluster,
    required this.onTap,
  });

  @override
  State<_ClusterBubble> createState() => _ClusterBubbleState();
}

class _ClusterBubbleState extends State<_ClusterBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasUrgent = widget.cluster.hasUrgent;
    final gradient =
        hasUrgent ? AppColors.urgentGradient : AppColors.buttonGradient;
    final count = widget.cluster.count;

    // Size scales with count
    final size = count >= 10 ? 48.0 : count >= 5 ? 42.0 : 36.0;

    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.0),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withValues(alpha: 0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$count',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    const Text(
                      'jobs',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Downward pointer
            CustomPaint(
              size: const Size(9, 5),
              painter: _TrianglePointerPainter(color: gradient.colors.last),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Main Map Widget ───────────────────────────────────────────
class OpenStreetMapWidget extends StatefulWidget {
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

  @override
  State<OpenStreetMapWidget> createState() => _OpenStreetMapWidgetState();
}

class _OpenStreetMapWidgetState extends State<OpenStreetMapWidget>
    with TickerProviderStateMixin {
  double _currentZoom = 13.5;
  AnimationController? _mapAnimController;

  // Kathmandu default centre
  static const LatLng kathmanduCenter = LatLng(27.7172, 85.3240);

  @override
  void dispose() {
    _mapAnimController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant OpenStreetMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedJob != null &&
        widget.selectedJob?.id != oldWidget.selectedJob?.id) {
      final job = widget.selectedJob!;
      _animatedMapMove(
        LatLng(job.latitude, job.longitude),
        math.max(_currentZoom, 15.0),
      );
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    if (widget.mapController == null) return;

    _mapAnimController?.dispose();

    final camera = widget.mapController!.camera;
    final latTween =
        Tween<double>(begin: camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: destZoom);

    final controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _mapAnimController = controller;

    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    controller.addListener(() {
      widget.mapController!.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
        if (_mapAnimController == controller) {
          _mapAnimController = null;
        }
      }
    });

    controller.forward();
  }

  String get _tileUrl {
    switch (widget.mapStyle) {
      case MapStyleType.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapStyleType.lightGray:
        return 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
      case MapStyleType.street:
        return 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
    }
  }

  /// Groups jobs into clusters based on current zoom level.
  /// At zoom < 14: cluster within ~0.01° radius.
  /// At zoom ≥ 14: cluster within ~0.0008° (spiderfy for exact overlaps).
  List<_JobCluster> _buildClusters() {
    final clusterRadius = _currentZoom < 14 ? 0.012 : 0.0008;
    final jobs = List<JobModel>.from(widget.jobs);
    final List<_JobCluster> clusters = [];
    final Set<int> assigned = {};

    for (int i = 0; i < jobs.length; i++) {
      if (assigned.contains(i)) continue;

      final job = jobs[i];
      final List<JobModel> clusterJobs = [job];
      assigned.add(i);

      for (int j = i + 1; j < jobs.length; j++) {
        if (assigned.contains(j)) continue;
        final other = jobs[j];
        final latDiff = (job.latitude - other.latitude).abs();
        final lngDiff = (job.longitude - other.longitude).abs();
        if (latDiff < clusterRadius && lngDiff < clusterRadius) {
          clusterJobs.add(other);
          assigned.add(j);
        }
      }

      // Cluster center = average lat/lng
      final avgLat =
          clusterJobs.map((j) => j.latitude).reduce((a, b) => a + b) /
              clusterJobs.length;
      final avgLng =
          clusterJobs.map((j) => j.longitude).reduce((a, b) => a + b) /
              clusterJobs.length;

      clusters.add(_JobCluster(
        jobs: clusterJobs,
        lat: avgLat,
        lng: avgLng,
      ));
    }
    return clusters;
  }

  List<Marker> _buildMarkers(List<_JobCluster> clusters) {
    final List<Marker> markers = [];

    // User location pin
    if (widget.userLocation != null) {
      markers.add(
        Marker(
          point: widget.userLocation!,
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

    // Job clusters / individual pins
    for (int ci = 0; ci < clusters.length; ci++) {
      final cluster = clusters[ci];

      if (cluster.isSingle) {
        // Individual pin
        final job = cluster.jobs.first;
        final isSelected = widget.selectedJob?.id == job.id;
        markers.add(
          Marker(
            point: cluster.center,
            width: 145,
            height: 70,
            alignment: Alignment.topCenter,
            child: _AnimatedMarkerWidget(
              key: ValueKey(job.id),
              job: job,
              isSelected: isSelected,
              onTap: () {
                _animatedMapMove(cluster.center, math.max(_currentZoom, 14.5));
                widget.onMarkerTap(job);
              },
              index: ci,
            ),
          ),
        );
      } else if (_currentZoom >= 14) {
        // Spiderfy individual pins within tight cluster
        for (int ki = 0; ki < cluster.jobs.length; ki++) {
          final job = cluster.jobs[ki];
          final angle = (2 * math.pi * ki) / cluster.jobs.length;
          const radius = 0.0008;
          final lat = cluster.lat + radius * math.sin(angle);
          final lng = cluster.lng + radius * math.cos(angle);
          final isSelected = widget.selectedJob?.id == job.id;
          markers.add(
            Marker(
              point: LatLng(lat, lng),
              width: 145,
              height: 70,
              alignment: Alignment.topCenter,
              child: _AnimatedMarkerWidget(
                key: ValueKey('${job.id}_spider_$ki'),
                job: job,
                isSelected: isSelected,
                onTap: () {
                  _animatedMapMove(LatLng(lat, lng), 15.5);
                  widget.onMarkerTap(job);
                },
                index: ci + ki,
              ),
            ),
          );
        }
      } else {
        // Cluster bubble
        markers.add(
          Marker(
            point: cluster.center,
            width: 54,
            height: 60,
            alignment: Alignment.topCenter,
            child: _ClusterBubble(
              key: ValueKey('cluster_${cluster.lat}_${cluster.lng}_${cluster.count}'),
              cluster: cluster,
              onTap: () {
                // Smooth animated zoom into the cluster on tap
                _animatedMapMove(
                    cluster.center, math.min(_currentZoom + 2.2, 17.0));
              },
            ),
          ),
        );
      }
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: widget.mapController,
      options: MapOptions(
        initialCenter: widget.userLocation ?? kathmanduCenter,
        initialZoom: _currentZoom,
        minZoom: 10,
        maxZoom: 18,
        onTap: (_, _) => widget.onMapTap(),
        onPositionChanged: (position, hasGesture) {
          final newZoom = position.zoom;
          if ((newZoom - _currentZoom).abs() > 0.15) {
            setState(() => _currentZoom = newZoom);
          }
          if (hasGesture && widget.onMapInteractionChanged != null) {
            widget.onMapInteractionChanged!(true);
          }
        },
      ),
      children: [
        // ── Map Tile Layer ────────────────────────────────────
        TileLayer(
          urlTemplate: _tileUrl,
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.xaie.getwork',
          maxZoom: 19,
        ),

        // ── Dynamic Location Filter Distance Range Circle ────
        if (widget.userLocation != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: widget.userLocation!,
                radius: widget.filterDistanceKm * 1000,
                useRadiusInMeter: true,
                color: AppColors.primary.withValues(alpha: 0.08),
                borderColor: AppColors.primary.withValues(alpha: 0.35),
                borderStrokeWidth: 1.5,
              ),
            ],
          ),

        // ── Job Markers & User Location Marker ───────────────
        MarkerLayer(
          markers: _buildMarkers(_buildClusters()),
        ),
      ],
    );
  }
}


LinearGradient _getJobPinGradient(JobModel job, bool isSelected) {
  if (isSelected) {
    return const LinearGradient(
      colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // 1. Instant / Urgent → Vibrant Urgent Orange-Red
  if (job.isInstant || job.isUrgent) {
    return const LinearGradient(
      colors: [Color(0xFFFF6B35), Color(0xFFE53935)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // 2. Skilled Job → Premium Teal Gradient
  if (job.isSkilled) {
    return const LinearGradient(
      colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // 3. Scheduled Job → Standard Trust Green Gradient
  return const LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF047857)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
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
    final gradient = _getJobPinGradient(job, isSelected);
    final shadowColor = isSelected
        ? const Color(0xFF0284C7).withValues(alpha: 0.5)
        : job.isUrgent
            ? AppColors.accent.withValues(alpha: 0.45)
            : gradient.colors.first.withValues(alpha: 0.45);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bubble Body
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(
            maxWidth: 140,
            minWidth: 90,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white,
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: isSelected ? 12 : 6,
                offset: const Offset(0, 3),
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
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (job.isUrgent) ...[
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 10,
                      color: Colors.amberAccent,
                    ),
                    const SizedBox(width: 2),
                  ],
                  Flexible(
                    child: Text(
                      job.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.1,
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

        // Downward Triangle Arrow Pointer Tip
        CustomPaint(
          size: const Size(10, 6),
          painter: _TrianglePointerPainter(
            color: gradient.colors.last,
          ),
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
