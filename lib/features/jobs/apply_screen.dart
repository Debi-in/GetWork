// ============================================================
// APPLY SCREEN — GetWork App
// Confirm profile details & submit application
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import 'jobs_provider.dart';

class ApplyScreen extends ConsumerStatefulWidget {
  final String jobId;

  const ApplyScreen({
    super.key,
    required this.jobId,
  });

  @override
  ConsumerState<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends ConsumerState<ApplyScreen> {
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submitApplication() async {
    setState(() => _isSubmitting = true);

    await Future.delayed(const Duration(milliseconds: 600));

    // Register application in state
    ref.read(appliedJobsProvider.notifier).applyToJob(widget.jobId);
    ref.read(allJobsProvider.notifier).incrementAppliedCount(widget.jobId);

    if (mounted) {
      context.go('/apply-success');
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobList = ref.watch(allJobsProvider).asData?.value ?? [];
    final job = jobList.firstWhere(
      (j) => j.id == widget.jobId,
      orElse: () => jobList.first,
    );

    final dummyWorker = UserModel.dummyWorker();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Confirm Application'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Job Summary Card ────────────────────────────────
            const Text(
              'Applying For',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        job.businessName[0].toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${job.businessName} • ${job.salaryDisplay}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Worker Profile Card ──────────────────────────────
            const Text(
              'Your Applicant Profile',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          dummyWorker.name[0],
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dummyWorker.name,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                '${dummyWorker.rating} (${dummyWorker.completedJobs} jobs completed)',
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
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Skills List
                  const Text(
                    'Skills',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: dummyWorker.skills
                        .map(
                          (skill) => Chip(
                            label: Text(skill),
                            backgroundColor: AppColors.surfaceVariant,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Optional Note ────────────────────────────────────
            const Text(
              'Message for Employer (Optional)',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'Introduce yourself or specify your availability (e.g. "I can start immediately").',
              ),
            ),
            const SizedBox(height: 32),

            // ── Submit Button ────────────────────────────────────
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitApplication,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Confirm & Send Application'),
            ),
          ],
        ),
      ),
    );
  }
}
