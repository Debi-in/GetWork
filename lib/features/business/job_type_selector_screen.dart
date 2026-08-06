// ============================================================
// JOB TYPE SELECTOR SCREEN — GetWork App
// Business Side Step 1: Choose Instant, Scheduled, or Skilled Job
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/job_model.dart';

class JobTypeSelectorScreen extends StatelessWidget {
  const JobTypeSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create New Job'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Job Type',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose how you want workers to discover and accept this listing.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: ListView(
                  children: [
                    // Card 1: Instant Job
                    _JobTypeCard(
                      type: JobType.instant,
                      title: 'Instant Job',
                      subtitle: 'Need someone right now — first worker to accept gets it.',
                      badgeText: 'FASTEST HIRE',
                      gradientColors: const [Color(0xFFFF6B35), Color(0xFFE53935)],
                      icon: Icons.bolt_rounded,
                      onTap: () {
                        context.push('/business/post-job?type=instant');
                      },
                    ),
                    const SizedBox(height: 16),

                    // Card 2: Scheduled Job
                    _JobTypeCard(
                      type: JobType.scheduled,
                      title: 'Scheduled Job',
                      subtitle: 'Post and review applicants before choosing the right fit.',
                      badgeText: 'POPULAR',
                      gradientColors: const [Color(0xFF059669), Color(0xFF047857)],
                      icon: Icons.calendar_month_rounded,
                      onTap: () {
                        context.push('/business/post-job?type=scheduled');
                      },
                    ),
                    const SizedBox(height: 16),

                    // Card 3: Skilled Job
                    _JobTypeCard(
                      type: JobType.skilled,
                      title: 'Skilled Job',
                      subtitle: 'Requires specific experience, licenses, or qualifications.',
                      badgeText: 'VERIFIED SKILLS',
                      gradientColors: const [Color(0xFF0D9488), Color(0xFF0F766E)],
                      icon: Icons.verified_rounded,
                      onTap: () {
                        context.push('/business/post-job?type=skilled');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobTypeCard extends StatelessWidget {
  final JobType type;
  final String title;
  final String subtitle;
  final String badgeText;
  final List<Color> gradientColors;
  final IconData icon;
  final VoidCallback onTap;

  const _JobTypeCard({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.gradientColors,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              gradientColors.first.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: gradientColors.first.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Icon Badge
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.first.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradientColors),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
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
}
