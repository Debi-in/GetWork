// ============================================================
// JOB CAROUSEL CARD — GetWork App
// Bottom horizontal carousel job card rendered over the map
// ============================================================

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/job_model.dart';

Color _getCategoryColor(JobCategory cat) {
  switch (cat) {
    case JobCategory.delivery:
      return AppColors.categoryDelivery;
    case JobCategory.retail:
      return AppColors.categoryRetail;
    case JobCategory.food:
      return AppColors.categoryFood;
    case JobCategory.construction:
      return AppColors.categoryConstruction;
    case JobCategory.cleaning:
      return AppColors.categoryCleaning;
    case JobCategory.tech:
      return AppColors.categoryTech;
    case JobCategory.events:
      return AppColors.categoryEvents;
    default:
      return AppColors.primary;
  }
}

class JobCarouselCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;

  const JobCarouselCard({
    super.key,
    required this.job,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = _getCategoryColor(job.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 190,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              catColor.withValues(alpha: 0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: catColor.withValues(alpha: 0.25),
            width: 0.9,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.09),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title row
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),

            // Business name + salary pill
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.businessName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFD1FAE5),
                        Color(0xFFA7F3D0),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    job.salaryDisplay,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF047857),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),

            // Distance + urgent badge
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 11,
                  color: catColor,
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    '${job.distanceKm ?? 0.5} km away',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9.5,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (job.isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFE53935)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Urgent',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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
