// ============================================================
// APPLY SCREEN — GetWork App
// Confirm profile details & submit live application to Supabase
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_jobs_service.dart';
import '../../../core/services/user_profile_service.dart';
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
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await UserProfileService.getProfile();
    if (mounted) {
      setState(() => _profile = profile);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submitApplication() async {
    setState(() => _isSubmitting = true);

    final workerName = _profile?.fullName.isNotEmpty == true
        ? _profile!.fullName
        : 'Worker Candidate';
    final workerPhone = _profile?.phone.isNotEmpty == true
        ? _profile!.phone
        : '+977 9800000000';

    // Submit live application to Supabase `job_applications`
    await SupabaseJobsService.applyForJob(
      jobId: widget.jobId,
      workerName: workerName,
      workerPhone: workerPhone,
      coverNote: _noteController.text.trim(),
    );

    // Register application in Riverpod state
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

    final workerName = _profile?.fullName.isNotEmpty == true
        ? _profile!.fullName
        : 'Worker Candidate';
    final workerSkill = (_profile?.primarySkill != null && _profile!.primarySkill!.isNotEmpty)
        ? _profile!.primarySkill!
        : 'General Helper';

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
                        job.businessName.isNotEmpty
                            ? job.businessName[0].toUpperCase()
                            : 'G',
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
                          workerName[0].toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workerName,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Phone: ${_profile?.phone.isNotEmpty == true ? _profile!.phone : "+977 98XXXXXXXX"}',
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
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 10),

                  // Primary Skill Tag
                  const Text(
                    'Primary Skill',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Chip(
                    label: Text(workerSkill),
                    backgroundColor: AppColors.primaryContainer,
                    labelStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
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
                    'Introduce yourself or specify your availability (e.g. "I am punctual and can start immediately").',
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
