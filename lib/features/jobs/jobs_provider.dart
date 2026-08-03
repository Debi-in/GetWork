// ============================================================
// JOBS PROVIDER — GetWork App
// Riverpod 3.x Notifier state management for filtering, searching & applying
// ============================================================

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/supabase_jobs_service.dart';
import '../../models/job_model.dart';

// ── Job Filter State ─────────────────────────────────────────
class JobFilterState extends Equatable {
  final JobCategory category;
  final SalaryType? salaryType;
  final double minSalary;
  final double maxSalary;
  final double maxDistanceKm;
  final bool isUrgentOnly;
  final bool isTodayOnly;

  const JobFilterState({
    this.category = JobCategory.all,
    this.salaryType,
    this.minSalary = 0,
    this.maxSalary = 5000,
    this.maxDistanceKm = 25,
    this.isUrgentOnly = false,
    this.isTodayOnly = false,
  });

  bool get isDefault =>
      category == JobCategory.all &&
      salaryType == null &&
      minSalary == 0 &&
      maxSalary == 5000 &&
      maxDistanceKm == 25 &&
      !isUrgentOnly &&
      !isTodayOnly;

  JobFilterState copyWith({
    JobCategory? category,
    SalaryType? salaryType,
    double? minSalary,
    double? maxSalary,
    double? maxDistanceKm,
    bool? isUrgentOnly,
    bool? isTodayOnly,
    bool clearSalaryType = false,
  }) {
    return JobFilterState(
      category: category ?? this.category,
      salaryType: clearSalaryType ? null : (salaryType ?? this.salaryType),
      minSalary: minSalary ?? this.minSalary,
      maxSalary: maxSalary ?? this.maxSalary,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      isUrgentOnly: isUrgentOnly ?? this.isUrgentOnly,
      isTodayOnly: isTodayOnly ?? this.isTodayOnly,
    );
  }

  @override
  List<Object?> get props => [
        category,
        salaryType,
        minSalary,
        maxSalary,
        maxDistanceKm,
        isUrgentOnly,
        isTodayOnly,
      ];
}

class JobFilterNotifier extends Notifier<JobFilterState> {
  @override
  JobFilterState build() => const JobFilterState();

  void updateFilter(JobFilterState newFilter) {
    state = newFilter;
  }

  void setCategory(JobCategory category) {
    state = state.copyWith(category: category);
  }

  void reset() {
    state = const JobFilterState();
  }
}

final jobFilterProvider = NotifierProvider<JobFilterNotifier, JobFilterState>(
  JobFilterNotifier.new,
);

// ── Selected Category Notifier ──────────────────────────────
class SelectedCategoryNotifier extends Notifier<JobCategory> {
  @override
  JobCategory build() => JobCategory.all;

  void setCategory(JobCategory category) {
    state = category;
  }
}

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, JobCategory>(
  SelectedCategoryNotifier.new,
);

// ── Search Query Notifier ───────────────────────────────────
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

// ── Selected Job on Map Notifier ────────────────────────────
class SelectedJobNotifier extends Notifier<JobModel?> {
  @override
  JobModel? build() => null;

  void selectJob(JobModel? job) {
    state = job;
  }
}

final selectedJobProvider = NotifierProvider<SelectedJobNotifier, JobModel?>(
  SelectedJobNotifier.new,
);

// ── Applied Jobs List Notifier ──────────────────────────────
class AppliedJobsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void applyToJob(String jobId) {
    state = {...state, jobId};
  }

  /// Auto-apply up to 6 jobs at once
  void autoApply6Jobs(List<String> jobIds) {
    final next = {...state};
    for (final id in jobIds) {
      if (next.length >= 6) break;
      next.add(id);
    }
    state = next;
  }

  bool isApplied(String jobId) {
    return state.contains(jobId);
  }

  void removeApplication(String jobId) {
    state = {...state}..remove(jobId);
  }

  /// User got the job — keep only that job id, remove all others.
  void gotTheJob(String jobId) {
    state = {jobId};
  }

  void clearAll() {
    state = {};
  }

  int get appliedCount => state.length;
}

final appliedJobsProvider =
    NotifierProvider<AppliedJobsNotifier, Set<String>>(
  AppliedJobsNotifier.new,
);

// ── Auto-Applied Jobs Notifier ──────────────────────────────
class AutoAppliedJobsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void markAutoApplied(Iterable<String> jobIds) {
    state = {...state, ...jobIds};
  }

  void clearAll() {
    state = {};
  }
}

final autoAppliedJobsProvider =
    NotifierProvider<AutoAppliedJobsNotifier, Set<String>>(
  AutoAppliedJobsNotifier.new,
);


// ── All Jobs List Notifier (Async — fetches from Supabase) ──
class JobsListNotifier extends AsyncNotifier<List<JobModel>> {
  @override
  Future<List<JobModel>> build() => SupabaseJobsService.fetchJobs();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(SupabaseJobsService.fetchJobs);
  }

  void incrementAppliedCount(String jobId) {
    final current = state.asData?.value ?? [];
    state = AsyncData([
      for (final job in current)
        if (job.id == jobId)
          job.copyWith(workersApplied: job.workersApplied + 1)
        else
          job,
    ]);
  }
}

final allJobsProvider =
    AsyncNotifierProvider<JobsListNotifier, List<JobModel>>(
  JobsListNotifier.new,
);

// ── Filtered Jobs Provider ──────────────────────────────────
final filteredJobsProvider = Provider<List<JobModel>>((ref) {
  // Use asData?.value so UI stays responsive while Supabase loads
  final jobs = ref.watch(allJobsProvider).asData?.value ?? [];
  final topCategory = ref.watch(selectedCategoryProvider);
  final filter = ref.watch(jobFilterProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();

  return jobs.where((job) {
    // 1. Top Category Pill or Modal Category
    final matchesCategory =
        (topCategory == JobCategory.all && filter.category == JobCategory.all) ||
        (topCategory != JobCategory.all && job.category == topCategory) ||
        (filter.category != JobCategory.all && job.category == filter.category);

    // 2. Search Query
    final matchesQuery = query.isEmpty ||
        job.title.toLowerCase().contains(query) ||
        job.businessName.toLowerCase().contains(query) ||
        job.address.toLowerCase().contains(query);

    // 3. Salary Type
    final matchesSalaryType =
        filter.salaryType == null || job.salaryType == filter.salaryType;

    // 4. Salary Range
    final matchesSalaryRange =
        job.salary >= filter.minSalary && job.salary <= filter.maxSalary;

    // 5. Distance Radius
    final matchesDistance =
        job.distanceKm == null || job.distanceKm! <= filter.maxDistanceKm;

    // 6. Urgent Filter
    final matchesUrgent = !filter.isUrgentOnly || job.isUrgent;

    // 7. Today Filter
    final matchesToday = !filter.isTodayOnly || job.isToday;

    return matchesCategory &&
        matchesQuery &&
        matchesSalaryType &&
        matchesSalaryRange &&
        matchesDistance &&
        matchesUrgent &&
        matchesToday;
  }).toList();
});
