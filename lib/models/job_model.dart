// ============================================================
// JOB MODEL — GetWork App
// ============================================================

import 'package:equatable/equatable.dart';

enum JobCategory {
  all,
  delivery,
  retail,
  food,
  construction,
  cleaning,
  tech,
  events,
}

enum SalaryType { hourly, daily, weekly, monthly, fixed }

// Legacy status kept for backward compat with existing screens
enum JobStatus { active, paused, closed, filled }

/// The new job-type system (Instant / Scheduled / Skilled)
enum JobType {
  instant,    // first-come, race-safe Accept
  scheduled,  // Apply then employer picks one applicant
  skilled,    // Apply + requirements shown, employer picks
}

/// Status for the new multi-type job lifecycle
enum JobStatusV2 {
  open,        // visible on map
  accepted,    // instant job taken by a worker
  filled,      // scheduled/skilled job applicant confirmed
  expired,     // past expiresAt without activity
  cancelled,   // removed by business
}

/// An entry in the applicants array (Scheduled / Skilled jobs)
class JobApplicant extends Equatable {
  final String uid;
  final DateTime appliedAt;
  final String status; // "pending" | "accepted" | "rejected"

  const JobApplicant({
    required this.uid,
    required this.appliedAt,
    this.status = 'pending',
  });

  JobApplicant copyWith({
    String? uid,
    DateTime? appliedAt,
    String? status,
  }) {
    return JobApplicant(
      uid: uid ?? this.uid,
      appliedAt: appliedAt ?? this.appliedAt,
      status: status ?? this.status,
    );
  }

  factory JobApplicant.fromMap(Map<String, dynamic> map) {
    return JobApplicant(
      uid: map['uid'] as String,
      appliedAt: DateTime.parse(map['appliedAt'] as String),
      status: map['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'appliedAt': appliedAt.toIso8601String(),
        'status': status,
      };

  @override
  List<Object?> get props => [uid, appliedAt, status];
}

class JobModel extends Equatable {
  final String id;
  final String title;
  final String businessId;
  final String businessName;
  final String? businessLogoUrl;
  final double latitude;
  final double longitude;
  final String address;
  final double salary;
  final SalaryType salaryType;
  final JobCategory category;
  final String description;
  final List<String> requirements;
  final DateTime shiftDate;
  final String shiftStartTime;
  final String shiftEndTime;
  final int workersNeeded;
  final int workersApplied;
  final bool isUrgent;
  final JobStatus status;
  final DateTime createdAt;
  final double? distanceKm;

  // ── New multi-type fields ─────────────────────────────────
  final JobType type;
  final JobStatusV2 jobStatusV2;
  final DateTime? expiresAt;

  // Instant-only
  final String? acceptedBy;
  final DateTime? acceptedAt;

  // Scheduled / Skilled
  final List<JobApplicant> applicants;
  final String? filledBy;

  const JobModel({
    required this.id,
    required this.title,
    required this.businessId,
    required this.businessName,
    this.businessLogoUrl,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.salary,
    required this.salaryType,
    required this.category,
    required this.description,
    required this.requirements,
    required this.shiftDate,
    required this.shiftStartTime,
    required this.shiftEndTime,
    required this.workersNeeded,
    this.workersApplied = 0,
    this.isUrgent = false,
    this.status = JobStatus.active,
    required this.createdAt,
    this.distanceKm,
    this.type = JobType.scheduled,
    this.jobStatusV2 = JobStatusV2.open,
    this.expiresAt,
    this.acceptedBy,
    this.acceptedAt,
    this.applicants = const [],
    this.filledBy,
  });

  // ── Convenience Getters ───────────────────────────────────
  String get salaryDisplay {
    final suffix = switch (salaryType) {
      SalaryType.hourly => '/hr',
      SalaryType.daily => '/day',
      SalaryType.weekly => '/wk',
      SalaryType.monthly => '/mo',
      SalaryType.fixed => '',
    };
    return 'Rs. ${salary.toStringAsFixed(0)}$suffix';
  }

  bool get isFull => workersApplied >= workersNeeded;
  bool get isToday =>
      shiftDate.year == DateTime.now().year &&
      shiftDate.month == DateTime.now().month &&
      shiftDate.day == DateTime.now().day;

  bool get isOpen => jobStatusV2 == JobStatusV2.open;
  bool get isInstant => type == JobType.instant;
  bool get isScheduled => type == JobType.scheduled;
  bool get isSkilled => type == JobType.skilled;

  JobModel copyWith({
    String? id,
    String? title,
    String? businessId,
    String? businessName,
    String? businessLogoUrl,
    double? latitude,
    double? longitude,
    String? address,
    double? salary,
    SalaryType? salaryType,
    JobCategory? category,
    String? description,
    List<String>? requirements,
    DateTime? shiftDate,
    String? shiftStartTime,
    String? shiftEndTime,
    int? workersNeeded,
    int? workersApplied,
    bool? isUrgent,
    JobStatus? status,
    DateTime? createdAt,
    double? distanceKm,
    JobType? type,
    JobStatusV2? jobStatusV2,
    DateTime? expiresAt,
    String? acceptedBy,
    DateTime? acceptedAt,
    List<JobApplicant>? applicants,
    String? filledBy,
  }) {
    return JobModel(
      id: id ?? this.id,
      title: title ?? this.title,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      businessLogoUrl: businessLogoUrl ?? this.businessLogoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      salary: salary ?? this.salary,
      salaryType: salaryType ?? this.salaryType,
      category: category ?? this.category,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      shiftDate: shiftDate ?? this.shiftDate,
      shiftStartTime: shiftStartTime ?? this.shiftStartTime,
      shiftEndTime: shiftEndTime ?? this.shiftEndTime,
      workersNeeded: workersNeeded ?? this.workersNeeded,
      workersApplied: workersApplied ?? this.workersApplied,
      isUrgent: isUrgent ?? this.isUrgent,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      distanceKm: distanceKm ?? this.distanceKm,
      type: type ?? this.type,
      jobStatusV2: jobStatusV2 ?? this.jobStatusV2,
      expiresAt: expiresAt ?? this.expiresAt,
      acceptedBy: acceptedBy ?? this.acceptedBy,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      applicants: applicants ?? this.applicants,
      filledBy: filledBy ?? this.filledBy,
    );
  }

  @override
  List<Object?> get props => [
        id, title, businessId, businessName, businessLogoUrl,
        latitude, longitude, address, salary, salaryType, category,
        description, requirements, shiftDate, shiftStartTime,
        shiftEndTime, workersNeeded, workersApplied, isUrgent,
        status, createdAt, distanceKm,
        type, jobStatusV2, expiresAt, acceptedBy, acceptedAt,
        applicants, filledBy,
      ];
}

