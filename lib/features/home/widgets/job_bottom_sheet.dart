// ============================================================
// JOB BOTTOM SHEET — GetWork App
// Bottom sheet shown when tapping a job marker on the map
// Matching exact reference design (image banner, tags, blur focus)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/user_profile_service.dart';
import '../../../models/job_model.dart';
import '../../jobs/jobs_provider.dart';
import '../../jobs/widgets/complete_profile_sheet.dart';
import '../../business/chat_repository.dart';
import '../../business/chat_screen.dart';

class JobBottomSheet extends ConsumerStatefulWidget {
  final JobModel job;
  final VoidCallback onClose;

  const JobBottomSheet({
    super.key,
    required this.job,
    required this.onClose,
  });

  @override
  ConsumerState<JobBottomSheet> createState() => _JobBottomSheetState();
}

class _JobBottomSheetState extends ConsumerState<JobBottomSheet> {
  bool _isSaved = false;

  Future<void> _openChatWithBusiness(BuildContext context) async {
    final profile = await UserProfileService.getProfile();
    final workerName =
        (profile != null && profile.fullName.isNotEmpty) ? profile.fullName : 'Worker';
    final workerPhone =
        (profile != null && profile.phone.isNotEmpty) ? profile.phone : '+977-9800000000';

    final convId = await ChatRepository.instance.createOrGetConversation(
      jobId: widget.job.id,
      businessName: widget.job.businessName,
      workerName: workerName,
      workerPhone: workerPhone,
    );

    if (!context.mounted) return;

    if (convId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: convId,
            workerName: widget.job.businessName,
            workerPhone: widget.job.category.name,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to connect to chat. Please check your network.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appliedJobs = ref.watch(appliedJobsProvider);
    final isApplied = appliedJobs.contains(widget.job.id);

    return Container(
      constraints: const BoxConstraints(maxHeight: 620),
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 32,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Image / Category Banner ────────────────────────
              Stack(
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    color: AppColors.primaryContainer,
                    child: Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadowLight,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getCategoryBannerIcon(widget.job.category),
                          size: 36,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                  // Top Drag handle indicator
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                  // Close button (Left)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textPrimary),
                        onPressed: widget.onClose,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),

                  // Heart & Share buttons (Right)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: Icon(
                              _isSaved ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                              size: 18,
                              color: _isSaved ? AppColors.accent : AppColors.textPrimary,
                            ),
                            onPressed: () {
                              setState(() {
                                _isSaved = !_isSaved;
                              });
                            },
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: const Icon(Icons.share_outlined, size: 18, color: AppColors.textPrimary),
                            onPressed: () {
                              // Share job link
                            },
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Main Content Padding ─────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Business Info Row
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: AppColors.accentContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              widget.job.businessName[0].toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentDark,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.job.businessName,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                  const SizedBox(width: 2),
                                  Text(
                                    '4.8 (24) • ${widget.job.distanceKm ?? 0.5} km away',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Quick Chat Button
                        InkWell(
                          onTap: () => _openChatWithBusiness(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.primaryDark),
                                SizedBox(width: 4),
                                Text(
                                  'Chat',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Job Title & Salary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            widget.job.title,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          widget.job.salaryDisplay,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Schedule & Shift Tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _BadgeTag(
                          icon: Icons.calendar_today_rounded,
                          label: 'Today, ${widget.job.shiftStartTime} - ${widget.job.shiftEndTime}',
                          bgColor: AppColors.primaryContainer,
                          textColor: AppColors.primaryDark,
                        ),
                        const _BadgeTag(
                          icon: Icons.bolt_rounded,
                          label: 'One Day',
                          bgColor: AppColors.accentContainer,
                          textColor: AppColors.accentDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Requirement Badges Row
                    Row(
                      children: [
                        _ChipBadge(label: '${widget.job.workersNeeded} Workers'),
                        const SizedBox(width: 6),
                        const _ChipBadge(label: '18+ Years'),
                        const SizedBox(width: 6),
                        const _ChipBadge(label: 'No experience'),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Description text
                    Text(
                      widget.job.description,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),

                    // Requirements List
                    const Text(
                      'Requirements',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...widget.job.requirements.map(
                      (req) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              req,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons Row
                    Row(
                      children: [
                        // Save Button
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isSaved = !_isSaved;
                              });
                            },
                            icon: Icon(
                              _isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                              size: 18,
                            ),
                            label: Text(_isSaved ? 'Saved' : 'Save'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Apply Button
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            onPressed: isApplied
                                ? null
                                : () async {
                                    final profile = await UserProfileService.getProfile();
                                    if (profile == null || !profile.isFullProfileComplete) {
                                      if (!context.mounted) return;
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) => CompleteProfileSheet(
                                          onProfileCompleted: () {
                                            if (context.mounted) {
                                              context.push('/job/${widget.job.id}/apply');
                                            }
                                          },
                                        ),
                                      );
                                    } else {
                                      if (!context.mounted) return;
                                      context.push('/job/${widget.job.id}/apply');
                                    }
                                  },
                            icon: const Icon(Icons.bolt_rounded, size: 20),
                            label: Text(isApplied ? 'Applied ✓' : 'Apply Now'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 50),
                              backgroundColor: isApplied
                                  ? AppColors.textHint
                                  : AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Applicants Counter Subtitle
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.group_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Applied by ${widget.job.workersApplied} people',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
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

  IconData _getCategoryBannerIcon(JobCategory category) {
    switch (category) {
      case JobCategory.delivery:
        return Icons.two_wheeler_rounded;
      case JobCategory.retail:
        return Icons.shopping_bag_rounded;
      case JobCategory.food:
        return Icons.restaurant_rounded;
      case JobCategory.construction:
        return Icons.construction_rounded;
      case JobCategory.cleaning:
        return Icons.cleaning_services_rounded;
      case JobCategory.tech:
        return Icons.computer_rounded;
      case JobCategory.events:
        return Icons.event_rounded;
      case JobCategory.all:
        return Icons.work_rounded;
    }
  }
}

class _BadgeTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color textColor;

  const _BadgeTag({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipBadge extends StatelessWidget {
  final String label;

  const _ChipBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
