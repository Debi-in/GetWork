// ============================================================
// JOB REPOSITORY — GetWork App
// Wraps SupabaseJobsService with write operations (post job, apply)
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/job_model.dart';

class JobRepository {
  JobRepository._();
  static final JobRepository instance = JobRepository._();

  final SupabaseClient _client = Supabase.instance.client;

  /// Post a new job to the `jobs` table (used by Business Dashboard FAB)
  Future<bool> postJob({
    required String title,
    required String category,
    required double salary,
    String salaryType = 'daily',
    required String address,
    required double latitude,
    required double longitude,
    DateTime? jobStartDate,
    String shiftStartTime = '09:00 AM',
    String shiftEndTime = '05:00 PM',
    required int workersNeeded,
    required String businessName,
    String description = '',
    List<String> requirements = const [],
    bool isUrgent = false,
  }) async {
    try {
      await _client.from('jobs').insert({
        'title': title,
        'category': category.toLowerCase(),
        'salary': salary,
        'salary_type': salaryType,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'job_start_date': (jobStartDate ?? DateTime.now()).toIso8601String().split('T').first,
        'shift_start_time': shiftStartTime,
        'shift_end_time': shiftEndTime,
        'workers_needed': workersNeeded,
        'business_name': businessName,
        'description': description,
        'requirements_text': requirements,
        'is_urgent': isUrgent,
        'status': 'active',
      });
      return true;
    } catch (e) {
      if (kDebugMode) print('⚠️ [JobRepository postJob Error]: $e');
      return false;
    }
  }

  /// Submit a job application to the `job_applications` table
  Future<bool> applyForJob({
    required String jobId,
    required String workerName,
    required String workerPhone,
    String coverNote = '',
  }) async {
    try {
      await _client.from('job_applications').insert({
        'job_id': jobId,
        'worker_name': workerName,
        'worker_phone': workerPhone,
        'cover_note': coverNote,
        'status': 'pending',
      });
      // Increment workers_applied counter on the job
      await _client.rpc('increment_workers_applied', params: {'job_id': jobId});
      return true;
    } catch (e) {
      if (kDebugMode) print('⚠️ [JobRepository applyForJob Error]: $e');
      return false;
    }
  }

  /// Fetch jobs posted by a specific business (used in Business Dashboard)
  Future<List<JobModel>> fetchBusinessJobs(String businessName) async {
    try {
      final response = await _client
          .from('jobs')
          .select()
          .eq('business_name', businessName)
          .order('created_at', ascending: false);

      final List<dynamic> rows = response;
      return rows.map((r) => _rowToJobModel(r as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) print('⚠️ [JobRepository fetchBusinessJobs Error]: $e');
      return [];
    }
  }

  /// Fetch applications for a given job
  Future<List<Map<String, dynamic>>> fetchApplications(String jobId) async {
    try {
      final response = await _client
          .from('job_applications')
          .select()
          .eq('job_id', jobId)
          .order('applied_at', ascending: false);
      return (response as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) print('⚠️ [JobRepository fetchApplications Error]: $e');
      return [];
    }
  }

  // ── Internal mapper ────────────────────────────────────────
  JobModel _rowToJobModel(Map<String, dynamic> row) {
    final salaryTypeStr = (row['salary_type'] as String? ?? 'daily').toLowerCase();
    SalaryType salaryType;
    switch (salaryTypeStr) {
      case 'hourly': salaryType = SalaryType.hourly; break;
      case 'weekly': salaryType = SalaryType.weekly; break;
      case 'monthly': salaryType = SalaryType.monthly; break;
      case 'fixed':
      case 'project': salaryType = SalaryType.fixed; break;
      default: salaryType = SalaryType.daily;
    }

    final categoryStr = (row['category'] as String? ?? 'all').toLowerCase();
    JobCategory category;
    switch (categoryStr) {
      case 'delivery': category = JobCategory.delivery; break;
      case 'retail': category = JobCategory.retail; break;
      case 'food': category = JobCategory.food; break;
      case 'construction': category = JobCategory.construction; break;
      case 'cleaning': category = JobCategory.cleaning; break;
      case 'tech': category = JobCategory.tech; break;
      case 'events': category = JobCategory.events; break;
      default: category = JobCategory.all;
    }

    DateTime shiftDate;
    try {
      final raw = row['job_start_date'];
      shiftDate = raw != null ? DateTime.parse(raw.toString()) : DateTime.now();
    } catch (_) {
      shiftDate = DateTime.now();
    }

    final reqRaw = row['requirements_text'] ?? [];
    final requirements = (reqRaw as List<dynamic>).cast<String>();

    return JobModel(
      id: row['id']?.toString() ?? '',
      title: row['title']?.toString() ?? '',
      businessId: row['business_id']?.toString() ?? '',
      businessName: row['business_name']?.toString() ?? '',
      businessLogoUrl: row['business_logo_url']?.toString(),
      latitude: (row['latitude'] as num?)?.toDouble() ?? 27.7172,
      longitude: (row['longitude'] as num?)?.toDouble() ?? 85.3240,
      address: row['address']?.toString() ?? 'Kathmandu',
      salary: (row['salary'] as num?)?.toDouble() ?? 700.0,
      salaryType: salaryType,
      category: category,
      description: row['description']?.toString() ?? '',
      requirements: requirements,
      shiftDate: shiftDate,
      shiftStartTime: row['shift_start_time']?.toString() ?? '09:00 AM',
      shiftEndTime: row['shift_end_time']?.toString() ?? '05:00 PM',
      workersNeeded: (row['workers_needed'] as num?)?.toInt() ?? 1,
      workersApplied: (row['workers_applied'] as num?)?.toInt() ?? 0,
      isUrgent: row['is_urgent'] as bool? ?? false,
      status: JobStatus.active,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'].toString())
          : DateTime.now(),
    );
  }
}
