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

enum SalaryType { hourly, daily, fixed }

enum JobStatus { active, paused, closed, filled }

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
  final double? distanceKm; // Computed from user location

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
  });

  String get salaryDisplay {
    final suffix = salaryType == SalaryType.hourly
        ? '/hr'
        : salaryType == SalaryType.daily
            ? '/day'
            : '';
    return 'Rs. ${salary.toStringAsFixed(0)}$suffix';
  }

  bool get isFull => workersApplied >= workersNeeded;
  bool get isToday =>
      shiftDate.year == DateTime.now().year &&
      shiftDate.month == DateTime.now().month &&
      shiftDate.day == DateTime.now().day;

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
    );
  }

  @override
  List<Object?> get props => [
        id, title, businessId, businessName, businessLogoUrl,
        latitude, longitude, address, salary, salaryType, category,
        description, requirements, shiftDate, shiftStartTime,
        shiftEndTime, workersNeeded, workersApplied, isUrgent,
        status, createdAt, distanceKm,
      ];
}
