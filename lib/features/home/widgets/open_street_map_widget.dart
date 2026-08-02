// ============================================================
// OPEN STREET MAP WIDGET — GetWork App
// Renders Kathmandu map via flutter_map + OpenStreetMap / CartoDB tiles
// Features map pin callout bubbles with downward pointer arrows,
// dual map themes (Light vs Dark mode), and interactive job markers
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../core/constants/app_colors.dart';
import '../../../models/job_model.dart';

class OpenStreetMapWidget extends StatelessWidget {
  final List<JobModel> jobs;
  final JobModel? selectedJob;
  final MapController? mapController;
  final bool isDarkMode;
  final void Function(JobModel job) onMarkerTap;
  final VoidCallback onMapTap;

  const OpenStreetMapWidget({
    super.key,
    required this.jobs,
    required this.selectedJob,
    this.mapController,
    this.isDarkMode = false,
    required this.onMarkerTap,
    required this.onMapTap,
  });

  // Kathmandu default centre
  static const LatLng kathmanduCenter = LatLng(27.7172, 85.3240);

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: kathmanduCenter,
        initialZoom: 13.5,
        minZoom: 10,
        maxZoom: 18,
        onTap: (_, _) => onMapTap(),
      ),
      children: [
        // ── Map Tile Layer (Light vs Sleek Dark Mode) ───────────
        TileLayer(
          urlTemplate: isDarkMode
              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.getwork.app',
          maxZoom: 19,
        ),

        // ── Job Salary Pins with Downward Arrow ──────────────────
        MarkerLayer(
          markers: jobs.map((job) {
            final isSelected = selectedJob?.id == job.id;
            return Marker(
              point: LatLng(job.latitude, job.longitude),
              width: 140,
              height: 64,
              alignment: Alignment.topCenter,
              child: GestureDetector(
                onTap: () => onMarkerTap(job),
                child: _MarkerCalloutPin(
                  job: job,
                  isSelected: isSelected,
                ),
              ),
            );
          }).toList(),
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
                blurRadius: isSelected ? 14 : 8,
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

    // Draw white border outline on sides
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
