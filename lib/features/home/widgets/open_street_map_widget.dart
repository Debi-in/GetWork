// ============================================================
// OPEN STREET MAP WIDGET — GetWork App
// Renders Kathmandu map via flutter_map + OpenStreetMap tiles
// with floating salary markers for discovered nearby jobs
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/job_model.dart';

class OpenStreetMapWidget extends StatelessWidget {
  final List<JobModel> jobs;
  final JobModel? selectedJob;
  final MapController? mapController;
  final void Function(JobModel job) onMarkerTap;
  final VoidCallback onMapTap;

  const OpenStreetMapWidget({
    super.key,
    required this.jobs,
    required this.selectedJob,
    this.mapController,
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
        // ── OpenStreetMap Tile Layer ────────────────────────────
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.getwork.app',
          maxZoom: 19,
        ),

        // ── Job Salary Markers ──────────────────────────────────
        MarkerLayer(
          markers: jobs.map((job) {
            final isSelected = selectedJob?.id == job.id;
            return Marker(
              point: LatLng(job.latitude, job.longitude),
              width: 120,
              height: 40,
              child: GestureDetector(
                onTap: () => onMarkerTap(job),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent : AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white,
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isSelected ? AppColors.accent : AppColors.primary)
                            .withValues(alpha: 0.4),
                        blurRadius: isSelected ? 12 : 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (job.isUrgent)
                        const Padding(
                          padding: EdgeInsets.only(right: 3),
                          child: Icon(
                            Icons.bolt_rounded,
                            size: 11,
                            color: Colors.white,
                          ),
                        ),
                      Flexible(
                        child: Text(
                          job.salaryDisplay,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
