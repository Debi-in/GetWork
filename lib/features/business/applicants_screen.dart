// ============================================================
// APPLICANTS SCREEN — GetWork App
// Business UI to view applicants for a job, accept or decline
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/supabase_config.dart';
import '../jobs/services/job_repository.dart';
import '../jobs/jobs_provider.dart';

class ApplicantsScreen extends ConsumerStatefulWidget {
  final String jobId;

  const ApplicantsScreen({
    super.key,
    required this.jobId,
  });

  @override
  ConsumerState<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends ConsumerState<ApplicantsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _applicants = [];
  String _jobTitle = 'Job Applicants';

  @override
  void initState() {
    super.initState();
    _fetchApplicants();
  }

  Future<void> _fetchApplicants() async {
    setState(() => _isLoading = true);

    try {
      final list = await JobRepository.instance.fetchApplications(widget.jobId);
      if (mounted) {
        setState(() {
          _applicants = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateApplicationStatus(
      String applicationId, String status, String workerName) async {
    try {
      final db = Supabase.instance.client;
      await db.from('job_applications').update({'status': status}).eq('id', applicationId);

      if (status == 'accepted') {
        // Increment workers_hired on job
        await db.rpc('increment_workers_applied', params: {'job_id': widget.jobId});
        // Refresh provider
        ref.read(allJobsProvider.notifier).refresh();

        // 🔔 Send push notification to all workers about a new job being filled
        // (in production, you'd target by worker_id — for now broadcast to topic)
        try {
          await Supabase.instance.client.functions.invoke(
            'send-notification',
            body: {
              'title': 'You Were Hired!',
              'body':
                  '$workerName, you have been accepted for the $_jobTitle shift. Open GetWork to see details.',
              'target': 'all',
              'tab': 'for_you',
              'data': {'type': 'hired', 'jobId': widget.jobId},
            },
            headers: {
              'x-admin-key': 'xaie-admin-2026',
              'apikey': SupabaseConfig.supabaseAnonKey,
            },
          );
        } catch (_) {
          // Notification failure should not block the hire action
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'accepted'
              ? '$workerName accepted for the shift!'
              : 'Application marked as declined'),
          backgroundColor:
              status == 'accepted' ? AppColors.primary : Colors.grey[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      _fetchApplicants();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(allJobsProvider).asData?.value ?? [];
    final matchingJob = jobs.where((j) => j.id == widget.jobId).firstOrNull;
    if (matchingJob != null) {
      _jobTitle = matchingJob.title;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Applicants — $_jobTitle'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchApplicants,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _applicants.isEmpty
              ? _EmptyApplicantsView()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _applicants.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final app = _applicants[index];
                    final appId = app['id']?.toString() ?? '';
                    final name = app['worker_name']?.toString() ?? 'Applicant';
                    final phone = app['worker_phone']?.toString() ?? 'N/A';
                    final note = app['cover_note']?.toString() ?? '';
                    final status = app['status']?.toString() ?? 'pending';
                    final appliedAt = app['applied_at']?.toString() ?? '';

                    return _ApplicantCard(
                      name: name,
                      phone: phone,
                      note: note,
                      status: status,
                      appliedAt: appliedAt,
                      onAccept: () =>
                          _updateApplicationStatus(appId, 'accepted', name),
                      onDecline: () =>
                          _updateApplicationStatus(appId, 'declined', name),
                    );
                  },
                ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────
class _EmptyApplicantsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Applicants Yet',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When workers apply for this shift, their profiles and messages will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Applicant Card ──────────────────────────────────────────────
class _ApplicantCard extends StatelessWidget {
  final String name;
  final String phone;
  final String note;
  final String status;
  final String appliedAt;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _ApplicantCard({
    required this.name,
    required this.phone,
    required this.note,
    required this.status,
    required this.appliedAt,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final isAccepted = status == 'accepted';
    final isDeclined = status == 'declined';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAccepted
              ? AppColors.primary.withValues(alpha: 0.5)
              : isDeclined
                  ? Colors.red.withValues(alpha: 0.3)
                  : AppColors.border,
          width: isAccepted ? 1.5 : 0.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryContainer,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'W',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isAccepted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Text(
                              'Hired',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          )
                        else if (isDeclined)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Text(
                              'Declined',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.phone_rounded, size: 13, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          phone,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '"$note"',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Action Buttons
          if (!isAccepted && !isDeclined)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('Accept Worker'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
                    minimumSize: const Size(80, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Decline'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
