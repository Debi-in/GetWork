// ============================================================
// SUPABASE JOBS SERVICE — GetWork App
// Fetches real job data from Supabase & maps to JobModel
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/job_model.dart';

class SupabaseJobsService {
  SupabaseJobsService._();

  static SupabaseClient get _db => Supabase.instance.client;

  // ── Fetch all active jobs ─────────────────────────────────
  static Future<List<JobModel>> fetchJobs() async {
    try {
      final response = await _db
          .from('jobs')
          .select()
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(100);

      return (response as List<dynamic>)
          .map((row) => _rowToJobModel(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Return empty list on error; UI shows empty state
      return [];
    }
  }

  // ── Post a new job ────────────────────────────────────────
  static Future<bool> postJob({
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
    JobType type = JobType.scheduled,
    int deadlineDays = 3,
    int postExpiryDays = 7,
  }) async {
    try {
      final now = DateTime.now();
      // For instant jobs: 4-hour expiry. For others: user-chosen 1–15 day expiry.
      final expiresAt = type == JobType.instant
          ? now.add(const Duration(hours: 4))
          : now.add(Duration(days: postExpiryDays.clamp(1, 15)));

      await _db.from('jobs').insert({
        'title': title,
        'category': category.toLowerCase(),
        'salary': salary,
        'salary_type': salaryType,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'job_start_date':
            (jobStartDate ?? DateTime.now()).toIso8601String().split('T').first,
        'shift_start_time': shiftStartTime,
        'shift_end_time': shiftEndTime,
        'workers_needed': workersNeeded,
        'business_name': businessName,
        'description': description,
        'requirements_text': requirements,
        'is_urgent': isUrgent,
        'status': 'active',
        'type': type.name,
        'job_status_v2': 'open',
        'expires_at': expiresAt.toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Submit an application ─────────────────────────────────
  static Future<bool> applyForJob({
    required String jobId,
    required String workerName,
    required String workerPhone,
    String coverNote = '',
  }) async {
    try {
      await _db.from('job_applications').insert({
        'job_id': jobId,
        'worker_name': workerName,
        'worker_phone': workerPhone,
        'cover_note': coverNote,
        'status': 'pending',
      });
      // Increment workers_applied counter atomically via RPC
      try {
        await _db.rpc('increment_workers_applied', params: {'job_id': jobId});
      } catch (_) {
        // RPC might not exist yet — silently ignore
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Fetch single job by id ────────────────────────────────
  static Future<JobModel?> fetchJobById(String id) async {
    try {
      final response =
          await _db.from('jobs').select().eq('id', id).single();
      return _rowToJobModel(response);
    } catch (e) {
      return null;
    }
  }

  // ── Map Supabase row → JobModel ───────────────────────────
  static JobModel _rowToJobModel(Map<String, dynamic> row) {
    // salary_type: DB uses enum string 'hourly'/'daily'/'fixed'/'project'
    final salaryTypeStr = (row['salary_type'] as String? ?? 'daily').toLowerCase();
    final salaryType = _parseSalaryType(salaryTypeStr);

    // category: DB uses enum string
    final categoryStr = (row['category'] as String? ?? 'all').toLowerCase();
    final category = _parseCategory(categoryStr);

    // status
    final statusStr = (row['status'] as String? ?? 'active').toLowerCase();
    final status = _parseStatus(statusStr);

    // shift_date: DB uses job_start_date (DATE)
    DateTime shiftDate;
    try {
      final rawDate = row['job_start_date'] ?? row['shift_date'];
      shiftDate = rawDate != null
          ? DateTime.parse(rawDate.toString())
          : DateTime.now();
    } catch (_) {
      shiftDate = DateTime.now();
    }

    // requirements: DB uses requirements_text (TEXT[])
    final reqRaw = row['requirements_text'] ?? row['requirements'] ?? [];
    final requirements = (reqRaw as List<dynamic>).cast<String>();

    // salary: unified column we added
    final salary = (row['salary'] as num?)?.toDouble() ??
        (row['daily_rate'] as num?)?.toDouble() ??
        (row['hourly_rate'] as num?)?.toDouble() ??
        0.0;

    final typeStr = (row['type'] as String? ?? 'scheduled').toLowerCase();
    final type = _parseJobType(typeStr);

    final statusV2Str = (row['job_status_v2'] as String? ?? 'open').toLowerCase();
    final jobStatusV2 = _parseJobStatusV2(statusV2Str);

    DateTime? expiresAt;
    if (row['expires_at'] != null) {
      try {
        expiresAt = DateTime.parse(row['expires_at'].toString());
      } catch (_) {}
    }

    return JobModel(
      id: row['id']?.toString() ?? '',
      title: row['title']?.toString() ?? '',
      businessId: row['business_id']?.toString() ?? 'unknown',
      businessName: row['business_name']?.toString() ?? '',
      businessLogoUrl: row['business_logo_url']?.toString(),
      latitude: (row['latitude'] as num?)?.toDouble() ?? 27.7172,
      longitude: (row['longitude'] as num?)?.toDouble() ?? 85.3240,
      address: row['address']?.toString() ?? '',
      salary: salary,
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
      status: status,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'].toString())
          : DateTime.now(),
      type: type,
      jobStatusV2: jobStatusV2,
      expiresAt: expiresAt,
    );
  }

  // ── Enum parsers ──────────────────────────────────────────
  static JobType _parseJobType(String s) {
    switch (s) {
      case 'instant': return JobType.instant;
      case 'skilled': return JobType.skilled;
      default:        return JobType.scheduled;
    }
  }

  static JobStatusV2 _parseJobStatusV2(String s) {
    switch (s) {
      case 'accepted':  return JobStatusV2.accepted;
      case 'filled':    return JobStatusV2.filled;
      case 'expired':   return JobStatusV2.expired;
      case 'cancelled': return JobStatusV2.cancelled;
      default:          return JobStatusV2.open;
    }
  }

  static SalaryType _parseSalaryType(String s) {
    switch (s) {
      case 'hourly':  return SalaryType.hourly;
      case 'weekly':  return SalaryType.weekly;
      case 'monthly': return SalaryType.monthly;
      case 'fixed':
      case 'project': return SalaryType.fixed;
      default:        return SalaryType.daily;
    }
  }

  static JobCategory _parseCategory(String s) {
    switch (s) {
      case 'delivery':     return JobCategory.delivery;
      case 'retail':       return JobCategory.retail;
      case 'food':         return JobCategory.food;
      case 'construction': return JobCategory.construction;
      case 'cleaning':     return JobCategory.cleaning;
      case 'tech':         return JobCategory.tech;
      case 'events':       return JobCategory.events;
      default:             return JobCategory.all;
    }
  }

  static JobStatus _parseStatus(String s) {
    switch (s) {
      case 'paused': return JobStatus.paused;
      case 'closed': return JobStatus.closed;
      case 'filled': return JobStatus.filled;
      default:       return JobStatus.active;
    }
  }
}
